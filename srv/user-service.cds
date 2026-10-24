using {AnimalAdoption.db as db} from '../db/schema';
// In @restrict, anything not granted is denied, so these are read-only without needing @readonly.

service UserService @(
    path    : '/user',
    requires: 'authenticated-user'
) { // as it is authenticated user the admin can also login and see readonly data of the user.
    // (the personal data below is still protected by the row-level rules, so only the
    //  public read-only entities at the bottom are visible to an admin login)
    // @restrict is the row-level rule
    // Profile: a user can read only their own
    // $user gets the users email
    @restrict: [
        {
            grant: 'READ', // caps bz already defined by CAP
            to   : 'User',
            where: 'email = $user'
        },
        {
            grant: 'CREATE', // registration: no "where" because the row does not exist yet
            to   : 'User'
        },
        {
            grant: [
                'UPDATE',
                'DELETE' // delete is changed to "deactivate" in user-service.js
            ],
            to   : 'User',
            where: 'email = $user'
        }
    ] // gets user email from the user entity
    entity Users                as
        projection on db.Users {
            // role is not listed, so a user can never make themselves an Admin
            ID,
            firstName,
            lastName,
            email,
            phoneNumber,
            address,
            city,
            state,
            postalCode,
            status
        };

    // Applications: own only, including reviewer comments // gets the email from user entity in association to AdoptionApplication
    // (the where path follows the link: application -> applicant -> email)
    @restrict: [
        {
            grant: 'READ',
            to   : 'User',
            where: 'applicant.email = $user'
        },
        {
            grant: 'CREATE',
            to   : 'User'
        },
        {
            // edit only before review: once the status changes, this condition fails
            // ('' inside the text means one single quote)
            grant: 'UPDATE',
            to   : 'User',
            where: 'applicant.email = $user and status = ''Submitted'''
        },
        {
            grant: 'withdraw', // custom action
            to   : 'User',
            where: 'applicant.email = $user'
        }
    ]
    entity AdoptionApplications as
        projection on db.AdoptionApplications {
            // applicant must stay in this list: the where rules above follow it
            ID,
            applicationID,
            animal,
            applicant,
            applicationDate,
            reasonForAdoption,
            housingType,
            housingDetails,
            hasOtherPets,
            petExperience,
            status,
            staffRemarks,
            rejectionReason
        }
        actions {
            action withdraw();
        };

    // Adoption records: own only
    @restrict: [{
        grant: 'READ',
        to   : 'User',
        where: 'application.applicant.email = $user'
    }] // 2 link association here
    entity Adoptions            as
        projection on db.Adoptions {
            ID,
            adoptionID,
            application,
            animal,
            adoptionDate,
            status,
            remarks
        };

    // Animals: read-only, and only the fields an adopter needs
    // (fields like spayedOrNeutered and adoptionEligible are left out on purpose)
    @readonly
    entity Animals              as
        projection on db.Animals {
            ID,
            animalID,
            name,
            species,
            breed,
            gender,
            age,
            color,
            photo,
            description,
            healthStatus,
            vaccinationStatus,
            adoptionStatus,
            adoptionFee,
            shelter
        };

    // Shelters: read-only, contact details only (no capacity or licence info)
    @readonly
    entity Shelters             as
        projection on db.Shelters {
            ID,
            shelterName,
            addressLine1,
            addressLine2,
            city,
            state,
            postalCode,
            contactNumber,
            email,
            website,
            operatingTime,
            closingTime
        };

    // Health records: read-only summary view
    // (diagnosis, treatment and medication are internal, so they are not listed)
    @readonly
    entity HealthRecords        as
        projection on db.HealthRecords {
            ID,
            animal,
            checkupDate,
            healthStatus,
            healthSummary,
            adoptionEligible,
            nextCheckupDate
        };

        // Status history of my applications
        // (changedBy is left out: the adopter only needs status, remarks and time)
    @restrict: [{ grant: 'READ', to: 'User', where: 'application.applicant.email = $user' }]
    entity ApplicationHistory as projection on db.ApplicationHistory {
        ID, application, oldStatus, newStatus, changedAt, remarks
    };

    // Inspections done on my adoptions
    // (4 links: inspection -> adoption -> application -> applicant -> email)
    @restrict: [{ grant: 'READ', to: 'User', where: 'adoption.application.applicant.email = $user' }]
    entity Inspections as projection on db.Inspections {
        ID, adoption, inspectionDate, inspectionType, result, remarks
    };

    // Documents (agreements, certificates, letters) of my adoptions
    @restrict: [{ grant: 'READ', to: 'User', where: 'adoption.application.applicant.email = $user' }]
    entity AdoptionDocuments as projection on db.AdoptionDocuments {
        ID, adoption, fileName, mediaType, fileSize, documentType, documentId, url
    };

    // Health certificates only (not internal medical reports)
    // filtered by document type, not by owner
    @restrict: [{ grant: 'READ', to: 'User', where: 'documentType = ''Health Certificate''' }]
    entity HealthDocuments as projection on db.HealthDocuments {
        ID, healthRecord, fileName, mediaType, fileSize, documentType, documentId, url
    };

};

// annotate is attach tag to existing thing 
// (it goes below the service because the entity must exist first)
// @readonly on a FIELD means a client cannot write it; our JS code writes to the real tables, so it still can
annotate UserService.Users with {
    email  @readonly; // set from the login in user-service.js
    status @readonly; // Active/Inactive is controlled by the system, not by the user
};

annotate UserService.AdoptionApplications with {
    applicant       @mandatory: false; // the handler fills it from the login
    applicationID   @readonly;
    status          @readonly;
    staffRemarks    @readonly;
    rejectionReason @readonly;
};