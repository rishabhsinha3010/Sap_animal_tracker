// Labels shared by both apps.
// They are put on the db entities, so every projection in AdminService and UserService inherits them
// (filters, forms and table headers use them when an annotation gives no Label of its own).
// App-specific screens (columns, sections, buttons) live in app/<app>/annotations/.
using {AnimalAdoption.db as db} from '../db/schema';

annotate db.Shelters with {
    shelterName         @title: 'Shelter Name';
    shelterCode         @title: 'Code';
    shelterType         @title: 'Type';
    licenseNumber       @title: 'License No.';
    capacity            @title: 'Capacity';
    currentOccupancy    @title: 'Current Occupancy';
    occupancyPercentage @title: 'Occupancy %';
    status              @title: 'Status';
    operatingTime       @title: 'Opens';
    closingTime         @title: 'Closes';
    addressLine1        @title: 'Address Line 1';
    addressLine2        @title: 'Address Line 2';
    city                @title: 'City';
    state               @title: 'State';
    postalCode          @title: 'Postal Code';
    country             @title: 'Country';
    contactNumber       @title: 'Phone';
    email               @title: 'Email';
    website             @title: 'Website';
    imageUrl            @title: 'Picture'  @UI.IsImageURL;
};

annotate db.Animals with {
    animalID          @title: 'Animal ID';
    shelter           @title: 'Shelter';
    name              @title: 'Name';
    species           @title: 'Species';
    breed             @title: 'Breed';
    gender            @title: 'Gender';
    age               @title: 'Age (years)';
    color             @title: 'Color';
    arrivalDate       @title: 'Arrival Date';
    healthStatus      @title: 'Health Status';
    vaccinationStatus @title: 'Vaccination';
    adoptionStatus    @title: 'Adoption Status';
    adoptionEligible  @title: 'Eligible for Adoption';
    adoptionFee       @title: 'Adoption Fee'  @Measures.ISOCurrency: 'INR';
    description       @title: 'Description'  @UI.MultiLineText;
    // show the value as a picture, not as text
    photo             @title: 'Photo Link (URL)';   // a text field to paste a link; photoUrl shows the picture
    image             @title: 'Upload Photo (JPG, PNG)';
    imageType         @UI.Hidden;
    imageName         @UI.Hidden;
    photoUrl          @title: 'Photo'  @UI.IsImageURL;
    // helper fields for the colours: never shown on their own
    healthCriticality   @UI.Hidden;
    adoptionCriticality @UI.Hidden;
};

annotate db.Users with {
    firstName   @title: 'First Name';
    lastName    @title: 'Last Name';
    fullName    @title: 'Name';
    email       @title: 'Email';
    phoneNumber @title: 'Phone';
    address     @title: 'Address';
    city        @title: 'City';
    state       @title: 'State';
    postalCode  @title: 'Postal Code';
    role        @title: 'Role';
    status      @title: 'Account Status';
};

annotate db.AdoptionApplications with {
    applicationID     @title: 'Application ID';
    animal            @title: 'Animal';
    applicant         @title: 'Applicant';
    applicationDate   @title: 'Application Date';
    reasonForAdoption @title: 'Reason for Adoption'  @UI.MultiLineText;
    housingType       @title: 'Housing Type';
    housingDetails    @title: 'Housing Details'  @UI.MultiLineText;
    hasOtherPets      @title: 'Other Pets at Home';
    petExperience     @title: 'Pet Experience'  @UI.MultiLineText;
    status            @title: 'Status';
    reviewedBy        @title: 'Reviewed By';
    reviewedAt        @title: 'Reviewed At';
    staffRemarks      @title: 'Staff Remarks';
    rejectionReason   @title: 'Rejection Reason';
    statusCriticality @UI.Hidden;
};

annotate db.ApplicationHistory with {
    oldStatus @title: 'From';
    newStatus @title: 'To';
    changedBy @title: 'Changed By';
    changedAt @title: 'When';
    remarks   @title: 'Remarks';
};

annotate db.Adoptions with {
    adoptionID   @title: 'Adoption ID';
    application  @title: 'Application';
    animal       @title: 'Animal';
    adoptionDate @title: 'Adoption Date';
    status       @title: 'Adoption Status';
    completedBy  @title: 'Completed By';
    remarks      @title: 'Remarks';
};

