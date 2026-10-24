// we have decleared all events here along with helper functions
// this.before(event, entity, fn)
//CAP gives every entity the standard operations (CRUD) automatically: 'CREATE', 'READ', 'UPDATE'.... (no need to define action)
const cds = require('@sap/cds');

module.exports = cds.service.impl(async function () {

    const { Users, Animals, AdoptionApplications, ApplicationHistory } =
        cds.entities('AnimalAdoption.db');

    // who is the logged-in person? (matched by email = login name)
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
    this.on('DELETE', 'Users', async (req) => {
        await UPDATE(Users, req.data.ID).with({ status: 'Inactive' });
    });

    // ---------- before a new application is saved ----------
    this.before('CREATE', 'AdoptionApplications', async (req) => {
        const me = await currentUser(req);

        const animal = await SELECT.one.from(Animals).where({ ID: req.data.animal_ID });
        if (!animal) return req.reject(404, 'Animal not found');
        if (animal.adoptionStatus !== 'Available') {
            return req.reject(409, `${animal.name} is not available for adoption`);
        }

        const { count } = await SELECT.one.from(AdoptionApplications).columns('count(*) as count');
        req.data.applicationID = 'APP-' + String(count + 1).padStart(4, '0');
        req.data.applicant_ID  = me.ID;          // always the logged-in user
        req.data.status        = 'Submitted';
        req.data.applicationDate = new Date().toISOString().slice(0, 10);   // Date field, so date only
    });

    // ---------- after it is saved: first history row (after create AdoptionApplication, history is stored)----------
    this.after('CREATE', 'AdoptionApplications', async (data, req) => {
        await INSERT.into(ApplicationHistory).entries({
            application_ID: data.ID,
            newStatus: 'Submitted',
            changedBy: req.user.id
        });
    });

    // ---------- action: withdraw ----------
    this.on('withdraw', 'AdoptionApplications', async (req) => {
        const key = req.params[0];
        const ID = key?.ID ?? key;

        const me  = await currentUser(req);
        const app = await SELECT.one.from(AdoptionApplications).where({ ID });
        if (!app) return req.reject(404, 'Application not found');
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