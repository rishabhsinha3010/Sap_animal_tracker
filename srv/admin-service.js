// SELECT, UPDATE, INSERT, req.reject and so on present in sap/cds
const cds = require('@sap/cds');
// take the query builders from cds.ql, not the globals: the Fiori UI plugin loads a second copy
// of @sap/cds, and then the global SELECT/INSERT/UPDATE belong to the wrong copy
const { SELECT, INSERT, UPDATE } = cds.ql;
// shared "next code number" helper (also used by user-service.js)
const { nextId } = require('./lib/ids');

module.exports = cds.service.impl(async function () {
    // Taking the name out of schema and destructuring them
    // we are not using the service version of status bz it will block it as it is decleared read only
    const { AdoptionApplications, ApplicationHistory, Adoptions, Animals, Shelters,
            HealthRecords, Inspections, Users } = cds.entities('AnimalAdoption.db');

    // =====================================================================
    // HELPERS (small functions used by several handlers below)
    // =====================================================================

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

        // gives the application row (as it was before the change) back to the caller
        return app;
    }

    // in an "after" handler CAP gives the saved row, sometimes inside a list ([{ ID: ... }]),
    // so data.ID can be undefined. This takes the ID either way (and falls back to the request).
    function savedID(data, req) {
        const row = Array.isArray(data) ? data[0] : data;
        return row?.ID ?? req.data?.ID;
    }

    // next number for a code like ANM-0001: takes the highest existing one and adds 1.
    // (counting rows would repeat a number after a delete, the highest number never does)
    // -> moved to srv/lib/ids.js, so user-service.js can use the same logic for APP- codes

    // recounts a shelter's occupancy from the animals really in it (FR-ADM-022)
    // occupancy = animals in the shelter that are not adopted yet
    // we recount instead of doing +1 / -1, so the number can never drift out of sync
    async function refreshShelter(shelterID) {
        if (!shelterID) return;
        const shelter = await SELECT.one.from(Shelters).where({ ID: shelterID });
        if (!shelter) return;

        const { count } = await SELECT.one.from(Animals)
            .columns('count(*) as count')
            .where('shelter_ID =', shelterID, 'and adoptionStatus !=', 'Adopted');

        const changes = { currentOccupancy: count };
        // Active <-> Full follows the occupancy (an Inactive shelter stays Inactive)
        if (shelter.status === 'Active' && count >= shelter.capacity) changes.status = 'Full';
        if (shelter.status === 'Full'   && count <  shelter.capacity) changes.status = 'Active';
        await UPDATE(Shelters, shelterID).with(changes);
    }

    // an animal can only go into a shelter that is open and has room
    function checkShelterHasRoom(req, shelter) {
        if (!shelter) return req.reject(404, 'Shelter not found');
        if (shelter.status === 'Inactive') return req.reject(409, `${shelter.shelterName} is inactive`);
        if (shelter.currentOccupancy >= shelter.capacity) {
            return req.reject(409, `${shelter.shelterName} is full`);
        }
    }

    // copies the newest health record onto the animal (FR-ADM-012, 013, 016)
    // "newest" = latest checkup date, so editing an old record does not overwrite newer facts
    async function syncAnimalHealth(animalID) {
        const latest = await SELECT.one.from(HealthRecords)
            .where({ animal_ID: animalID })
            .orderBy('checkupDate desc', 'createdAt desc');
        if (!latest) return;

        const changes = { adoptionEligible: latest.adoptionEligible };
        if (latest.healthStatus)      changes.healthStatus = latest.healthStatus;
        if (latest.vaccinationStatus) changes.vaccinationStatus = latest.vaccinationStatus;
        await UPDATE(Animals, animalID).with(changes);
    }

    // =====================================================================
    // APPLICATION REVIEW ACTIONS
    // =====================================================================

     // startReview is an event and its a bounded action // AdoptionApplications is a filter 
        // only run this handler when that action belongs to this entity 
        // If another entity had its own startReview action later, this handler wouldn't run for it.
        this.on('startReview', 'AdoptionApplications', async (req) => {
            await changeStatus(req, ['Submitted'], 'Under Review');
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
        // (this check has to run BEFORE the status changes, so we read the application here
        //  and changeStatus reads it once more)
        const key = req.params[0];
        const ID = key?.ID ?? key;
        const current = await SELECT.one.from(AdoptionApplications).where({ ID });
        if (!current) return req.reject(404, 'Application not found');

        const animal = await SELECT.one.from(Animals).where({ ID: current.animal_ID });
        if (animal.adoptionStatus === 'Adopted') {
            return req.reject(409, 'This animal has already been adopted');
        }

        // 2. move the application to Approved (also writes the history row)
        await changeStatus(req, ['Under Review'], 'Approved', { staffRemarks: remarks });

        // 3. create the adoption record automatically
        // (was: count the existing adoptions + 1. Replaced by nextId (highest + 1), because adoptionID is
        //  now @assert.unique and a count can repeat a number that seeded data already uses)
        await INSERT.into(Adoptions).entries({
            adoptionID: await nextId(Adoptions, 'adoptionID', 'ADP-'), // is the next number // pads with zeros to make ADP-0001
            application_ID: current.ID,
            // An association is a link, and a database table can't store a link, only a value. So CAP automatically creates a real column named <association name>_<key name>, which is animal_ + ID = animal_ID
            animal_ID: current.animal_ID,
            adoptionDate: new Date().toISOString().slice(0, 10), // cuts the timestamp down to the date
            status: 'Active'
        });

        // 4. mark the animal as adopted
        await UPDATE(Animals, current.animal_ID).with({ adoptionStatus: 'Adopted' });

        // 5. one animal left the shelter, so occupancy goes down
        // (refreshShelter recounts, so it can never go below 0 and the Full status resets itself)
        await refreshShelter(animal.shelter_ID);
    });

    // =====================================================================
    // ANIMALS (FR-ADM-001, 002, 005, 022)
    // =====================================================================

    // before a new animal is saved: the shelter must have room, and we generate the animal ID
    // (animalID is @readonly, so only this code can fill it)
    this.before('CREATE', 'Animals', async (req) => {
        const shelter = await SELECT.one.from(Shelters).where({ ID: req.data.shelter_ID });
        if (req.data.adoptionStatus !== 'Adopted') checkShelterHasRoom(req, shelter);
        req.data.animalID = await nextId(Animals, 'animalID', 'ANM-');
    });

    // after it is saved: recount the shelter
    this.after('CREATE', 'Animals', async (data, req) => {
        const animal = await SELECT.one.from(Animals).where({ ID: savedID(data, req) });
        await refreshShelter(animal.shelter_ID);
    });

    // before an animal is changed: remember where it was, and check the new shelter if it moves
    this.before('UPDATE', 'Animals', async (req) => {
        const old = await SELECT.one.from(Animals).where({ ID: req.data.ID });
        if (!old) return;
        req._prevShelterID = old.shelter_ID;      // remembered for the "after" handler
        if (req.data.shelter_ID && req.data.shelter_ID !== old.shelter_ID) {
            const target = await SELECT.one.from(Shelters).where({ ID: req.data.shelter_ID });
            checkShelterHasRoom(req, target);
        }
    });

    // after it is changed: recount the new shelter, and the old one if the animal moved
    // (also catches an admin setting the adoption status to Adopted by hand)
    this.after('UPDATE', 'Animals', async (data, req) => {
        const animal = await SELECT.one.from(Animals).where({ ID: savedID(data, req) });
        await refreshShelter(animal.shelter_ID);
        if (req._prevShelterID && req._prevShelterID !== animal.shelter_ID) {
            await refreshShelter(req._prevShelterID);
        }
    });

    // deleting an animal frees its place in the shelter
    this.before('DELETE', 'Animals', async (req) => {
        const animal = await SELECT.one.from(Animals).where({ ID: req.data.ID });
        req._prevShelterID = animal?.shelter_ID;
    });
    this.after('DELETE', 'Animals', async (_, req) => {
        await refreshShelter(req._prevShelterID);
    });

    // =====================================================================
    // HEALTH RECORDS (FR-ADM-012, 013, 016, Fiori screen #7)
    // =====================================================================

    // after a health record is created or changed, the animal shows the newest health facts
    this.after(['CREATE', 'UPDATE'], 'HealthRecords', async (data, req) => {
        const record = await SELECT.one.from(HealthRecords).where({ ID: savedID(data, req) });
        await syncAnimalHealth(record.animal_ID);
    });

    // ---------- action: markRecovered ----------
    this.on('markRecovered', 'HealthRecords', async (req) => {
        const key = req.params[0];
        const ID = key?.ID ?? key;

        const record = await SELECT.one.from(HealthRecords).where({ ID });
        if (!record) return req.reject(404, 'Health record not found');

        await UPDATE(HealthRecords, ID).with({ healthStatus: 'Healthy' });
        await syncAnimalHealth(record.animal_ID);

        // an animal that was "Under Treatment" and is healthy again can be adopted again
        const animal = await SELECT.one.from(Animals).where({ ID: record.animal_ID });
        if (animal.healthStatus === 'Healthy' && animal.adoptionStatus === 'Under Treatment') {
            await UPDATE(Animals, animal.ID).with({ adoptionStatus: 'Available' });
        }
    });

    // =====================================================================
    // INSPECTIONS (FR-ADM-019)
    // =====================================================================

    // a Validated inspection completes the adoption (only if it is still Active)
    // completedBy is the admin who validated it
    this.after(['CREATE', 'UPDATE'], 'Inspections', async (data, req) => {
        const inspection = await SELECT.one.from(Inspections).where({ ID: savedID(data, req) });
        if (inspection?.result === 'Validated') {
            await UPDATE(Adoptions)
                .with({ status: 'Completed', completedBy: req.user.id })
                .where({ ID: inspection.adoption_ID, status: 'Active' });
        }
    });

    // =====================================================================
    // DOCUMENTS (NFR-007, NFR-011)
    // =====================================================================

    // PDF, JPEG, JPG and PNG only, up to 10 MB per file (a .jpg file has the type image/jpeg)
    const ALLOWED_TYPES = ['application/pdf', 'image/jpeg', 'image/png'];
    const MAX_FILE_SIZE = 10 * 1024 * 1024;

        this.before(['CREATE', 'UPDATE'],
        ['ApplicationDocuments', 'AdoptionDocuments', 'HealthDocuments', 'InspectionDocuments'],
        (req) => {
            // when the file itself is uploaded (PUT .../content) its type and size come from the request headers
            if (req.data.content) {
                const type   = (req.headers?.['content-type'] || '').split(';')[0].trim();
                const length = Number(req.headers?.['content-length']);
                if (!ALLOWED_TYPES.includes(type)) {
                    return req.reject(400, 'Only PDF, JPEG, JPG and PNG files are allowed');
                }
                if (length > MAX_FILE_SIZE) {
                    return req.reject(400, 'The file is larger than 10 MB');
                }
                req.data.fileSize = length;     // store the real size next to the file
                return;
            }
            const { mediaType, fileSize } = req.data;
            if (mediaType && !ALLOWED_TYPES.includes(mediaType)) {
                return req.reject(400, 'Only PDF, JPEG, JPG and PNG files are allowed');
            }
            if (fileSize && fileSize > MAX_FILE_SIZE) {
                return req.reject(400, 'The file is larger than 10 MB');
            }
        });

    // =====================================================================
    // DATA RETENTION (NFR-005: applications and adoption records are kept 7 years)
    // =====================================================================

    // applications can never be deleted (Adoptions are already read-only)
    this.before('DELETE', 'AdoptionApplications', (req) => {
        return req.reject(405, 'Adoption applications must be kept for 7 years and cannot be deleted');
    });

    // deleting a user only deactivates the profile, like on the user side,
    // because that user's applications and adoptions point to the row
    this.on('DELETE', 'Users', async (req) => {
        await UPDATE(Users, req.data.ID).with({ status: 'Inactive' });
    });

});