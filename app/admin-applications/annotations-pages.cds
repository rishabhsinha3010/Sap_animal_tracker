// UI annotations for the other admin pages (Animals, Shelters, Health Records, Inspections).
// Same idea as annotations.cds (which holds the Applications pages): Fiori elements draws the
// screens from these tags. Kept in a second file so each file stays readable.
using AdminService as service from '../../srv/admin-service';

// =====================================================================
// ANIMALS (list + object page, draft: Create / Edit / Save)
// =====================================================================
annotate service.Animals with @(
    UI.HeaderInfo : {
        TypeName       : 'Animal',
        TypeNamePlural : 'Animals',
        Title          : { Value : name },
        Description    : { Value : animalID },
        ImageUrl       : photo   // the photo (data-URI now, Cloudinary URL later) shows in the header
    },
    UI.SelectionFields : [ species, adoptionStatus, healthStatus, shelter_ID ],
    UI.LineItem : [
        { Value : photo,               Label : 'Photo' },
        { Value : animalID,            Label : 'Animal ID' },
        { Value : name,                Label : 'Name' },
        { Value : species,             Label : 'Species' },
        { Value : breed,               Label : 'Breed' },
        { Value : shelter.shelterName, Label : 'Shelter' },
        { Value : healthStatus,        Label : 'Health' },
        { Value : adoptionStatus,      Label : 'Adoption Status' },
        { Value : adoptionFee,         Label : 'Fee' }
    ],
    UI.Facets : [
        { $Type : 'UI.ReferenceFacet', ID : 'Details', Label : 'Details',             Target : '@UI.FieldGroup#Details' },
        { $Type : 'UI.ReferenceFacet', ID : 'Status',  Label : 'Health and Adoption', Target : '@UI.FieldGroup#Status' },
        { $Type : 'UI.ReferenceFacet', ID : 'Health',  Label : 'Health Records',      Target : 'healthRecords/@UI.LineItem' }
    ],
    UI.FieldGroup #Details : { Data : [
        { Value : name }, { Value : species }, { Value : breed }, { Value : gender },
        { Value : age }, { Value : color }, { Value : arrivalDate },
        { Value : shelter_ID, Label : 'Shelter' },
        { Value : photo, Label : 'Photo' },
        { Value : description }
    ]},
    UI.FieldGroup #Status : { Data : [
        { Value : healthStatus }, { Value : vaccinationStatus }, { Value : adoptionEligible },
        { Value : adoptionStatus }, { Value : adoptionFee }
    ]}
);

// labels: used by filters, forms and table headers when no Label is given above
annotate service.Animals with {
    animalID          @title : 'Animal ID';
    name              @title : 'Name';
    species           @title : 'Species';
    breed             @title : 'Breed';
    gender            @title : 'Gender';
    age               @title : 'Age (years)';
    color             @title : 'Color';
    arrivalDate       @title : 'Arrival Date';
    healthStatus      @title : 'Health Status';
    vaccinationStatus @title : 'Vaccination';
    adoptionStatus    @title : 'Adoption Status';
    adoptionEligible  @title : 'Eligible for Adoption';
    adoptionFee       @title : 'Adoption Fee';
    description       @title : 'Description';
    photo             @title : 'Photo' @UI.IsImageURL;   // show the value as a picture, not as text
    // shelter picker: shows the shelter NAME and opens a list of shelters
    shelter @(
        Common.Label : 'Shelter',
        Common.Text : shelter.shelterName,
        Common.TextArrangement : #TextOnly,
        Common.ValueList : {
            CollectionPath : 'Shelters',
            Parameters : [
                { $Type : 'Common.ValueListParameterInOut',       LocalDataProperty : shelter_ID, ValueListProperty : 'ID' },
                { $Type : 'Common.ValueListParameterDisplayOnly', ValueListProperty : 'shelterName' },
                { $Type : 'Common.ValueListParameterDisplayOnly', ValueListProperty : 'city' },
                { $Type : 'Common.ValueListParameterDisplayOnly', ValueListProperty : 'currentOccupancy' },
                { $Type : 'Common.ValueListParameterDisplayOnly', ValueListProperty : 'capacity' }
            ]
        }
    );
};

