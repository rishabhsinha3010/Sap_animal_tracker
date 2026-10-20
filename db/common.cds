namespace AnimalAdoption.common;

// Predefined aspect from cds : Aspect: a reusable bundle of fields that gets added into an entity.
using {
    cuid,
    managed // 
} from '@sap/cds/common';

// As it is predefined by CAP it is filled automatically. We dont have to maintain these fields.
aspect Base : cuid, managed {}

// Type: a set of allowed values that can be used in an entity.
// a user-defined data type in computer programming that represents a fixed set of named constants
//Fixed list of values given by FR document. CAP rejects anything outside the list, and Fiori turns them into dropdowns.
type Gender            : String(10) enum {
    Male;
    Female;
    Unknown;
}

type HealthStatus      : String(20) enum {
    Healthy;
    Sick;
    Injured;
    // left side is used in code and right side is used in UI
    UnderTreatment = 'Under Treatment';
    Critical;
}

type VaccinationStatus : String(20) enum {
    Vaccinated;
    PartiallyVaccinated = 'Partially Vaccinated';
    NotVaccinated = 'Not Vaccinated';
}

type ApplicationStatus : String(20) enum {
  Submitted;
  UnderReview = 'Under Review';
  Approved;
  Rejected;
  Withdrawn;
}

type AdoptionRecordStatus : String(20) enum {
  Active;
  Completed;
  Cancelled;
}

type AdoptionStatus    : String(20) enum {
    Available;
    Reserved;
    Adopted;
    UnderTreatment = 'Under Treatment';
}

type InspectionType : String(20) enum {
  Initial;
  FollowUp = 'Follow-up';
  Routine;
}

type InspectionResult : String(20) enum {
  Pending;
  Validated;
  FollowUpRequired = 'Follow-up Required';
  Failed;
}

type HousingType       : String(30) enum {
    Apartment;
    IndependentHouse = 'Independent House';
    Farm;
    Other;
}

type ShelterStatus     : String(10) enum {
    Active;
    Inactive;
    Full;
}

type UserRole          : String(10) enum {
    Admin;
    User;
}

type AccountStatus     : String(10) enum {
    Active;
    Inactive;
    Blocked;
}

type DocumentType : String(30) enum {
  AdoptionAgreement   = 'Adoption Agreement';
  AdoptionCertificate = 'Adoption Certificate';
  ApprovalLetter      = 'Approval Letter';
  HealthCertificate   = 'Health Certificate';
  MedicalReport       = 'Medical Report';
  InspectionReport    = 'Inspection Report';
  SupportingDocument  = 'Supporting Document';
}

aspect Attachment : Base {
  fileName     : String(255) @mandatory;
  mediaType    : String(100) @mandatory;
  fileSize     : Integer;
  documentType : DocumentType;
  documentId   : String(255);   // object id in SAP Document Management Service
  url          : String(1000);
  note         : String(500);
}
