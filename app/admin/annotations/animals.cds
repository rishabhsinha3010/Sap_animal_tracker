// Animals: list + object page (draft: Create / Edit / Save)
using AdminService as service from '../../../srv/admin-service';

annotate service.Animals with @(
    UI.HeaderInfo: {
        TypeName      : 'Animal',
        TypeNamePlural: 'Animals',
        Title         : {Value: name},
        Description   : {Value: breed},
        ImageUrl      : photo,   // the photo (Cloudinary URL) shows in the header
        TypeImageUrl  : 'sap-icon://heart'
    },
    UI.SelectionFields: [species, adoptionStatus, healthStatus, shelter_ID],
    UI.PresentationVariant: {
        SortOrder     : [{Property: animalID}],
        Visualizations: ['@UI.LineItem']
    },
    UI.LineItem: [
        {Value: photo, ![@HTML5.CssDefaults]: {width: '5rem'}},
        {Value: animalID, Label: 'ID', ![@HTML5.CssDefaults]: {width: '6rem'}},
        {Value: name, ![@HTML5.CssDefaults]: {width: '9rem'}},
        {Value: species, ![@HTML5.CssDefaults]: {width: '7rem'}},
        {Value: breed, ![@HTML5.CssDefaults]: {width: '10rem'}},
        {Value: shelter_ID, ![@HTML5.CssDefaults]: {width: '10rem'}},
        {Value: healthStatus,   Criticality: healthCriticality,   CriticalityRepresentation: #WithoutIcon, ![@HTML5.CssDefaults]: {width: '9rem'}},
        {Value: adoptionStatus, Criticality: adoptionCriticality, CriticalityRepresentation: #WithoutIcon, ![@HTML5.CssDefaults]: {width: '9rem'}},
        {Value: adoptionFee, ![@HTML5.CssDefaults]: {width: '8rem'}}
    ],
    UI.HeaderFacets: [
        {$Type: 'UI.ReferenceFacet', Target: '@UI.DataPoint#Adoption'},
        {$Type: 'UI.ReferenceFacet', Target: '@UI.DataPoint#Health'},
        {$Type: 'UI.ReferenceFacet', Target: '@UI.DataPoint#Fee'}
    ],
    UI.DataPoint #Adoption: {Value: adoptionStatus, Title: 'Adoption Status', Criticality: adoptionCriticality},
    UI.DataPoint #Health  : {Value: healthStatus,   Title: 'Health',          Criticality: healthCriticality},
    UI.DataPoint #Fee     : {Value: adoptionFee,    Title: 'Adoption Fee'},
    UI.Facets: [
        {$Type: 'UI.ReferenceFacet', ID: 'Details', Label: 'Details',             Target: '@UI.FieldGroup#Details'},
        {$Type: 'UI.ReferenceFacet', ID: 'Status',  Label: 'Health and Adoption', Target: '@UI.FieldGroup#Status'},
        {$Type: 'UI.ReferenceFacet', ID: 'Health',  Label: 'Health Records',      Target: 'healthRecords/@UI.LineItem'}
    ],
    UI.FieldGroup #Details: {Data: [
        {Value: animalID}, {Value: name}, {Value: species}, {Value: breed}, {Value: gender},
        {Value: age}, {Value: color}, {Value: arrivalDate}, {Value: shelter_ID},
        {Value: photo}, {Value: description}
    ]},
    UI.FieldGroup #Status: {Data: [
        {Value: healthStatus, Criticality: healthCriticality}, {Value: vaccinationStatus}, {Value: adoptionEligible},
        {Value: adoptionStatus, Criticality: adoptionCriticality}, {Value: adoptionFee}
    ]}
);

// shelter picker: shows the shelter NAME and opens a list of shelters with free places
annotate service.Animals with {
    shelter @(
        Common.Text           : shelter.shelterName,
        Common.TextArrangement: #TextOnly,
        Common.ValueList      : {
            CollectionPath: 'Shelters',
            Parameters    : [
                {$Type: 'Common.ValueListParameterInOut',       LocalDataProperty: shelter_ID, ValueListProperty: 'ID'},
                {$Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'shelterName'},
                {$Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'city'},
                {$Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'currentOccupancy'},
                {$Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'capacity'}
            ]
        }
    );
};
