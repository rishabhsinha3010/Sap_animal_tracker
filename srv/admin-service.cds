using {AnimalAdoption.db as db} from '../db/schema';

// service AdminService @(path : '/admin', requires: 'Admin')
// requires to get login for acces (security)
// requires: 'Admin' -> only a logged-in user with the Admin role can use this service.
// Anyone else gets 401 (not logged in) or 403 (logged in, wrong role).
service AdminService @(
    path    : '/admin',
    requires: 'Admin'
) {
    // full access (create, read, update, delete)
    // each line is a "projection": a window onto a table. CAP gives CRUD for free.
    entity Animals              as projection on db.Animals;
    entity Shelters             as projection on db.Shelters;
    entity Users                as projection on db.Users;

    entity HealthRecords        as projection on db.HealthRecords
        actions {
            // Fiori screen #7 "Mark Recovered": sets the record (and the animal) back to Healthy
            action markRecovered();
        };

    entity Inspections          as projection on db.Inspections;

    entity AdoptionApplications as
        projection on db.AdoptionApplications {
            *,
            // colour code for the status in Fiori: 0 grey, 1 red, 2 orange, 3 green
            // calculated when read, so it is never stored
            case
                when status = 'Approved'
                     then 3
                when status = 'Rejected'
                     then 1
                when status = 'Under Review'
                     then 2
                else 0
            end as statusCriticality : Integer,
            // which review buttons make sense right now (used by Fiori to enable or grey them out)
            case
                when status = 'Submitted'
                     then true
                else false
            end as canStartReview    : Boolean,
            case
                when status = 'Under Review'
                     then true
                else false
            end as canDecide         : Boolean
        }

        actions {
            // bound actions
            //Bound means the action belongs to one specific application

            // moves an application from Submitted to Under Review.
            action startReview();
            // The remarks are optional, because the admin may not have anything to add.
            action approve(remarks: String(500));
            // @mandatory means the admin can't reject without a reason.
            // (named rejectApplication, not reject, because CAP already has a method called reject)
            action rejectApplication(reason: String(500) @mandatory );
        };

    // read-only: records are created by the system, never by hand
    // @readonly blocks POST, PATCH and DELETE (our own JS code can still write to the real tables)
    @readonly
    entity Adoptions            as projection on db.Adoptions;

    @readonly
    entity ApplicationHistory   as projection on db.ApplicationHistory;

    // documents: admin uploads and maintains files
    entity ApplicationDocuments as projection on db.ApplicationDocuments;
    entity AdoptionDocuments    as projection on db.AdoptionDocuments;
    entity HealthDocuments      as projection on db.HealthDocuments;
    entity InspectionDocuments  as projection on db.InspectionDocuments;

    // ---------- dashboard (all read-only views) ----------
    // A view ("select from") is calculated every time it is read, so the numbers are never out of date.
    // @cds.redirection.target: false -> without it the compiler cannot tell which of two entities
    // on the same table the links should point to.

    // KPI cards: one row with the animal counts (FR-ADM-023)
    // Unavailable = every animal that is neither Available nor Adopted (Reserved, Under Treatment)
    @readonly
    @cds.redirection.target: false
    entity AnimalSummary        as
        select from db.Animals {
            key 1          as ID                 : Integer, // fixed key, because every OData entity needs one
                count( * ) as totalAnimals       : Integer,
                sum(case
                        when adoptionStatus = 'Available'
                             then 1
                        else 0
                    end)   as availableAnimals   : Integer,
                sum(case
                        when adoptionStatus = 'Adopted'
                             then 1
                        else 0
                    end)   as adoptedAnimals     : Integer,
                sum(case
                        when adoptionStatus not in (
                                 'Available', 'Adopted'
                             )
                             then 1
                        else 0
                    end)   as unavailableAnimals : Integer
        };

    // bar chart: applications per status (FR-ADM-024)
    // a status with no applications does not appear (treat it as 0 in the UI)
    @readonly
    @cds.redirection.target: false
    entity ApplicationsByStatus as
        select from db.AdoptionApplications {
            key status,
                count( * ) as total : Integer
        }
        group by
            status;

    // line chart: adoptions per month (FR-ADM-025)
    // counts every adoption that was not cancelled
    @readonly
    @cds.redirection.target: false
    entity AdoptionTrend        as
        select from db.Adoptions {
            key year(adoptionDate)  as year  : Integer,
            key month(adoptionDate) as month : Integer,
                count( * )          as total : Integer
        }
        where
            status != 'Cancelled'
        group by
            year(adoptionDate),
            month(adoptionDate);

    // health checkups whose next checkup date has passed (FR-ADM-014)
    @readonly
    @cds.redirection.target: false
    entity OverdueCheckups      as
        projection on db.HealthRecords {
            ID,
            animal,
            checkupDate,
            nextCheckupDate,
            healthStatus
        }
        where
            nextCheckupDate < $now;

    // shelter occupancy with progress bar value (FR-ADM-026)
    // occupancyPercentage is the calculated field from the Shelters entity
    @readonly
    @cds.redirection.target: false
    entity ShelterOccupancy     as
        projection on db.Shelters {
            ID,
            shelterName,
            city,
            currentOccupancy,
            capacity,
            occupancyPercentage
        };
}

// annotate = attach tags to something that already exists (so it goes after the service)
// these fields can only be changed by the actions, never by a normal edit.
// That is what makes the review history trustworthy.
annotate AdminService.AdoptionApplications with {
    status          @readonly;
    reviewedBy      @readonly;
    reviewedAt      @readonly;
    rejectionReason @readonly;
};

// the buttons are only enabled when the application is in the right status:
// Start Review for a Submitted one, Approve and Reject for one that is Under Review
// (the JS handlers check this too, so the rule also holds for direct API calls)
annotate AdminService.AdoptionApplications actions {
    startReview       @Core.OperationAvailable : in.canStartReview;
    approve           @Core.OperationAvailable : in.canDecide;
    rejectApplication @Core.OperationAvailable : in.canDecide;
};
