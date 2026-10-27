// we have decleared all events here along with helper functions
// this.before(event, entity, fn)
//CAP gives every entity the standard operations (CRUD) automatically: 'CREATE', 'READ', 'UPDATE'.... (no need to define action)
// before = runs before CAP saves, on = replaces what CAP does, after = runs after CAP has saved
const cds = require('@sap/cds');
// take the query builders from cds.ql, not the globals: the Fiori UI plugin loads a second copy
// of @sap/cds, and then the global SELECT/INSERT/UPDATE belong to the wrong copy
const { SELECT, INSERT, UPDATE } = cds.ql;
// shared "next code number" helper (same logic as ANM- codes on the admin side)
const { nextId } = require('./lib/ids');

module.exports = cds.service.impl(async function () {

    // roles of the logged-in person (XSUAA role collections AnimalAdoption_Admin / AnimalAdoption_User)
    // (also used by the top bar of both apps for the account menu)
    this.on('myRoles', (req) => {
        const { givenName, familyName, email } = req.user.attr || {};
        return {
            user: req.user.id,
            name: [givenName, familyName].filter(Boolean).join(' ') || req.user.id,
            email: email || (req.user.id.includes('@') ? req.user.id : null),
            admin: req.user.is('Admin'),
            adopter: req.user.is('User')
        };
    });

    // the real tables (not the service projections), so this code can write to fields
    // that are @readonly for outside callers, like status
    const { Users, Animals, AdoptionApplications, ApplicationHistory } =
        cds.entities('AnimalAdoption.db');

    // who is the logged-in person? (matched by email = login name)
    // used by every handler that needs to know "me"
    async function currentUser(req) {
        const me = await SELECT.one.from(Users).where({ email: req.user.id });
        if (!me) req.reject(403, 'No user profile found for your login. Please register first.');
        if (me.status !== 'Active') req.reject(403, 'Your account is not active');
        return me;
    }

    // ---------- registration: create my profile (check if user exists)----------
    this.before('CREATE', 'Users', async (req) => {
        const existing = await SELECT.one.from(Users).where({ email: req.user.id });
        if (existing) return req.reject(409, 'A profile already exists for this login');
        req.data.email  = req.user.id;   // always the logged-in person
        req.data.status = 'Active';
    });

    // ---------- "delete" my profile = deactivate it FR document----------
    // (on replaces the normal delete, so the row stays: applications and adoptions point to it, NFR-005)
    this.on('DELETE', 'Users', async (req) => {
        await UPDATE(Users, req.data.ID).with({ status: 'Inactive' });
    });

    // an application counts as "open" while it is still being handled or was approved.
    // Rejected and Withdrawn ones are finished, so the user may apply again after those.
    const OPEN_STATUSES = ['Submitted', 'Under Review', 'Approved'];

    // ---------- before a new application is saved ----------
    this.before('CREATE', 'AdoptionApplications', async (req) => {
        const me = await currentUser(req);

        // history and documents are compositions, so CAP would also save them in a "deep insert".
        // An adopter must not write their own history or documents, so we drop them.
        delete req.data.history;
        delete req.data.documents;

        const animal = await SELECT.one.from(Animals).where({ ID: req.data.animal_ID });
        if (!animal) return req.reject(404, 'Animal not found');
        if (animal.adoptionStatus !== 'Available') {
            return req.reject(409, `${animal.name} is not available for adoption`);
        }

        // duplicate guard: one open application per user and animal
        const duplicate = await SELECT.one.from(AdoptionApplications).where({
            applicant_ID: me.ID, animal_ID: animal.ID, status: { in: OPEN_STATUSES }
        });
        if (duplicate) {
            return req.reject(409, `You already applied for ${animal.name} (${duplicate.applicationID})`);
        }

        // (was: count the existing applications + 1. Replaced by nextId (highest + 1), because
        //  applicationID is now @assert.unique and a count can repeat a number seeded data already uses)
        req.data.applicationID = await nextId(AdoptionApplications, 'applicationID', 'APP-');
        req.data.applicant_ID  = me.ID;          // always the logged-in user
        req.data.status        = 'Submitted';
        req.data.applicationDate = new Date().toISOString().slice(0, 10);   // Date field, so date only
    });

    // ---------- after it is saved: first history row (after create AdoptionApplication, history is stored)----------
    // (it runs after the save because only then does the new application have an ID)
    // (CAP can hand us the saved row inside a list, so we take the ID from either shape)
    this.after('CREATE', 'AdoptionApplications', async (data, req) => {
        const saved = Array.isArray(data) ? data[0] : data;
        await INSERT.into(ApplicationHistory).entries({
            application_ID: saved?.ID ?? req.data.ID,
            newStatus: 'Submitted',
            changedBy: req.user.id
        });
    });

    // ---------- before an application is edited ----------
    // (the @restrict rule already allows this only for my own Submitted applications)
    // the animal and the links cannot be changed afterwards: otherwise a user could move an
    // application to an animal that is no longer available, or add history rows
    this.before('UPDATE', 'AdoptionApplications', (req) => {
        delete req.data.animal_ID;
        delete req.data.applicant_ID;
        delete req.data.history;
        delete req.data.documents;
    });

    // ---------- action: apply (bound to Animals) ----------
    // "Apply" button on an animal: creates the application for that animal.
    // We send a normal CREATE through this same service, so all the checks above
    // (profile, availability, duplicate guard, history row) run exactly once, in one place.
    this.on('apply', 'Animals', async (req) => {
        const key = req.params[0];
        const ID = key?.ID ?? key;   // the key can arrive as { ID } or as a plain string

        const { AdoptionApplications: MyApplications } = this.entities;   // the service projection
        // we choose the new key ourselves, so we know which row to read back afterwards
        const newID = cds.utils.uuid();
        await this.run(INSERT.into(MyApplications).entries({
            ID: newID,
            animal_ID: ID,
            reasonForAdoption: req.data.reasonForAdoption,
            housingType: req.data.housingType,
            housingDetails: req.data.housingDetails,
            hasOtherPets: req.data.hasOtherPets ?? false,
            petExperience: req.data.petExperience
        }));

        // read the full application to return it
        // (the read goes through the service, so it only shows the fields an adopter may see)
        return this.run(SELECT.one.from(MyApplications).where({ ID: newID }));
    });

    // ---------- action: withdraw ----------
    this.on('withdraw', 'AdoptionApplications', async (req) => {
        // the application the button was pressed on (key from the URL)
        const key = req.params[0];
        const ID = key?.ID ?? key;

        const me  = await currentUser(req);
        const app = await SELECT.one.from(AdoptionApplications).where({ ID });
        if (!app) return req.reject(404, 'Application not found');
        // the @restrict rule already blocks other people's applications, this is a second check
        if (app.applicant_ID !== me.ID) return req.reject(403, 'This is not your application');
        if (app.status !== 'Submitted') {
            return req.reject(409, `Cannot withdraw an application that is "${app.status}"`);
        }

        await UPDATE(AdoptionApplications, ID).with({ status: 'Withdrawn' });
        await INSERT.into(ApplicationHistory).entries({
            application_ID: ID,
            oldStatus: 'Submitted',
            newStatus: 'Withdrawn',
            changedBy: req.user.id
        });
    });

});