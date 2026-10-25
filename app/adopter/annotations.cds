// UI annotations of the adopter app (the /user service).
// Fiori elements draws the screens from these tags, no UI code by hand.
using UserService as service from '../../srv/user-service';

// =====================================================================
// BROWSE ANIMALS (list + object page with the Apply button)
// =====================================================================
annotate service.Animals with @(
    UI.HeaderInfo : {
        TypeName       : 'Animal',
        TypeNamePlural : 'Animals',
        Title          : { Value : name },
        Description    : { Value : breed },
        ImageUrl       : photo
    },
    // filters (Step 3: species, shelter, fee, health)
    UI.SelectionFields : [ species, shelter_ID, adoptionStatus, healthStatus, adoptionFee ],
    UI.LineItem : [
        // Apply in the table toolbar: select an animal, press Apply, fill the dialog
        { $Type : 'UI.DataFieldForAction', Action : 'UserService.apply', Label : 'Apply' },
        { Value : photo,               Label : 'Photo' },
        { Value : name,                Label : 'Name' },
        { Value : species,             Label : 'Species' },
        { Value : breed,               Label : 'Breed' },
        { Value : age,                 Label : 'Age' },
        { Value : healthStatus,        Label : 'Health' },
        { Value : adoptionFee,         Label : 'Fee' },
        { Value : shelter.shelterName, Label : 'Shelter' },
        { Value : adoptionStatus,      Label : 'Status' }
    ],
    // Apply also in the object page header
    UI.Identification : [
        { $Type : 'UI.DataFieldForAction', Action : 'UserService.apply', Label : 'Apply' }
    ],
    UI.Facets : [
        { $Type : 'UI.ReferenceFacet', ID : 'About',   Label : 'About',          Target : '@UI.FieldGroup#About' },
        { $Type : 'UI.ReferenceFacet', ID : 'Health',  Label : 'Health',         Target : '@UI.FieldGroup#Health' },
        { $Type : 'UI.ReferenceFacet', ID : 'Records', Label : 'Health Checkups', Target : 'healthRecords/@UI.LineItem' },
        { $Type : 'UI.ReferenceFacet', ID : 'Shelter', Label : 'Shelter',        Target : '@UI.FieldGroup#Shelter' }
    ],
    UI.FieldGroup #About : { Data : [
        { Value : animalID }, { Value : species }, { Value : breed }, { Value : gender }, { Value : age },
        { Value : color }, { Value : description }, { Value : adoptionFee }, { Value : adoptionStatus }
    ]},
    UI.FieldGroup #Health : { Data : [
        { Value : healthStatus }, { Value : vaccinationStatus }
    ]},
    UI.FieldGroup #Shelter : { Data : [
        { Value : shelter.shelterName,   Label : 'Name' },
        { Value : shelter.addressLine1,  Label : 'Address' },
        { Value : shelter.city,          Label : 'City' },
        { Value : shelter.contactNumber, Label : 'Phone' },
        { Value : shelter.email,         Label : 'Email' },
        { Value : shelter.operatingTime, Label : 'Opens' },
        { Value : shelter.closingTime,   Label : 'Closes' }
    ]}
);
annotate service.Animals with {
    animalID          @title : 'Animal ID';
    name              @title : 'Name';
    species           @title : 'Species';
    breed             @title : 'Breed';
    gender            @title : 'Gender';
    age               @title : 'Age (years)';
    color             @title : 'Color';
    description       @title : 'Description';
    healthStatus      @title : 'Health';
    vaccinationStatus @title : 'Vaccination';
    adoptionStatus    @title : 'Availability';
    adoptionFee       @title : 'Adoption Fee';
    photo             @title : 'Photo' @UI.IsImageURL;
    shelter @(
        Common.Label : 'Shelter',
        Common.Text : shelter.shelterName,
        Common.TextArrangement : #TextOnly,
        Common.ValueList : {
            CollectionPath : 'Shelters',
            Parameters : [
                { $Type : 'Common.ValueListParameterInOut',       LocalDataProperty : shelter_ID, ValueListProperty : 'ID' },
                { $Type : 'Common.ValueListParameterDisplayOnly', ValueListProperty : 'shelterName' },
                { $Type : 'Common.ValueListParameterDisplayOnly', ValueListProperty : 'city' }
            ]
        }
    );
};

// health checkups table inside the animal page (only the fields the user service exposes)
annotate service.HealthRecords with @(
    UI.LineItem : [
        { Value : checkupDate,     Label : 'Checkup' },
        { Value : healthStatus,    Label : 'Health' },
        { Value : healthSummary,   Label : 'Summary' },
        { Value : nextCheckupDate, Label : 'Next Checkup' }
    ]
);