annotate db.HealthRecords with {
    animal            @title: 'Animal';
    checkupDate       @title: 'Checkup Date';
    healthStatus      @title: 'Health Status';
    vaccinationStatus @title: 'Vaccination';
    diagnosis         @title: 'Diagnosis';
    treatment         @title: 'Treatment';
    medication        @title: 'Medication';
    veterinarianName  @title: 'Veterinarian';
    weight            @title: 'Weight (kg)';
    healthSummary     @title: 'Summary';
    adoptionEligible  @title: 'Eligible for Adoption';
    nextCheckupDate   @title: 'Next Checkup';
    remarks           @title: 'Remarks';
    healthCriticality @UI.Hidden;
};

annotate db.Inspections with {
    adoption           @title: 'Adoption';
    inspector          @title: 'Inspector';
    inspectionDate     @title: 'Inspection Date';
    inspectionType     @title: 'Type';
    animalCondition    @title: 'Animal Condition'  @UI.MultiLineText;
    findings           @title: 'Findings'  @UI.MultiLineText;
    existingPetDetails @title: 'Other Pets'  @UI.MultiLineText;
    result             @title: 'Result';
    remarks            @title: 'Remarks'  @UI.MultiLineText;
    resultCriticality  @UI.Hidden;
};

// technical keys (UUIDs): never shown, e.g. as the first column of the Animal / Shelter / Adoption pickers
annotate db.Shelters             with { ID @UI.Hidden; };
annotate db.Animals              with { ID @UI.Hidden; };
annotate db.Users                with { ID @UI.Hidden; };
annotate db.AdoptionApplications with { ID @UI.Hidden; };
annotate db.Adoptions            with { ID @UI.Hidden; };

// every document table shows the same columns (all four document entities share the Attachment aspect)
annotate db.ApplicationDocuments with @(UI.LineItem: [
    {Value: fileName,     Label: 'File'},
    {Value: documentType, Label: 'Type'},
    {$Type: 'UI.DataFieldWithUrl', Value: url, Url: url, Label: 'Link'},
    {Value: note,         Label: 'Note'}
]);
annotate db.AdoptionDocuments with @(UI.LineItem: [
    {Value: fileName,     Label: 'File'},
    {Value: documentType, Label: 'Type'},
    {$Type: 'UI.DataFieldWithUrl', Value: url, Url: url, Label: 'Link'}
]);
annotate db.HealthDocuments with @(UI.LineItem: [
    {Value: fileName,     Label: 'File'},
    {Value: documentType, Label: 'Type'},
    {$Type: 'UI.DataFieldWithUrl', Value: url, Url: url, Label: 'Link'}
]);
annotate db.InspectionDocuments with @(UI.LineItem: [
    {Value: fileName,     Label: 'File'},
    {Value: documentType, Label: 'Type'},
    {$Type: 'UI.DataFieldWithUrl', Value: url, Url: url, Label: 'Link'}
]);

