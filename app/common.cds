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
    photo             @title: 'Photo'  @UI.IsImageURL;
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