// =====================================================================
// MY APPLICATIONS (list + object page with the Withdraw button)
// =====================================================================
annotate service.AdoptionApplications with @(
    // applications are created only through Apply and never edited or deleted here.
    // UI.*Hidden only hides the buttons. (Capabilities.InsertRestrictions would ALSO make the server
    // refuse inserts, and then the Apply action itself could not create the application.)
    UI.CreateHidden : true,
    UI.UpdateHidden : true,
    UI.DeleteHidden : true,

    UI.HeaderInfo : {
        TypeName       : 'Application',
        TypeNamePlural : 'My Applications',
        Title          : { Value : applicationID },
        Description    : { Value : animal.name }
    },
    UI.SelectionFields : [ status ],
    UI.LineItem : [
        { Value : applicationID,   Label : 'Application' },
        { Value : animal.name,     Label : 'Animal' },
        { Value : applicationDate, Label : 'Applied On' },
        // colour: 3 green, 2 orange, 1 red, 0 grey (statusCriticality in user-service.cds)
        { Value : status,          Label : 'Status', Criticality : statusCriticality, CriticalityRepresentation : #WithIcon }
    ],
    UI.Identification : [
        { $Type : 'UI.DataFieldForAction', Action : 'UserService.withdraw', Label : 'Withdraw' }
    ],
    UI.Facets : [
        { $Type : 'UI.ReferenceFacet', ID : 'Application', Label : 'My Application',  Target : '@UI.FieldGroup#Application' },
        { $Type : 'UI.ReferenceFacet', ID : 'Review',      Label : 'Review Comments', Target : '@UI.FieldGroup#Review' },
        { $Type : 'UI.ReferenceFacet', ID : 'History',     Label : 'History',         Target : 'history/@UI.LineItem' },
        { $Type : 'UI.ReferenceFacet', ID : 'Adoption',    Label : 'Adoption',        Target : '@UI.FieldGroup#Adoption' },
        { $Type : 'UI.ReferenceFacet', ID : 'Inspection',  Label : 'Inspection',      Target : 'adoption/inspections/@UI.LineItem' },
        { $Type : 'UI.ReferenceFacet', ID : 'Documents',   Label : 'Documents',       Target : 'documents/@UI.LineItem' }
    ],
    UI.FieldGroup #Application : { Data : [
        { Value : animal.name,       Label : 'Animal' },
        { Value : applicationDate,   Label : 'Applied On' },
        { Value : reasonForAdoption, Label : 'Reason' },
        { Value : housingType,       Label : 'Housing Type' },
        { Value : housingDetails,    Label : 'Housing Details' },
        { Value : hasOtherPets,      Label : 'Other Pets' },
        { Value : petExperience,     Label : 'Pet Experience' }
    ]},
    UI.FieldGroup #Review : { Data : [
        { Value : status,          Label : 'Status', Criticality : statusCriticality, CriticalityRepresentation : #WithIcon },
        { Value : staffRemarks,    Label : 'Staff Remarks' },
        { Value : rejectionReason, Label : 'Rejection Reason' }
    ]},
    // empty until the application is approved
    UI.FieldGroup #Adoption : { Data : [
        { Value : adoption.adoptionID,   Label : 'Adoption ID' },
        { Value : adoption.adoptionDate, Label : 'Adoption Date' },
        { Value : adoption.status,       Label : 'Adoption Status' },
        { Value : adoption.remarks,      Label : 'Remarks' }
    ]}
);
annotate service.AdoptionApplications with {
    status          @title : 'Status';
    applicationDate @title : 'Applied On';
};

annotate service.ApplicationHistory with @(
    UI.LineItem : [
        { Value : changedAt, Label : 'When' },
        { Value : oldStatus, Label : 'From' },
        { Value : newStatus, Label : 'To' },
        { Value : remarks,   Label : 'Remarks' }
    ]
);

annotate service.Inspections with @(
    UI.LineItem : [
        { Value : inspectionDate, Label : 'Date' },
        { Value : inspectionType, Label : 'Type' },
        { Value : result,         Label : 'Result' },
        { Value : remarks,        Label : 'Remarks' }
    ]
);

annotate service.ApplicationDocuments with @(
    UI.LineItem : [
        { Value : fileName,     Label : 'File' },
        { Value : documentType, Label : 'Type' },
        // url = Cloudinary link (opens the file); content download works too
        { $Type : 'UI.DataFieldWithUrl', Value : url, Url : url, Label : 'Link' },
        { Value : note,         Label : 'Note' }
    ]
);

// =====================================================================
// MY PROFILE (object page only, opened from the Home page)
// =====================================================================
annotate service.Users with @(
    // deleting = deactivating (user-service.js); not offered as a button (UI only, the API still allows it)
    UI.DeleteHidden : true,
    UI.HeaderInfo : {
        TypeName       : 'Profile',
        TypeNamePlural : 'Profiles',
        Title          : { Value : fullName },
        Description    : { Value : email }
    },
    UI.Facets : [
        { $Type : 'UI.ReferenceFacet', ID : 'Person',  Label : 'Personal Details', Target : '@UI.FieldGroup#Person' },
        { $Type : 'UI.ReferenceFacet', ID : 'Address', Label : 'Address',          Target : '@UI.FieldGroup#Address' }
    ],
    UI.FieldGroup #Person : { Data : [
        { Value : firstName }, { Value : lastName }, { Value : email }, { Value : phoneNumber }, { Value : status }
    ]},
    UI.FieldGroup #Address : { Data : [
        { Value : address }, { Value : city }, { Value : state }, { Value : postalCode }
    ]}
);
annotate service.Users with {
    firstName   @title : 'First Name';
    lastName    @title : 'Last Name';
    fullName    @title : 'Name';
    email       @title : 'Email (your login)';
    phoneNumber @title : 'Phone';
    address     @title : 'Address';
    city        @title : 'City';
    state       @title : 'State';
    postalCode  @title : 'Postal Code';
    status      @title : 'Account Status';
};