// ---------------------------------------------------------------------
// dropdowns for the fields with a fixed list of values (the enum types in db/common.cds).
// The values come from the CodeLists entity (db/schema.cds), filtered by the list name.
// ---------------------------------------------------------------------
annotate db.Animals with {
    gender @Common.ValueListWithFixedValues @Common.ValueList: {
        CollectionPath: 'CodeLists',
        Parameters    : [
            {$Type: 'Common.ValueListParameterConstant', ValueListProperty: 'list', Constant: 'Gender'},
            {$Type: 'Common.ValueListParameterInOut', LocalDataProperty: gender, ValueListProperty: 'code'}
        ]
    };
    healthStatus @Common.ValueListWithFixedValues @Common.ValueList: {
        CollectionPath: 'CodeLists',
        Parameters    : [
            {$Type: 'Common.ValueListParameterConstant', ValueListProperty: 'list', Constant: 'HealthStatus'},
            {$Type: 'Common.ValueListParameterInOut', LocalDataProperty: healthStatus, ValueListProperty: 'code'}
        ]
    };
    vaccinationStatus @Common.ValueListWithFixedValues @Common.ValueList: {
        CollectionPath: 'CodeLists',
        Parameters    : [
            {$Type: 'Common.ValueListParameterConstant', ValueListProperty: 'list', Constant: 'VaccinationStatus'},
            {$Type: 'Common.ValueListParameterInOut', LocalDataProperty: vaccinationStatus, ValueListProperty: 'code'}
        ]
    };
    adoptionStatus @Common.ValueListWithFixedValues @Common.ValueList: {
        CollectionPath: 'CodeLists',
        Parameters    : [
            {$Type: 'Common.ValueListParameterConstant', ValueListProperty: 'list', Constant: 'AdoptionStatus'},
            {$Type: 'Common.ValueListParameterInOut', LocalDataProperty: adoptionStatus, ValueListProperty: 'code'}
        ]
    };
};
annotate db.Shelters with {
    status @Common.ValueListWithFixedValues @Common.ValueList: {
        CollectionPath: 'CodeLists',
        Parameters    : [
            {$Type: 'Common.ValueListParameterConstant', ValueListProperty: 'list', Constant: 'ShelterStatus'},
            {$Type: 'Common.ValueListParameterInOut', LocalDataProperty: status, ValueListProperty: 'code'}
        ]
    };
};
annotate db.Users with {
    status @Common.ValueListWithFixedValues @Common.ValueList: {
        CollectionPath: 'CodeLists',
        Parameters    : [
            {$Type: 'Common.ValueListParameterConstant', ValueListProperty: 'list', Constant: 'AccountStatus'},
            {$Type: 'Common.ValueListParameterInOut', LocalDataProperty: status, ValueListProperty: 'code'}
        ]
    };
};
annotate db.AdoptionApplications with {
    status @Common.ValueListWithFixedValues @Common.ValueList: {
        CollectionPath: 'CodeLists',
        Parameters    : [
            {$Type: 'Common.ValueListParameterConstant', ValueListProperty: 'list', Constant: 'ApplicationStatus'},
            {$Type: 'Common.ValueListParameterInOut', LocalDataProperty: status, ValueListProperty: 'code'}
        ]
    };
    housingType @Common.ValueListWithFixedValues @Common.ValueList: {
        CollectionPath: 'CodeLists',
        Parameters    : [
            {$Type: 'Common.ValueListParameterConstant', ValueListProperty: 'list', Constant: 'HousingType'},
            {$Type: 'Common.ValueListParameterInOut', LocalDataProperty: housingType, ValueListProperty: 'code'}
        ]
    };
};
annotate db.Adoptions with {
    status @Common.ValueListWithFixedValues @Common.ValueList: {
        CollectionPath: 'CodeLists',
        Parameters    : [
            {$Type: 'Common.ValueListParameterConstant', ValueListProperty: 'list', Constant: 'AdoptionRecordStatus'},
            {$Type: 'Common.ValueListParameterInOut', LocalDataProperty: status, ValueListProperty: 'code'}
        ]
    };
};
annotate db.HealthRecords with {
    healthStatus @Common.ValueListWithFixedValues @Common.ValueList: {
        CollectionPath: 'CodeLists',
        Parameters    : [
            {$Type: 'Common.ValueListParameterConstant', ValueListProperty: 'list', Constant: 'HealthStatus'},
            {$Type: 'Common.ValueListParameterInOut', LocalDataProperty: healthStatus, ValueListProperty: 'code'}
        ]
    };
    vaccinationStatus @Common.ValueListWithFixedValues @Common.ValueList: {
        CollectionPath: 'CodeLists',
        Parameters    : [
            {$Type: 'Common.ValueListParameterConstant', ValueListProperty: 'list', Constant: 'VaccinationStatus'},
            {$Type: 'Common.ValueListParameterInOut', LocalDataProperty: vaccinationStatus, ValueListProperty: 'code'}
        ]
    };
};
annotate db.Inspections with {
    inspectionType @Common.ValueListWithFixedValues @Common.ValueList: {
        CollectionPath: 'CodeLists',
        Parameters    : [
            {$Type: 'Common.ValueListParameterConstant', ValueListProperty: 'list', Constant: 'InspectionType'},
            {$Type: 'Common.ValueListParameterInOut', LocalDataProperty: inspectionType, ValueListProperty: 'code'}
        ]
    };
    result @Common.ValueListWithFixedValues @Common.ValueList: {
        CollectionPath: 'CodeLists',
        Parameters    : [
            {$Type: 'Common.ValueListParameterConstant', ValueListProperty: 'list', Constant: 'InspectionResult'},
            {$Type: 'Common.ValueListParameterInOut', LocalDataProperty: result, ValueListProperty: 'code'}
        ]
    };
};
annotate db.CodeLists with {
    code @title: 'Value';
    list @UI.Hidden;
    sortOrder @UI.Hidden;
};