// =====================================================================
// SHELTERS
// =====================================================================
annotate service.Shelters with @(
    UI.HeaderInfo : {
        TypeName       : 'Shelter',
        TypeNamePlural : 'Shelters',
        Title          : { Value : shelterName },
        Description    : { Value : city }
    },
    UI.SelectionFields : [ city, status ],
    UI.LineItem : [
        { Value : shelterName,      Label : 'Name' },
        { Value : city,             Label : 'City' },
        { Value : capacity,         Label : 'Capacity' },
        { Value : currentOccupancy, Label : 'Occupancy' },
        // progress bar of how full the shelter is
        { $Type : 'UI.DataFieldForAnnotation', Target : '@UI.DataPoint#Occupancy', Label : 'Full %' },
        { Value : status,           Label : 'Status' }
    ],
    UI.DataPoint #Occupancy : {
        Value         : occupancyPercentage,
        TargetValue   : 100,
        Visualization : #Progress
    },
    UI.Facets : [
        { $Type : 'UI.ReferenceFacet', ID : 'General', Label : 'General',             Target : '@UI.FieldGroup#General' },
        { $Type : 'UI.ReferenceFacet', ID : 'Address', Label : 'Address and Contact', Target : '@UI.FieldGroup#Address' },
        { $Type : 'UI.ReferenceFacet', ID : 'Animals', Label : 'Animals',             Target : 'animals/@UI.LineItem' }
    ],
    UI.FieldGroup #General : { Data : [
        { Value : shelterName }, { Value : shelterCode }, { Value : shelterType }, { Value : licenseNumber },
        { Value : capacity }, { Value : currentOccupancy }, { Value : occupancyPercentage },
        { Value : status }, { Value : operatingTime }, { Value : closingTime }
    ]},
    UI.FieldGroup #Address : { Data : [
        { Value : addressLine1 }, { Value : addressLine2 }, { Value : city }, { Value : state },
        { Value : postalCode }, { Value : country }, { Value : contactNumber }, { Value : email }, { Value : website }
    ]}
);
annotate service.Shelters with {
    shelterName         @title : 'Shelter Name';
    shelterCode         @title : 'Code';
    shelterType         @title : 'Type';
    licenseNumber       @title : 'License No.';
    capacity            @title : 'Capacity';
    currentOccupancy    @title : 'Current Occupancy';
    occupancyPercentage @title : 'Occupancy %';
    status              @title : 'Status';
    operatingTime       @title : 'Opens';
    closingTime         @title : 'Closes';
    addressLine1        @title : 'Address Line 1';
    addressLine2        @title : 'Address Line 2';
    city                @title : 'City';
    state               @title : 'State';
    postalCode          @title : 'Postal Code';
    country             @title : 'Country';
    contactNumber       @title : 'Phone';
    email               @title : 'Email';
    website             @title : 'Website';
};

// =====================================================================
// HEALTH RECORDS (with the Mark Recovered button)
// =====================================================================
annotate service.HealthRecords with @(
    UI.HeaderInfo : {
        TypeName       : 'Health Record',
        TypeNamePlural : 'Health Records',
        Title          : { Value : animal.name },
        Description    : { Value : checkupDate }
    },
    UI.SelectionFields : [ animal_ID, healthStatus, checkupDate, nextCheckupDate ],
    UI.LineItem : [
        // button in the table toolbar: select a row, then press it
        { $Type : 'UI.DataFieldForAction', Action : 'AdminService.markRecovered', Label : 'Mark Recovered' },
        { Value : animal.name,       Label : 'Animal' },
        { Value : checkupDate,       Label : 'Checkup Date' },
        { Value : healthStatus,      Label : 'Health' },
        { Value : vaccinationStatus, Label : 'Vaccination' },
        { Value : veterinarianName,  Label : 'Veterinarian' },
        { Value : nextCheckupDate,   Label : 'Next Checkup' }
    ],
    // the same button in the object page header
    UI.Identification : [
        { $Type : 'UI.DataFieldForAction', Action : 'AdminService.markRecovered', Label : 'Mark Recovered' }
    ],
    UI.Facets : [
        { $Type : 'UI.ReferenceFacet', ID : 'Checkup',   Label : 'Checkup',   Target : '@UI.FieldGroup#Checkup' },
        { $Type : 'UI.ReferenceFacet', ID : 'Treatment', Label : 'Treatment', Target : '@UI.FieldGroup#Treatment' }
    ],
    UI.FieldGroup #Checkup : { Data : [
        { Value : animal_ID, Label : 'Animal' }, { Value : checkupDate }, { Value : veterinarianName },
        { Value : healthStatus }, { Value : vaccinationStatus }, { Value : weight },
        { Value : adoptionEligible }, { Value : nextCheckupDate }
    ]},
    UI.FieldGroup #Treatment : { Data : [
        { Value : diagnosis }, { Value : treatment }, { Value : medication },
        { Value : healthSummary }, { Value : remarks }
    ]}
);
annotate service.HealthRecords with {
    checkupDate       @title : 'Checkup Date';
    healthStatus      @title : 'Health Status';
    vaccinationStatus @title : 'Vaccination';
    diagnosis         @title : 'Diagnosis';
    treatment         @title : 'Treatment';
    medication        @title : 'Medication';
    veterinarianName  @title : 'Veterinarian';
    weight            @title : 'Weight (kg)';
    healthSummary     @title : 'Summary';
    adoptionEligible  @title : 'Eligible for Adoption';
    nextCheckupDate   @title : 'Next Checkup';
    remarks           @title : 'Remarks';
    // animal picker (same idea as on the applications)
    animal @(
        Common.Label : 'Animal',
        Common.Text : animal.name,
        Common.TextArrangement : #TextOnly,
        Common.ValueList : {
            CollectionPath : 'Animals',
            Parameters : [
                { $Type : 'Common.ValueListParameterInOut',       LocalDataProperty : animal_ID, ValueListProperty : 'ID' },
                { $Type : 'Common.ValueListParameterDisplayOnly', ValueListProperty : 'animalID' },
                { $Type : 'Common.ValueListParameterDisplayOnly', ValueListProperty : 'name' },
                { $Type : 'Common.ValueListParameterDisplayOnly', ValueListProperty : 'species' }
            ]
        }
    );
};

