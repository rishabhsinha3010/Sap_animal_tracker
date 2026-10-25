using {AnimalAdoption.common as common} from './common';

namespace AnimalAdoption.db; //namespace created of the project

// ---------------- Shelters ----------------
entity Shelters : common.Base {
    // @ Annotations are tags that adds rules or behavior to a filed. 
    shelterName         : String(100) @mandatory;
    shelterCode         : String(20);
    addressLine1        : String(100);
    addressLine2        : String(100);
    city                : String(50);
    state               : String(50);
    postalCode          : String(20);
    country             : String(20);
    contactNumber       : String(20);
    email               : String(100);
    website             : String(200);
    licenseNumber       : String(50);
    shelterType         : String(50);
    operatingTime       : Time;
    closingTime         : Time;
    capacity            : Integer @mandatory @assert.range: [1, 100000];
    currentOccupancy    : Integer default 0;
    occupancyPercentage : Decimal(5, 2) = case
                                              when capacity > 0
                                              then (currentOccupancy * 100.0 / capacity)
                                              else 0
                                          end;
    status              : common.ShelterStatus default 'Active';
    imageUrl            : String(1000);   // Cloudinary URL of the shelter picture (upload comes later)
    animals             : Association to many Animals on animals.shelter = $self;
}

// ---------------- Animals ----------------
// @assert.unique: CAP refuses a second row with the same animalID (the generated code must stay unique)
@assert.unique.animalID: [animalID]
entity Animals : common.Base {
    animalID          : String(20) @readonly;   // generated in service logic, e.g. ANM-0001
    shelter           : Association to Shelters @mandatory;   // creates shelter_ID
    name              : String(100) @mandatory;
    species           : String(50)  @mandatory;
    breed             : String(100);
    gender            : common.Gender;
    age               : Integer @assert.range: [0, 60];
    color             : String(50);
    arrivalDate       : Date;
    healthStatus      : common.HealthStatus      default 'Healthy';
    vaccinationStatus : common.VaccinationStatus default 'Not Vaccinated';
    adoptionStatus    : common.AdoptionStatus    default 'Available';
    adoptionEligible  : Boolean default false;
    adoptionFee       : Decimal(10, 2) @assert.range: [0, 999999];
    // Cloudinary URL of the photo (String(1000) because Cloudinary URLs with transformations get long;
    // the sample data uses small data-URI emoji pictures instead)
    photo             : String(1000);
    description       : String(500);
    // Association (not Composition): with draft, a Composition would make health records part of the
    // animal's draft, so they could only be edited inside an animal. Health records get their own app.
    healthRecords     : Association to many HealthRecords on healthRecords.animal = $self;
    applications      : Association to many AdoptionApplications on applications.animal = $self;
}

// ---------------- Users ----------------
@assert.unique.email: [email]
entity Users : common.Base {
    firstName   : String(100) @mandatory;
    lastName    : String(100) @mandatory;
     // calculated when read (not stored): first name + last name, used by the Fiori screens
    fullName    : String(201) = firstName || ' ' || lastName;
    email       : String(255) @mandatory @assert.format: '^[^@\s]+@[^@\s]+\.[^@\s]+$';
    phoneNumber : String(20) @assert.format: '^[0-9+\- ]{7,20}$';
    address     : String(255);
    city        : String(100);
    state       : String(100);
    postalCode  : String(20);
    role        : common.UserRole      default 'User';
    status      : common.AccountStatus default 'Active';
    applications : Association to many AdoptionApplications on applications.applicant = $self;
}

// ---------------- Adoption Applications ----------------
@assert.unique.applicationID: [applicationID]
entity AdoptionApplications : common.Base {
    applicationID     : String(20) @readonly;
    animal            : Association to Animals @mandatory;   // animal_ID
    applicant         : Association to Users   @mandatory;   // applicant_ID
    applicationDate   : Date;  // set by the handler when the application is created
    reasonForAdoption : String(500) @mandatory;
    housingType       : common.HousingType;
    housingDetails    : String(500);
    hasOtherPets      : Boolean default false;
    petExperience     : String(500);
    status            : common.ApplicationStatus default 'Submitted';
    reviewedBy        : String(100);
    reviewedAt        : Timestamp;
    staffRemarks      : String(500);
    rejectionReason   : String(500);
    documents         : Composition of many ApplicationDocuments on documents.application = $self;
    history           : Composition of many ApplicationHistory   on history.application   = $self;
    // the adoption created when this application is approved (empty before that).
    // "to one ... on" = no extra column, CAP finds it through Adoptions.application
    adoption          : Association to one Adoptions on adoption.application = $self;
}

entity ApplicationDocuments : common.Attachment {
    application : Association to AdoptionApplications;
}

entity ApplicationHistory : common.Base {
    application : Association to AdoptionApplications;
    oldStatus   : common.ApplicationStatus;
    newStatus   : common.ApplicationStatus;
    changedBy   : String(100);
    changedAt   : Timestamp default $now;
    remarks     : String(500);
}

// ---------------- Adoptions (auto-created on approval) ----------------
@assert.unique.application: [application]
@assert.unique.adoptionID: [adoptionID]
entity Adoptions : common.Base {
    adoptionID   : String(20) @readonly;
    application  : Association to AdoptionApplications @mandatory;   // application_ID
    animal       : Association to Animals @mandatory;                // animal_ID
    adoptionDate : Date; // set by the approve action
    status       : common.AdoptionRecordStatus default 'Active';
    completedBy  : String(100);
    remarks      : String(500);
    documents    : Composition of many AdoptionDocuments on documents.adoption = $self;
    inspections  : Association to many Inspections on inspections.adoption = $self;
}

entity AdoptionDocuments : common.Attachment {
    adoption : Association to Adoptions;
}

// ---------------- Health Records ----------------
entity HealthRecords : common.Base {
    animal            : Association to Animals @mandatory;   // animal_ID
    checkupDate       : Date @mandatory;
    healthStatus      : common.HealthStatus;
    vaccinationStatus : common.VaccinationStatus;
    diagnosis         : String(500);
    treatment         : String(500);
    medication        : String(500);
    veterinarianName  : String(100);
    weight            : Decimal(10, 2);
    healthSummary     : String(500);
    adoptionEligible  : Boolean default false;
    nextCheckupDate   : Date;
    remarks           : String(500);
    documents         : Composition of many HealthDocuments on documents.healthRecord = $self;
}

entity HealthDocuments : common.Attachment {
    healthRecord : Association to HealthRecords;
}

// ---------------- Inspections ----------------
entity Inspections : common.Base {
    adoption           : Association to Adoptions @mandatory;   // adoption_ID
    inspector          : Association to Users;                  // inspector_ID
    inspectionDate     : Date @mandatory;
    inspectionType     : common.InspectionType default 'Initial';
    animalCondition    : String(500);
    findings           : String(500);
    existingPetDetails : String(500);
    result             : common.InspectionResult default 'Pending';
    remarks            : String(500);
    documents          : Composition of many InspectionDocuments on documents.inspection = $self;
}

entity InspectionDocuments : common.Attachment {
    inspection : Association to Inspections;
}

