using AdminService as service from '../../srv/admin-service';

annotate service.AdoptionApplications with @(
    // no Delete button: applications must be kept for 7 years (NFR-005), the server refuses deletes too
    Capabilities.DeleteRestrictions : { Deletable : false }
);

// readable names for the filter fields (without these the raw field names show up)
annotate service.AdoptionApplications with {
    status          @title : 'Status';
    applicationDate @title : 'Application Date';
};

// UI annotations = instructions for Fiori elements: which columns, filters, sections and buttons to draw.
// No UI code is written by hand, Fiori elements builds the screens from these tags.

annotate service.AdoptionApplications with @(

    // title area at the top of the object page, and the names used in the list
    UI.HeaderInfo : {
        TypeName       : 'Application',
        TypeNamePlural : 'Applications',
        Title          : { Value : applicationID },
        Description    : { Value : status }   // (the colour is shown in the list and in the Review section)
    },

    // filter bar of the list report (FR-ADM-006: search, filter, sort)
    UI.SelectionFields : [ status, applicationDate, animal_ID ],

    // columns of the list report (Fiori screen #4)
    UI.LineItem : [
        { Value : applicationID,        Label : 'Application ID' },
        { Value : animal.name,          Label : 'Animal' },
        { Value : applicant.fullName,   Label : 'Applicant' },
        { Value : applicationDate,      Label : 'Application Date' },
        // Criticality colours the status (statusCriticality: 3 green, 2 orange, 1 red, 0 grey)
        { Value : status,               Label : 'Status', Criticality : statusCriticality, CriticalityRepresentation : #WithIcon }
    ],

    // buttons in the header of the object page (Fiori screen #5)
    UI.Identification : [
        { $Type : 'UI.DataFieldForAction', Action : 'AdminService.startReview',        Label : 'Start Review' },
        { $Type : 'UI.DataFieldForAction', Action : 'AdminService.approve',            Label : 'Approve' },
        { $Type : 'UI.DataFieldForAction', Action : 'AdminService.rejectApplication',  Label : 'Reject' }
    ],

    // the sections of the object page
    UI.Facets : [
        { $Type : 'UI.ReferenceFacet', ID : 'ApplicantInfo', Label : 'Applicant and Animal', Target : '@UI.FieldGroup#ApplicantInfo' },
        { $Type : 'UI.ReferenceFacet', ID : 'Housing',       Label : 'Housing and Experience', Target : '@UI.FieldGroup#Housing' },
        { $Type : 'UI.ReferenceFacet', ID : 'Review',        Label : 'Review', Target : '@UI.FieldGroup#Review' },
        { $Type : 'UI.ReferenceFacet', ID : 'History',       Label : 'Status History (Audit)', Target : 'history/@UI.LineItem' },
        { $Type : 'UI.ReferenceFacet', ID : 'Documents',     Label : 'Supporting Documents', Target : 'documents/@UI.LineItem' }
    ],

    UI.FieldGroup #ApplicantInfo : { Data : [
        { Value : applicant.fullName,  Label : 'Applicant' },
        { Value : applicant.email,     Label : 'Email' },
        { Value : applicant.phoneNumber, Label : 'Phone' },
        { Value : animal.name,         Label : 'Animal' },
        { Value : animal.species,      Label : 'Species' },
        { Value : animal.breed,        Label : 'Breed' },
        { Value : applicationDate,     Label : 'Application Date' },
        { Value : reasonForAdoption,   Label : 'Reason for Adoption' }
    ]},

    UI.FieldGroup #Housing : { Data : [
        { Value : housingType,    Label : 'Housing Type' },
        { Value : housingDetails, Label : 'Housing Details' },
        { Value : hasOtherPets,   Label : 'Has Other Pets' },
        { Value : petExperience,  Label : 'Pet Experience' }
    ]},

    UI.FieldGroup #Review : { Data : [
        { Value : status,          Label : 'Status', Criticality : statusCriticality, CriticalityRepresentation : #WithIcon },
        { Value : reviewedBy,      Label : 'Reviewed By' },
        { Value : reviewedAt,      Label : 'Reviewed At' },
        { Value : staffRemarks,    Label : 'Staff Remarks' },
        { Value : rejectionReason, Label : 'Rejection Reason' }
    ]}
);

// the audit table shown inside the object page (Fiori screen #6)
annotate service.ApplicationHistory with @(
    UI.LineItem : [
        { Value : changedAt, Label : 'When' },
        { Value : oldStatus, Label : 'From' },
        { Value : newStatus, Label : 'To' },
        { Value : changedBy, Label : 'By' },
        { Value : remarks,   Label : 'Remarks' }
    ]
);

// the documents table shown inside the object page
annotate service.ApplicationDocuments with @(
    UI.LineItem : [
        { Value : fileName,     Label : 'File' },
        { Value : documentType, Label : 'Type' },
        { Value : fileSize,     Label : 'Size (bytes)' },
        { Value : note,         Label : 'Note' }
    ]
);

// the animal filter and the animal field show the animal's NAME instead of an ID,
// and open a value help (a pick list of animals) when the user clicks the filter
annotate service.AdoptionApplications with {
    animal @(
        Common.Label : 'Animal',
        Common.Text : animal.name,
        Common.TextArrangement : #TextOnly,
        Common.ValueList : {
            Label : 'Animals',
            CollectionPath : 'Animals',
            Parameters : [
                { $Type : 'Common.ValueListParameterInOut',       LocalDataProperty : animal_ID, ValueListProperty : 'ID' },
                { $Type : 'Common.ValueListParameterDisplayOnly', ValueListProperty : 'animalID' },
                { $Type : 'Common.ValueListParameterDisplayOnly', ValueListProperty : 'name' },
                { $Type : 'Common.ValueListParameterDisplayOnly', ValueListProperty : 'species' },
                { $Type : 'Common.ValueListParameterDisplayOnly', ValueListProperty : 'adoptionStatus' }
            ]
        }
    );
};