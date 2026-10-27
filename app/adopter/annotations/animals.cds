// Browse Animals: list + object page with the Apply button
using UserService as service from '../../../srv/user-service';

annotate service.Animals with @(
    // adopters only look and apply: no Create / Edit / Delete buttons (the server refuses them anyway)
    UI.CreateHidden: true,
    UI.UpdateHidden: true,
    UI.DeleteHidden: true,

    UI.HeaderInfo: {
        TypeName      : 'Animal',
        TypeNamePlural: 'Animals',
        Title         : {Value: name},
        Description   : {Value: breed},
        ImageUrl      : photo,
        TypeImageUrl  : 'sap-icon://heart'
    },
    UI.SelectionFields: [species, breed, shelter_ID, adoptionStatus],
    // animals you can still adopt first
    UI.PresentationVariant: {
        SortOrder     : [{Property: adoptionCriticality, Descending: true}, {Property: name}],
        Visualizations: ['@UI.LineItem']
    },
    UI.LineItem: [
        // Apply in the table toolbar: select an animal, press Apply, fill the dialog
        {$Type: 'UI.DataFieldForAction', Action: 'UserService.apply', Label: 'Apply to Adopt'},
        {Value: photo, ![@HTML5.CssDefaults]: {width: '5rem'}},
        {Value: name, ![@HTML5.CssDefaults]: {width: '9rem'}},
        {Value: species, ![@HTML5.CssDefaults]: {width: '7rem'}},
        {Value: breed, ![@HTML5.CssDefaults]: {width: '12rem'}},
        {Value: age, ![@HTML5.CssDefaults]: {width: '6rem'}},
        {Value: adoptionFee, ![@HTML5.CssDefaults]: {width: '9rem'}},
        {Value: shelter_ID, ![@HTML5.CssDefaults]: {width: '12rem'}},
        {Value: adoptionStatus, Criticality: adoptionCriticality, CriticalityRepresentation: #WithoutIcon, ![@HTML5.CssDefaults]: {width: '9rem'}}
    ],
    UI.HeaderFacets: [
        {$Type: 'UI.ReferenceFacet', Target: '@UI.DataPoint#Adoption'},
        {$Type: 'UI.ReferenceFacet', Target: '@UI.DataPoint#Fee'},
        {$Type: 'UI.ReferenceFacet', Target: '@UI.FieldGroup#HeaderFacts', Label: 'At a Glance'}
    ],
    UI.DataPoint #Adoption: {Value: adoptionStatus, Title: 'Availability', Criticality: adoptionCriticality},
    UI.DataPoint #Fee     : {Value: adoptionFee,    Title: 'Adoption Fee'},
    UI.FieldGroup #HeaderFacts: {Data: [
        {Value: species}, {Value: gender}, {Value: age}
    ]},
    // Apply also in the object page header (enabled only while the animal is Available)
    UI.Identification: [
        {$Type: 'UI.DataFieldForAction', Action: 'UserService.apply', Label: 'Apply to Adopt', Criticality: #Positive}
    ],
    UI.Facets: [
        {$Type: 'UI.ReferenceFacet', ID: 'About',   Label: 'About',           Target: '@UI.FieldGroup#About'},
        {$Type: 'UI.ReferenceFacet', ID: 'Health',  Label: 'Health',          Target: '@UI.FieldGroup#Health'},
        {$Type: 'UI.ReferenceFacet', ID: 'Records', Label: 'Health Checkups', Target: 'healthRecords/@UI.LineItem'},
        {$Type: 'UI.ReferenceFacet', ID: 'Shelter', Label: 'Shelter',         Target: '@UI.FieldGroup#Shelter'}
    ],
    UI.FieldGroup #About: {Data: [
        {Value: description}, {Value: animalID}, {Value: species}, {Value: breed},
        {Value: gender}, {Value: age}, {Value: color}
    ]},
    UI.FieldGroup #Health: {Data: [
        {Value: healthStatus, Criticality: healthCriticality}, {Value: vaccinationStatus}
    ]},
    UI.FieldGroup #Shelter: {Data: [
        {Value: shelter.shelterName,   Label: 'Name'},
        {Value: shelter.addressLine1,  Label: 'Address'},
        {Value: shelter.city,          Label: 'City'},
        {Value: shelter.contactNumber, Label: 'Phone'},
        {Value: shelter.email,         Label: 'Email'},
        {Value: shelter.operatingTime, Label: 'Opens'},
        {Value: shelter.closingTime,   Label: 'Closes'}
    ]}
);

annotate service.Animals with {
    // the adopter sees "Availability" where the admin sees "Adoption Status"
    adoptionStatus @title: 'Availability';
    shelter @(
        Common.Text           : shelter.shelterName,
        Common.TextArrangement: #TextOnly,
        Common.ValueList      : {
            CollectionPath: 'Shelters',
            Parameters    : [
                {$Type: 'Common.ValueListParameterInOut',       LocalDataProperty: shelter_ID, ValueListProperty: 'ID'},
                {$Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'shelterName'},
                {$Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'city'}
            ]
        }
    );
};

// health checkups table inside the animal page (only the fields the user service exposes)
annotate service.HealthRecords with @(
    UI.PresentationVariant: {SortOrder: [{Property: checkupDate, Descending: true}], Visualizations: ['@UI.LineItem']},
    UI.LineItem: [
        {Value: checkupDate},
        {Value: healthStatus, Criticality: healthCriticality, CriticalityRepresentation: #WithIcon},
        {Value: healthSummary},
        {Value: adoptionEligible},
        {Value: nextCheckupDate}
    ]
);
