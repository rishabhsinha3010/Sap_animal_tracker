// My Applications: list + object page with the Withdraw button
using UserService as service from '../../../srv/user-service';

annotate service.AdoptionApplications with @(
    // applications are created only through Apply and never edited or deleted here.
    // UI.*Hidden only hides the buttons. (Capabilities.InsertRestrictions would ALSO make the server
    // refuse inserts, and then the Apply action itself could not create the application.)
    UI.CreateHidden: true,
    UI.UpdateHidden: true,
    UI.DeleteHidden: true,

    UI.HeaderInfo: {
        TypeName      : 'Application',
        TypeNamePlural: 'My Applications',
        Title         : {Value: animal.name},
        Description   : {Value: applicationID},
        TypeImageUrl  : 'sap-icon://document-text'
    },
    UI.SelectionFields: [status],
    UI.PresentationVariant: {
        SortOrder     : [{Property: applicationDate, Descending: true}],
        Visualizations: ['@UI.LineItem']
    },
    UI.LineItem: [
        {Value: applicationID, ![@HTML5.CssDefaults]: {width: '8rem'}},
        {Value: animal.name,     Label: 'Animal', ![@HTML5.CssDefaults]: {width: '9rem'}},
        {Value: animal.species,  Label: 'Species', ![@HTML5.CssDefaults]: {width: '7rem'}},
        {Value: applicationDate, Label: 'Applied On', ![@HTML5.CssDefaults]: {width: '9rem'}},
        // colour: 3 green, 2 orange, 1 red, 0 grey (statusCriticality in db/schema.cds)
        {Value: status, Criticality: statusCriticality, CriticalityRepresentation: #WithIcon, ![@HTML5.CssDefaults]: {width: '9rem'}}
    ],
    UI.HeaderFacets: [
        {$Type: 'UI.ReferenceFacet', Target: '@UI.DataPoint#Status'},
        {$Type: 'UI.ReferenceFacet', Target: '@UI.DataPoint#AppliedOn'}
    ],
    UI.DataPoint #Status   : {Value: status,          Title: 'Status', Criticality: statusCriticality},
    UI.DataPoint #AppliedOn: {Value: applicationDate, Title: 'Applied On'},
    UI.Identification: [
        {$Type: 'UI.DataFieldForAction', Action: 'UserService.withdraw', Label: 'Withdraw', Criticality: #Negative}
    ],
    UI.Facets: [
        {$Type: 'UI.ReferenceFacet', ID: 'Application', Label: 'My Application',  Target: '@UI.FieldGroup#Application'},
        {$Type: 'UI.ReferenceFacet', ID: 'Review',      Label: 'Review Comments', Target: '@UI.FieldGroup#Review'},
        {$Type: 'UI.ReferenceFacet', ID: 'History',     Label: 'History',         Target: 'history/@UI.LineItem'},
        {$Type: 'UI.ReferenceFacet', ID: 'Adoption',    Label: 'Adoption',        Target: '@UI.FieldGroup#Adoption'},
        {$Type: 'UI.ReferenceFacet', ID: 'Inspection',  Label: 'Inspection',      Target: 'adoption/inspections/@UI.LineItem'},
        {$Type: 'UI.ReferenceFacet', ID: 'Documents',   Label: 'Documents',       Target: 'documents/@UI.LineItem'}
    ],
    UI.FieldGroup #Application: {Data: [
        {Value: animal.name, Label: 'Animal'},
        {Value: applicationDate, Label: 'Applied On'},
        {Value: reasonForAdoption},
        {Value: housingType},
        {Value: housingDetails},
        {Value: hasOtherPets},
        {Value: petExperience}
    ]},
    UI.FieldGroup #Review: {Data: [
        {Value: status, Criticality: statusCriticality, CriticalityRepresentation: #WithIcon},
        {Value: staffRemarks},
        {Value: rejectionReason}
    ]},
    // empty until the application is approved
    UI.FieldGroup #Adoption: {Data: [
        {Value: adoption.adoptionID},
        {Value: adoption.adoptionDate},
        {Value: adoption.status},
        {Value: adoption.remarks}
    ]}
);

annotate service.ApplicationHistory with @(
    UI.PresentationVariant: {SortOrder: [{Property: changedAt, Descending: true}], Visualizations: ['@UI.LineItem']},
    UI.LineItem: [
        {Value: changedAt},
        {Value: oldStatus},
        {Value: newStatus},
        {Value: remarks}
    ]
);

annotate service.Inspections with @(UI.LineItem: [
    {Value: inspectionDate},
    {Value: inspectionType},
    {Value: result, Criticality: resultCriticality, CriticalityRepresentation: #WithIcon},
    {Value: remarks}
]);

// texts for the Apply dialog (Fiori builds the dialog from the action parameters)
annotate service.Animals actions {
    apply(
        reasonForAdoption @title: 'Why do you want to adopt?' @UI.MultiLineText,
        housingType       @title: 'Housing Type' @Common.ValueListWithFixedValues @Common.ValueList: {
            CollectionPath: 'CodeLists',
            Parameters    : [
                {$Type: 'Common.ValueListParameterConstant', ValueListProperty: 'list', Constant: 'HousingType'},
                {$Type: 'Common.ValueListParameterInOut', LocalDataProperty: housingType, ValueListProperty: 'code'}
            ]
        },
        housingDetails    @title: 'Housing Details' @UI.MultiLineText,
        hasOtherPets      @title: 'Other Pets at Home',
        petExperience     @title: 'Pet Experience' @UI.MultiLineText
    );
};

// Withdraw changes the status: reload it (and the history) on the page
annotate service.AdoptionApplications actions {
    withdraw @Common.SideEffects: {
        TargetProperties: ['in/status', 'in/statusCriticality', 'in/canWithdraw'],
        TargetEntities  : ['in/history']
    };
};
