// SELECT, UPDATE, INSERT, req.reject and so on present in sap/cds
const cds = require('@sap/cds');

module.exports = cds.service.impl(async function () {
     console.log('>>> admin-service.js loaded');
    // Taking the name out of schema and destructuring them
    // we are not using the service version of status bz it will block it as it is decleared read only
    const { AdoptionApplications, ApplicationHistory, Adoptions, Animals, Shelters } = cds.entities('AnimalAdoption.db');

    async function changeStatus(req, allowedFrom, newStatus, extra = {}) {

        // /admin/AdoptionApplications(7f3a-91bc)/AdminService.startReview directly gets key from here [0].
        // ID comes from Base UUID
        const key = req.params[0];
        // { ID: 'abc' } or just 'abc' handle both
        const ID = key?.ID ?? key;

        const app = await SELECT.one.from(AdoptionApplications).where({ ID });
        if (!app) return req.reject(404, 'Application not found');

        // If allowedFrom is ['Submitted'] and the application is already Approved, the check fails and the admin sees "Cannot change status from "Approved" to "Under Review""
        // Without this check, someone could approve a rejected application
        if (!allowedFrom.includes(app.status)) {
            return req.reject(409, `Cannot change status from "${app.status}" to "${newStatus}"`);
        }

        // Update the application
        await UPDATE(AdoptionApplications, ID).with({
            status: newStatus,
            reviewedBy: req.user.id,
            reviewedAt: new Date().toISOString(),
            // spreads the extra filed //it's as if we'd written staffRemarks: 'Looks good' right here
            ...extra
        });

        // adds a new row to the history table
        await INSERT.into(ApplicationHistory).entries({
            application_ID: ID,
            oldStatus: app.status,
            newStatus: newStatus,
            changedBy: req.user.id,
            remarks: extra.staffRemarks || extra.rejectionReason || null
        });

    }

     // startReview is an event and its a bounded action // AdoptionApplications is a filter 
        // only run this handler when that action belongs to this entity 
        // If another entity had its own startReview action later, this handler wouldn't run for it.
        this.on('startReview', 'AdoptionApplications', async (req) => {
            await changeStatus(req, ['Submitted'], 'Under Review');
            console.log('startReview called');
        });

        // ---------- action: rejectApplication ----------
    this.on('rejectApplication', 'AdoptionApplications', async (req) => {
        const { reason } = req.data;
        await changeStatus(req, ['Under Review'], 'Rejected', { rejectionReason: reason });
    });

    // ---------- action: approve ----------
    // Insert into the real Adoptions table, bypassing the service's @readonly
    this.on('approve', 'AdoptionApplications', async (req) => {

        const { remarks } = req.data;

        // 1. the animal must still be free
        const key = req.params[0];
        const ID = key?.ID ?? key;
        const current = await SELECT.one.from(AdoptionApplications).where({ ID });
        if (!current) return req.reject(404, 'Application not found');

        const animal = await SELECT.one.from(Animals).where({ ID: current.animal_ID });
        if (animal.adoptionStatus === 'Adopted') {
            return req.reject(409, 'This animal has already been adopted');
        }

        // 2. move the application to Approved (also writes the history row)
        const app = await changeStatus(req, ['Under Review'], 'Approved', { staffRemarks: remarks });

        // 3. create the adoption record automatically
        const { count } = await SELECT.one.from(Adoptions).columns('count(*) as count'); // counts the existing adoptions
        await INSERT.into(Adoptions).entries({
            adoptionID: 'ADP-' + String(count + 1).padStart(4, '0'), // is the next number // pads with zeros to make ADP-0001
            application_ID: current.ID,
            // An association is a link, and a database table can't store a link, only a value. So CAP automatically creates a real column named <association name>_<key name>, which is animal_ + ID = animal_ID
            animal_ID: current.animal_ID,
            adoptionDate: new Date().toISOString().slice(0, 10), // cuts the timestamp down to the date
            status: 'Active'
        });

        // 4. mark the animal as adopted
        await UPDATE(Animals, current.animal_ID).with({ adoptionStatus: 'Adopted' });

        // 5. one animal left the shelter, so occupancy goes down (never below 0)
        await UPDATE(Shelters)
            .set('currentOccupancy = currentOccupancy - 1')
            .where('ID =', animal.shelter_ID, 'and currentOccupancy > 0');
    });

});