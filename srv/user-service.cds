using {AnimalAdoption.db as db} from '../db/schema';
// the enum types (HousingType...) for the parameters of the apply action
using {AnimalAdoption.common as common} from '../db/common';
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
            fullName,   // calculated (first + last name), read-only, used as the page title
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
            rejectionReason,
            // links for the "My Applications" screen (review comments, history, adoption, documents).
            // they point to the entities below, so the same row-level rules apply to them
            history,
            documents,
            adoption,
            // colour for the status, same numbers as on the admin side (3 green, 2 orange, 1 red, 0 grey)
            case
                when status = 'Approved'
                     then 3
                when status = 'Rejected'
                     then 1
                when status = 'Under Review'
                     then 2
                else 0
            end as statusCriticality : Integer,
            // the Withdraw button is only enabled while the application is still Submitted
            case
                when status = 'Submitted'
                     then true
                else false
            end as canWithdraw       : Boolean
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
            remarks,
            // so "My Applications" can show the inspection result and the adoption papers
            inspections,
            documents
        };

    // Animals: read-only, and only the fields an adopter needs
    // (fields like spayedOrNeutered and adoptionEligible are left out on purpose)
    // READ for everyone logged in, but the apply button only for the User role
    // (an admin login can look at the animals, but has no adopter profile to apply with)
    @restrict: [
        { grant: 'READ',  to: 'authenticated-user' },
        { grant: 'apply', to: 'User' }
    ]
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
            shelter,
            // health history shown on the animal page (the HealthRecords projection below decides which fields)
            healthRecords,
            // the Apply button is only enabled for an animal that is still Available
            case
                when adoptionStatus = 'Available'
                     then true
                else false
            end as canApply : Boolean
        }
        actions {
            // bound action: "apply for THIS animal". The dialog in Fiori asks for these parameters.
            // returns the new application, so the UI can jump to it
            action apply(reasonForAdoption : String(500) @mandatory,
                         housingType       : common.HousingType,
                         housingDetails    : String(500),
                         hasOtherPets      : Boolean,
                         petExperience     : String(500)) returns AdoptionApplications;
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
        ID, adoption, fileName, mediaType, fileSize, documentType, documentId, url, content
    };

    // Documents attached to my applications (read only: the admin uploads them)
    // (3 links: document -> application -> applicant -> email)
    @restrict: [{ grant: 'READ', to: 'User', where: 'application.applicant.email = $user' }]
    entity ApplicationDocuments as projection on db.ApplicationDocuments {
        ID, application, fileName, mediaType, fileSize, documentType, documentId, url, note, content
    };

    // Health certificates only (not internal medical reports)
    // filtered by document type, not by owner
    @restrict: [{ grant: 'READ', to: 'User', where: 'documentType = ''Health Certificate''' }]
    entity HealthDocuments as projection on db.HealthDocuments {
        ID, healthRecord, fileName, mediaType, fileSize, documentType, documentId, url, content
    };

};

// annotate is attach tag to existing thing 
// (it goes below the service because the entity must exist first)
// @readonly on a FIELD means a client cannot write it; our JS code writes to the real tables, so it still can
annotate UserService.Users with {
    email  @readonly; // set from the login in user-service.js
    status @readonly; // Active/Inactive is controlled by the system, not by the user
};

// buttons are greyed out when they would fail anyway (the JS handlers check it again)
annotate UserService.Animals actions {
    apply    @Core.OperationAvailable : in.canApply;
};
annotate UserService.AdoptionApplications actions {
    withdraw @Core.OperationAvailable : in.canWithdraw;
};

annotate UserService.AdoptionApplications with {
    applicant       @mandatory: false; // the handler fills it from the login
    applicationID   @readonly;
    status          @readonly;
    staffRemarks    @readonly;
    rejectionReason @readonly;
};

// My Profile page: draft gives the Fiori "Edit / Save / Cancel" buttons and keeps half-typed
// changes until Save. The checks in user-service.js run on Save (draftActivate), like on the admin side.
annotate UserService.Users with @odata.draft.enabled;

// texts for the Apply dialog (Fiori builds the dialog from the action parameters)
annotate UserService.Animals actions {
    apply(
        reasonForAdoption @title : 'Why do you want to adopt?' @UI.MultiLineText,
        housingType       @title : 'Housing Type',
        housingDetails    @title : 'Housing Details',
        hasOtherPets      @title : 'Other Pets at Home',
        petExperience     @title : 'Pet Experience'
    );
};
