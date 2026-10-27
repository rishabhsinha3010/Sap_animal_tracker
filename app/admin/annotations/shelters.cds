// Shelters: list + object page (draft), with the occupancy shown as a progress bar
using AdminService as service from '../../../srv/admin-service';

annotate service.Shelters with @(
    UI.HeaderInfo: {
        TypeName      : 'Shelter',
        TypeNamePlural: 'Shelters',
        Title         : {Value: shelterName},
        Description   : {Value: city},
        TypeImageUrl  : 'sap-icon://building'
    },
    UI.SelectionFields: [city, status],
    UI.PresentationVariant: {
        SortOrder     : [{Property: shelterName}],
        Visualizations: ['@UI.LineItem']
    },
    UI.LineItem: [
        {Value: shelterName, ![@HTML5.CssDefaults]: {width: '13rem'}},
        {Value: shelterCode, ![@HTML5.CssDefaults]: {width: '7rem'}},
        {Value: city, ![@HTML5.CssDefaults]: {width: '9rem'}},
        {Value: contactNumber, ![@HTML5.CssDefaults]: {width: '10rem'}},
        {Value: capacity, ![@HTML5.CssDefaults]: {width: '6rem'}},
        {Value: currentOccupancy, ![@HTML5.CssDefaults]: {width: '9rem'}},
        // progress bar of how full the shelter is
        {$Type: 'UI.DataFieldForAnnotation', Target: '@UI.DataPoint#Occupancy', Label: 'Occupancy', ![@HTML5.CssDefaults]: {width: '11rem'}},
        {Value: status, ![@HTML5.CssDefaults]: {width: '9rem'}}
    ],
    UI.DataPoint #Occupancy: {
        Value        : occupancyPercentage,
        TargetValue  : 100,
        Title        : 'Occupancy',
        Visualization: #Progress
    },
    UI.HeaderFacets: [
        {$Type: 'UI.ReferenceFacet', Target: '@UI.DataPoint#Occupancy'},
        {$Type: 'UI.ReferenceFacet', Target: '@UI.FieldGroup#HeaderContact', Label: 'Contact'}
    ],
    UI.FieldGroup #HeaderContact: {Data: [
        {Value: contactNumber},
        {Value: email},
        {$Type: 'UI.DataFieldWithUrl', Value: website, Url: website}
    ]},
    UI.Facets: [
        {$Type: 'UI.ReferenceFacet', ID: 'General', Label: 'General',             Target: '@UI.FieldGroup#General'},
        {$Type: 'UI.ReferenceFacet', ID: 'Address', Label: 'Address and Contact', Target: '@UI.FieldGroup#Address'},
        {$Type: 'UI.ReferenceFacet', ID: 'Animals', Label: 'Animals',             Target: 'animals/@UI.LineItem'}
    ],
    UI.FieldGroup #General: {Data: [
        {Value: shelterName}, {Value: shelterCode}, {Value: shelterType}, {Value: licenseNumber},
        {Value: capacity}, {Value: currentOccupancy}, {Value: status},
        {Value: operatingTime}, {Value: closingTime}
    ]},
    UI.FieldGroup #Address: {Data: [
        {Value: addressLine1}, {Value: addressLine2}, {Value: city}, {Value: state},
        {Value: postalCode}, {Value: country}, {Value: contactNumber}, {Value: email}, {Value: website}
    ]}
);
