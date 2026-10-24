using { AnimalAdoption.db as db } from '../db/schema';

// service AdminService @(path : '/admin', requires: 'Admin') 
// requires to get login for acces (security)
service AdminService @(path : '/admin', requires: 'Admin'){
    // full access (create, read, update, delete)
    entity Animals              as projection on db.Animals;
    entity Shelters             as projection on db.Shelters;
    entity Users                as projection on db.Users;
    entity HealthRecords        as projection on db.HealthRecords;
    entity Inspections          as projection on db.Inspections;
    entity AdoptionApplications as projection on db.AdoptionApplications actions{
        // bound actions
        //Bound means the action belongs to one specific application

        // moves an application from Submitted to Under Review.
            action startReview();
        // The remarks are optional, because the admin may not have anything to add.
            action approve(remarks : String(500));
        // @mandatory means the admin can't reject without a reason.
            action rejectApplication(reason : String(500) @mandatory);
    };

    // read-only: records are created by the system, never by hand
    @readonly entity Adoptions          as projection on db.Adoptions;
    @readonly entity ApplicationHistory as projection on db.ApplicationHistory;

    // documents: admin uploads and maintains files
    entity ApplicationDocuments as projection on db.ApplicationDocuments;
    entity AdoptionDocuments    as projection on db.AdoptionDocuments;
    entity HealthDocuments      as projection on db.HealthDocuments;
    entity InspectionDocuments  as projection on db.InspectionDocuments;
}

annotate AdminService.AdoptionApplications with {
    status          @readonly;
    reviewedBy      @readonly;
    reviewedAt      @readonly;
    rejectionReason @readonly;
};