// My Profile: object page only, opened from the Home page (draft: Edit / Save)
using UserService as service from '../../../srv/user-service';

annotate service.Users with @(
    // deleting = deactivating (user-service.js); not offered as a button (UI only, the API still allows it)
    UI.DeleteHidden: true,
    UI.HeaderInfo: {
        TypeName      : 'Profile',
        TypeNamePlural: 'Profiles',
        Title         : {Value: fullName},
        Description   : {Value: email},
        TypeImageUrl  : 'sap-icon://person-placeholder'
    },
    UI.Facets: [
        {$Type: 'UI.ReferenceFacet', ID: 'Person',  Label: 'Personal Details', Target: '@UI.FieldGroup#Person'},
        {$Type: 'UI.ReferenceFacet', ID: 'Address', Label: 'Address',          Target: '@UI.FieldGroup#Address'}
    ],
    UI.FieldGroup #Person: {Data: [
        {Value: firstName}, {Value: lastName}, {Value: email}, {Value: phoneNumber}, {Value: status}
    ]},
    UI.FieldGroup #Address: {Data: [
        {Value: address}, {Value: city}, {Value: state}, {Value: postalCode}
    ]}
);

annotate service.Users with {
    email @title: 'Email (your login)';
};
