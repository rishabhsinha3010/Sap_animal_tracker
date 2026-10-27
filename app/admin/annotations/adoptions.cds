// Adoptions: read-only list + object page (records are created by the Approve action)
using AdminService as service from '../../../srv/admin-service';

annotate service.Adoptions with @(
    UI.HeaderInfo: {
        TypeName      : 'Adoption',
        TypeNamePlural: 'Adoptions',
        Title         : {Value: adoptionID},
        Description   : {Value: animal.name},
        TypeImageUrl  : 'sap-icon://family-care'
    },
    UI.SelectionFields: [status, adoptionDate, animal_ID],
    UI.PresentationVariant: {
        SortOrder     : [{Property: adoptionDate, Descending: true}],
        Visualizations: ['@UI.LineItem']
    },
    UI.LineItem: [
        {Value: adoptionID, ![@HTML5.CssDefaults]: {width: '8rem'}},
        {Value: animal.name,                       Label: 'Animal', ![@HTML5.CssDefaults]: {width: '9rem'}},
        {Value: application.applicant.fullName,    Label: 'Adopter', ![@HTML5.CssDefaults]: {width: '11rem'}},
        {Value: application.applicationID,         Label: 'Application', ![@HTML5.CssDefaults]: {width: '8rem'}},
        {Value: adoptionDate, ![@HTML5.CssDefaults]: {width: '9rem'}},
        {Value: status, ![@HTML5.CssDefaults]: {width: '9rem'}}
    ],
    UI.HeaderFacets: [
        {$Type: 'UI.ReferenceFacet', Target: '@UI.FieldGroup#HeaderAdopter', Label: 'Adopter'}
    ],
    UI.FieldGroup #HeaderAdopter: {Data: [
        {Value: application.applicant.fullName, Label: 'Name'},
        {Value: application.applicant.email,    Label: 'Email'}
    ]},
    UI.Facets: [
        {$Type: 'UI.ReferenceFacet', ID: 'Adoption',    Label: 'Adoption',    Target: '@UI.FieldGroup#Adoption'},
        {$Type: 'UI.ReferenceFacet', ID: 'Inspections', Label: 'Inspections', Target: 'inspections/@UI.LineItem'},
        {$Type: 'UI.ReferenceFacet', ID: 'Documents',   Label: 'Documents',   Target: 'documents/@UI.LineItem'}
    ],
    UI.FieldGroup #Adoption: {Data: [
        {Value: application.applicationID, Label: 'Application'},
        {Value: animal.name,               Label: 'Animal'},
        {Value: adoptionDate},
        {Value: status},
        {Value: completedBy},
        {Value: remarks}
    ]}
);

annotate service.Adoptions with {
    animal @(
        Common.Text           : animal.name,
        Common.TextArrangement: #TextOnly,
        Common.ValueList      : {
            CollectionPath: 'Animals',
            Parameters    : [
                {$Type: 'Common.ValueListParameterInOut',       LocalDataProperty: animal_ID, ValueListProperty: 'ID'},
                {$Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'animalID'},
                {$Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'name'}
            ]
        }
    );
};
