// Health Records: list + object page (draft), with the Mark Recovered button
using AdminService as service from '../../../srv/admin-service';

annotate service.HealthRecords with @(
    UI.HeaderInfo: {
        TypeName      : 'Health Record',
        TypeNamePlural: 'Health Records',
        Title         : {Value: animal.name},
        Description   : {Value: checkupDate},
        TypeImageUrl  : 'sap-icon://stethoscope'
    },
    UI.SelectionFields: [animal_ID, healthStatus, checkupDate, nextCheckupDate],
    UI.PresentationVariant: {
        SortOrder     : [{Property: checkupDate, Descending: true}],
        Visualizations: ['@UI.LineItem']
    },
    UI.LineItem: [
        // button in the table toolbar: select a row, then press it
        {$Type: 'UI.DataFieldForAction', Action: 'AdminService.markRecovered', Label: 'Mark Recovered'},
        {Value: animal_ID, ![@HTML5.CssDefaults]: {width: '10rem'}},
        {Value: checkupDate, ![@HTML5.CssDefaults]: {width: '9rem'}},
        {Value: healthStatus, Criticality: healthCriticality, CriticalityRepresentation: #WithIcon, ![@HTML5.CssDefaults]: {width: '9rem'}},
        {Value: vaccinationStatus, ![@HTML5.CssDefaults]: {width: '10rem'}},
        {Value: veterinarianName, ![@HTML5.CssDefaults]: {width: '11rem'}},
        {Value: nextCheckupDate, ![@HTML5.CssDefaults]: {width: '9rem'}}
    ],
    UI.HeaderFacets: [
        {$Type: 'UI.ReferenceFacet', Target: '@UI.DataPoint#Health'},
        {$Type: 'UI.ReferenceFacet', Target: '@UI.DataPoint#NextCheckup'}
    ],
    UI.DataPoint #Health     : {Value: healthStatus,    Title: 'Health', Criticality: healthCriticality},
    UI.DataPoint #NextCheckup: {Value: nextCheckupDate, Title: 'Next Checkup'},
    // the same button in the object page header
    UI.Identification: [
        {$Type: 'UI.DataFieldForAction', Action: 'AdminService.markRecovered', Label: 'Mark Recovered'}
    ],
    UI.Facets: [
        {$Type: 'UI.ReferenceFacet', ID: 'Checkup',   Label: 'Checkup',   Target: '@UI.FieldGroup#Checkup'},
        {$Type: 'UI.ReferenceFacet', ID: 'Treatment', Label: 'Treatment', Target: '@UI.FieldGroup#Treatment'},
        {$Type: 'UI.ReferenceFacet', ID: 'Documents', Label: 'Documents', Target: 'documents/@UI.LineItem'}
    ],
    UI.FieldGroup #Checkup: {Data: [
        {Value: animal_ID}, {Value: checkupDate}, {Value: veterinarianName},
        {Value: healthStatus}, {Value: vaccinationStatus}, {Value: weight},
        {Value: adoptionEligible}, {Value: nextCheckupDate}
    ]},
    UI.FieldGroup #Treatment: {Data: [
        {Value: diagnosis}, {Value: treatment}, {Value: medication},
        {Value: healthSummary}, {Value: remarks}
    ]}
);

// animal picker (same idea as on the applications)
annotate service.HealthRecords with {
    animal @(
        Common.Text           : animal.name,
        Common.TextArrangement: #TextOnly,
        Common.ValueList      : {
            CollectionPath: 'Animals',
            Parameters    : [
                {$Type: 'Common.ValueListParameterInOut',       LocalDataProperty: animal_ID, ValueListProperty: 'ID'},
                {$Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'animalID'},
                {$Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'name'},
                {$Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'species'}
            ]
        }
    );
};

// Mark Recovered changes the record (and the animal): reload it on the page
annotate service.HealthRecords actions {
    markRecovered @Common.SideEffects: {
        TargetProperties: ['in/healthStatus', 'in/healthCriticality', 'in/adoptionEligible', 'in/nextCheckupDate', 'in/remarks']
    };
};
