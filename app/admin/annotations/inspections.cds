// Inspections: list + object page (draft). Setting the result to Validated completes the adoption.
using AdminService as service from '../../../srv/admin-service';

annotate service.Inspections with @(
    UI.HeaderInfo: {
        TypeName      : 'Inspection',
        TypeNamePlural: 'Inspections',
        Title         : {Value: adoption.adoptionID},
        Description   : {Value: inspectionType},
        TypeImageUrl  : 'sap-icon://inspection'
    },
    UI.SelectionFields: [result, inspectionType, inspectionDate],
    UI.PresentationVariant: {
        SortOrder     : [{Property: inspectionDate, Descending: true}],
        Visualizations: ['@UI.LineItem']
    },
    UI.LineItem: [
        {Value: adoption_ID, ![@HTML5.CssDefaults]: {width: '8rem'}},
        {Value: adoption.animal.name, Label: 'Animal', ![@HTML5.CssDefaults]: {width: '9rem'}},
        {Value: inspectionDate, ![@HTML5.CssDefaults]: {width: '9rem'}},
        {Value: inspectionType, ![@HTML5.CssDefaults]: {width: '8rem'}},
        {Value: inspector_ID, ![@HTML5.CssDefaults]: {width: '11rem'}},
        {Value: result, Criticality: resultCriticality, CriticalityRepresentation: #WithIcon, ![@HTML5.CssDefaults]: {width: '10rem'}}
    ],
    UI.HeaderFacets: [
        {$Type: 'UI.ReferenceFacet', Target: '@UI.DataPoint#Result'}
    ],
    UI.DataPoint #Result: {Value: result, Title: 'Result', Criticality: resultCriticality},
    UI.Facets: [
        {$Type: 'UI.ReferenceFacet', ID: 'Inspection', Label: 'Inspection', Target: '@UI.FieldGroup#Inspection'},
        {$Type: 'UI.ReferenceFacet', ID: 'Findings',   Label: 'Findings',   Target: '@UI.FieldGroup#Findings'},
        {$Type: 'UI.ReferenceFacet', ID: 'Documents',  Label: 'Documents',  Target: 'documents/@UI.LineItem'}
    ],
    UI.FieldGroup #Inspection: {Data: [
        {Value: adoption_ID}, {Value: inspector_ID},
        {Value: inspectionDate}, {Value: inspectionType}, {Value: result}
    ]},
    UI.FieldGroup #Findings: {Data: [
        {Value: animalCondition}, {Value: findings}, {Value: existingPetDetails}, {Value: remarks}
    ]}
);

annotate service.Inspections with {
    adoption @(
        Common.Text           : adoption.adoptionID,
        Common.TextArrangement: #TextOnly,
        Common.ValueList      : {
            CollectionPath: 'Adoptions',
            Parameters    : [
                {$Type: 'Common.ValueListParameterInOut',       LocalDataProperty: adoption_ID, ValueListProperty: 'ID'},
                {$Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'adoptionID'},
                {$Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'adoptionDate'},
                {$Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'status'}
            ]
        }
    );
    inspector @(
        Common.Text           : inspector.fullName,
        Common.TextArrangement: #TextOnly,
        Common.ValueList      : {
            CollectionPath: 'Users',
            Parameters    : [
                {$Type: 'Common.ValueListParameterInOut',       LocalDataProperty: inspector_ID, ValueListProperty: 'ID'},
                {$Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'fullName'},
                {$Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'email'}
            ]
        }
    );
};