// =====================================================================
// INSPECTIONS (setting the result to Validated completes the adoption)
// =====================================================================
annotate service.Inspections with @(
    UI.HeaderInfo : {
        TypeName       : 'Inspection',
        TypeNamePlural : 'Inspections',
        Title          : { Value : adoption.adoptionID },
        Description    : { Value : inspectionType }
    },
    UI.SelectionFields : [ result, inspectionType, inspectionDate ],
    UI.LineItem : [
        { Value : adoption.adoptionID,  Label : 'Adoption' },
        { Value : adoption.animal.name, Label : 'Animal' },
        { Value : inspectionDate,       Label : 'Date' },
        { Value : inspectionType,       Label : 'Type' },
        { Value : inspector.fullName,   Label : 'Inspector' },
        { Value : result,               Label : 'Result' }
    ],
    UI.Facets : [
        { $Type : 'UI.ReferenceFacet', ID : 'Inspection', Label : 'Inspection', Target : '@UI.FieldGroup#Inspection' },
        { $Type : 'UI.ReferenceFacet', ID : 'Findings',   Label : 'Findings',   Target : '@UI.FieldGroup#Findings' }
    ],
    UI.FieldGroup #Inspection : { Data : [
        { Value : adoption_ID,  Label : 'Adoption' },
        { Value : inspector_ID, Label : 'Inspector' },
        { Value : inspectionDate }, { Value : inspectionType }, { Value : result }
    ]},
    UI.FieldGroup #Findings : { Data : [
        { Value : animalCondition }, { Value : findings }, { Value : existingPetDetails }, { Value : remarks }
    ]}
);
annotate service.Inspections with {
    inspectionDate     @title : 'Inspection Date';
    inspectionType     @title : 'Type';
    result             @title : 'Result';
    animalCondition    @title : 'Animal Condition';
    findings           @title : 'Findings';
    existingPetDetails @title : 'Other Pets';
    remarks            @title : 'Remarks';
    adoption @(
        Common.Label : 'Adoption',
        Common.Text : adoption.adoptionID,
        Common.TextArrangement : #TextOnly,
        Common.ValueList : {
            CollectionPath : 'Adoptions',
            Parameters : [
                { $Type : 'Common.ValueListParameterInOut',       LocalDataProperty : adoption_ID, ValueListProperty : 'ID' },
                { $Type : 'Common.ValueListParameterDisplayOnly', ValueListProperty : 'adoptionID' },
                { $Type : 'Common.ValueListParameterDisplayOnly', ValueListProperty : 'adoptionDate' },
                { $Type : 'Common.ValueListParameterDisplayOnly', ValueListProperty : 'status' }
            ]
        }
    );
    inspector @(
        Common.Label : 'Inspector',
        Common.Text : inspector.fullName,
        Common.TextArrangement : #TextOnly,
        Common.ValueList : {
            CollectionPath : 'Users',
            Parameters : [
                { $Type : 'Common.ValueListParameterInOut',       LocalDataProperty : inspector_ID, ValueListProperty : 'ID' },
                { $Type : 'Common.ValueListParameterDisplayOnly', ValueListProperty : 'fullName' },
                { $Type : 'Common.ValueListParameterDisplayOnly', ValueListProperty : 'email' }
            ]
        }
    );
};
