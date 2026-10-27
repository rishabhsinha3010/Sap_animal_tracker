// Adoption Applications: list + object page with Start Review / Approve / Reject
using AdminService as service from '../../../srv/admin-service';

annotate service.AdoptionApplications with @(
    // no Delete button: applications must be kept for 7 years (NFR-005), the server refuses deletes too
    Capabilities.DeleteRestrictions: {Deletable: false},

    UI.HeaderInfo: {
        TypeName      : 'Application',
        TypeNamePlural: 'Applications',
        Title         : {Value: applicationID},
        Description   : {Value: animal.name},
        TypeImageUrl  : 'sap-icon://document-text'
    },

    // filter bar of the list report (FR-ADM-006: search, filter, sort)
    UI.SelectionFields: [status, animal_ID, applicationDate],

    // newest first
    UI.PresentationVariant: {
        SortOrder     : [{Property: applicationDate, Descending: true}],
        Visualizations: ['@UI.LineItem']
    },

    UI.LineItem: [
        {Value: applicationID, ![@HTML5.CssDefaults]: {width: '8rem'}},
        {Value: animal.name,        Label: 'Animal', ![@HTML5.CssDefaults]: {width: '9rem'}},
        {Value: animal.species,     Label: 'Species', ![@HTML5.CssDefaults]: {width: '7rem'}},
        {Value: applicant.fullName, Label: 'Applicant', ![@HTML5.CssDefaults]: {width: '11rem'}},
        {Value: applicationDate, ![@HTML5.CssDefaults]: {width: '9rem'}},
        {Value: housingType, ![@HTML5.CssDefaults]: {width: '10rem'}},
        // Criticality colours the status (statusCriticality: 3 green, 2 orange, 1 red, 0 grey)
        {Value: status, Criticality: statusCriticality, CriticalityRepresentation: #WithIcon, ![@HTML5.CssDefaults]: {width: '9rem'}}
    ],

    // key facts in the object page header
    UI.HeaderFacets: [
        {$Type: 'UI.ReferenceFacet', Target: '@UI.DataPoint#Status'},
        {$Type: 'UI.ReferenceFacet', Target: '@UI.FieldGroup#HeaderApplicant', Label: 'Applicant'},
        {$Type: 'UI.ReferenceFacet', Target: '@UI.FieldGroup#HeaderDates', Label: 'Dates'}
    ],
    UI.DataPoint #Status: {Value: status, Title: 'Status', Criticality: statusCriticality},
    UI.FieldGroup #HeaderApplicant: {Data: [
        {Value: applicant.fullName,    Label: 'Name'},
        {Value: applicant.email,       Label: 'Email'},
        {Value: applicant.phoneNumber, Label: 'Phone'}
    ]},
    UI.FieldGroup #HeaderDates: {Data: [
        {Value: applicationDate},
        {Value: reviewedAt}
    ]},

    // review buttons in the object page header (enabled by canStartReview / canDecide)
    UI.Identification: [
        {$Type: 'UI.DataFieldForAction', Action: 'AdminService.startReview',       Label: 'Start Review'},
        {$Type: 'UI.DataFieldForAction', Action: 'AdminService.approve',           Label: 'Approve', Criticality: #Positive},
        {$Type: 'UI.DataFieldForAction', Action: 'AdminService.rejectApplication', Label: 'Reject',  Criticality: #Negative}
    ],

    UI.Facets: [
        {$Type: 'UI.ReferenceFacet', ID: 'Animal',    Label: 'Animal',                 Target: '@UI.FieldGroup#Animal'},
        {$Type: 'UI.ReferenceFacet', ID: 'Housing',   Label: 'Home and Experience',    Target: '@UI.FieldGroup#Housing'},
        {$Type: 'UI.ReferenceFacet', ID: 'Review',    Label: 'Review',                 Target: '@UI.FieldGroup#Review'},
        {$Type: 'UI.ReferenceFacet', ID: 'History',   Label: 'Status History (Audit)', Target: 'history/@UI.LineItem'},
        {$Type: 'UI.ReferenceFacet', ID: 'Documents', Label: 'Supporting Documents',   Target: 'documents/@UI.LineItem'}
    ],
    UI.FieldGroup #Animal: {Data: [
        {Value: animal.animalID, Label: 'Animal ID'},
        {Value: animal.name,     Label: 'Name'},
        {Value: animal.species,  Label: 'Species'},
        {Value: animal.breed,    Label: 'Breed'},
        {Value: animal.adoptionStatus, Label: 'Adoption Status'},
        {Value: reasonForAdoption}
    ]},
    UI.FieldGroup #Housing: {Data: [
        {Value: housingType},
        {Value: housingDetails},
        {Value: hasOtherPets},
        {Value: petExperience}
    ]},
    UI.FieldGroup #Review: {Data: [
        {Value: status, Criticality: statusCriticality, CriticalityRepresentation: #WithIcon},
        {Value: reviewedBy},
        {Value: reviewedAt},
        {Value: staffRemarks},
        {Value: rejectionReason}
    ]}
);

// texts of the Approve / Reject dialogs
annotate service.AdoptionApplications actions {
    approve(remarks @title: 'Remarks for the adopter' @UI.MultiLineText);
    rejectApplication(reason @title: 'Reason for rejection' @UI.MultiLineText);
};

// audit table inside the object page
annotate service.ApplicationHistory with @(
    UI.PresentationVariant: {SortOrder: [{Property: changedAt, Descending: true}], Visualizations: ['@UI.LineItem']},
    UI.LineItem: [
        {Value: changedAt},
        {Value: oldStatus},
        {Value: newStatus},
        {Value: changedBy},
        {Value: remarks}
    ]
);

// animal filter / field: show the NAME instead of the ID and open a pick list of animals
annotate service.AdoptionApplications with {
    animal @(
        Common.Text           : animal.name,
        Common.TextArrangement: #TextOnly,
        Common.ValueList      : {
            Label         : 'Animals',
            CollectionPath: 'Animals',
            Parameters    : [
                {$Type: 'Common.ValueListParameterInOut',       LocalDataProperty: animal_ID, ValueListProperty: 'ID'},
                {$Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'animalID'},
                {$Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'name'},
                {$Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'species'},
                {$Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'adoptionStatus'}
            ]
        }
    );
    applicant @(
        Common.Text           : applicant.fullName,
        Common.TextArrangement: #TextOnly
    );
};
