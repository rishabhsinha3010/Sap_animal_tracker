// Builds the CSV files in db/data (the data deployed to HANA) from the animal photos.
// The photo URLs come from images/cloudinary-urls.json (written by scripts/upload-images.js).
//
// Run from the project root:   node scripts/gen-data.js
//
// Why a script instead of typing the CSVs by hand: the counts must match each other
// (shelter occupancy = animals in the shelter that are not adopted, every application has
// history rows, ...). Generating them keeps that consistent when you add or change an animal.
const fs = require('fs');
const path = require('path');

const ROOT = path.join(__dirname, '..');
const OUT = path.join(ROOT, 'db', 'data');
const urls = JSON.parse(fs.readFileSync(path.join(ROOT, 'images', 'cloudinary-urls.json'), 'utf8'));
const photo = file => {
    const u = urls[`animals/${file}`];
    if (!u) throw new Error(`No Cloudinary URL for images/animals/${file}. Run scripts/upload-images.js first.`);
    return u.url;
};

// ---------- CSV helpers ----------
// a value with a comma, quote or line break must be wrapped in "..." (and " doubled)
const q = v => {
    if (v === null || v === undefined) return '';
    const s = String(v);
    return /[",\n]/.test(s) ? '"' + s.replace(/"/g, '""') + '"' : s;
};
const write = (name, rows) => {
    // columns = every key used by any row, so optional fields can be left out of a row
    const cols = [...new Set(rows.flatMap(r => Object.keys(r)))];
    const text = [cols.join(','), ...rows.map(r => cols.map(c => q(r[c])).join(','))].join('\n') + '\n';
    fs.writeFileSync(path.join(OUT, `AnimalAdoption.db-${name}.csv`), text, 'utf8');
    console.log(`${String(rows.length).padStart(3)} rows  AnimalAdoption.db-${name}.csv`);
};
// readable fixed UUIDs, e.g. uuid('a', 3) -> aaaaaaaa-0000-0000-0000-000000000003
const uuid = (c, n) => `${c.repeat(8)}-0000-0000-0000-${String(n).padStart(12, '0')}`;

// ---------- Shelters (split by animal type) ----------
const S = { pets: uuid('1', 1), small: uuid('1', 2), farm: uuid('1', 3) };
const shelters = [
    { ID: S.pets, shelterName: 'Happy Paws Shelter', shelterCode: 'SHL-HYD', addressLine1: '12 Jubilee Hills Road', city: 'Hyderabad', state: 'Telangana', postalCode: '500033', country: 'India', contactNumber: '+91 40 2355 0101', email: 'contact@happypaws.example', website: 'https://happypaws.example', licenseNumber: 'TS-AWB-2019-114', shelterType: 'Dogs and Cats', operatingTime: '09:00:00', closingTime: '18:00:00', capacity: 40, status: 'Active' },
    { ID: S.small, shelterName: 'City Care Small Pets', shelterCode: 'SHL-PNE', addressLine1: '4 FC Road', city: 'Pune', state: 'Maharashtra', postalCode: '411004', country: 'India', contactNumber: '+91 20 2565 0202', email: 'hello@citycare.example', website: 'https://citycare.example', licenseNumber: 'MH-AWB-2020-087', shelterType: 'Small animals and birds', operatingTime: '10:00:00', closingTime: '17:00:00', capacity: 25, status: 'Active' },
    { ID: S.farm, shelterName: 'Green Tails Farm Rescue', shelterCode: 'SHL-BLR', addressLine1: 'Survey No. 88, Hesaraghatta Road', city: 'Bengaluru', state: 'Karnataka', postalCode: '560089', country: 'India', contactNumber: '+91 80 4123 0303', email: 'rescue@greentails.example', website: 'https://greentails.example', licenseNumber: 'KA-AWB-2018-042', shelterType: 'Farm animals and reptiles', operatingTime: '08:00:00', closingTime: '16:00:00', capacity: 10, status: 'Active' },
];

// ---------- Animals (one per photo; the file name gives species and breed) ----------
// [key, photo file, shelter, name, species, breed, gender, age, color, arrival, health, vaccination, status, fee, description]
const A = {};
const animalRows = [
    ['bruno',   'Dog_Labrador_Retriever',       S.pets,  'Bruno',    'Dog',        'Labrador Retriever',       'Male',    3, 'Yellow',        '2026-08-20', 'Healthy', 'Vaccinated',           'Available',       1500, 'Friendly and playful, loves fetch and long walks.'],
    ['goldie',  'Dog_Golden_Retriever',         S.pets,  'Goldie',   'Dog',        'Golden Retriever',         'Female',  4, 'Golden',        '2026-07-02', 'Healthy', 'Vaccinated',           'Adopted',         1800, 'Gentle family dog, great with children.'],
    ['max',     'Dog_German_Shepherd',          S.pets,  'Max',      'Dog',        'German Shepherd',          'Male',    2, 'Black and tan', '2026-09-25', 'Healthy', 'Vaccinated',           'Available',       2500, 'Smart and energetic, needs an active home.'],
    ['rocky',   'Dog_Beagle',                   S.pets,  'Rocky',    'Dog',        'Beagle',                   'Male',    4, 'Tricolour',     '2026-10-10', 'Sick',    'Not Vaccinated',       'Under Treatment',    0, 'Recovering from a skin infection, very gentle.'],
    ['misty',   'Cat_Persian',                  S.pets,  'Misty',    'Cat',        'Persian',                  'Female',  2, 'White',         '2026-09-02', 'Healthy', 'Vaccinated',           'Available',       1000, 'Calm indoor cat who enjoys sunny windows.'],
    ['simba',   'Cat_Indian_Domestic_Shorthair', S.pets, 'Simba',    'Cat',        'Indian Domestic Shorthair','Male',    1, 'Orange tabby',  '2026-10-01', 'Healthy', 'Partially Vaccinated', 'Available',        500, 'Curious young cat, litter trained.'],
    ['coco',    'Rabbit_Holland_Lop',           S.small, 'Coco',     'Rabbit',     'Holland Lop',              'Female',  1, 'Brown',         '2026-09-15', 'Healthy', 'Partially Vaccinated', 'Available',        500, 'Floppy-eared bunny who loves carrots.'],
    ['snowball','Rabbit_New_Zealand_White',     S.small, 'Snowball', 'Rabbit',     'New Zealand White',        'Male',    2, 'White',         '2026-08-30', 'Healthy', 'Vaccinated',           'Available',        600, 'Calm and easy to handle.'],
    ['peanut',  'Guinea_Pig_American',          S.small, 'Peanut',   'Guinea Pig', 'American',                 'Male',    1, 'Brown and white','2026-09-20','Healthy', 'Not Vaccinated',       'Available',        300, 'Squeaks happily at feeding time.'],
    ['nibbles', 'Hamster_Syrian',               S.small, 'Nibbles',  'Hamster',    'Syrian',                   'Female',  1, 'Golden',        '2026-10-05', 'Healthy', 'Not Vaccinated',       'Available',        200, 'Night owl, loves her running wheel.'],
    ['kiwi',    'Parrot_Budgerigar',            S.small, 'Kiwi',     'Bird',       'Budgerigar',               'Unknown', 1, 'Green',         '2026-08-28', 'Healthy', 'Not Vaccinated',       'Available',        300, 'Chirpy budgie who knows a few whistles.'],
    ['sunny',   'Parrot_Cockatiel',             S.small, 'Sunny',    'Bird',       'Cockatiel',                'Male',    2, 'Grey and yellow','2026-09-08','Healthy', 'Not Vaccinated',       'Available',        800, 'Sings in the morning, likes head scratches.'],
    ['snowy',   'Pigeon_Fantail',               S.small, 'Snowy',    'Bird',       'Fantail Pigeon',           'Female',  1, 'White',         '2026-10-12', 'Injured', 'Not Vaccinated',       'Under Treatment',    0, 'Healing from a wing injury.'],
    ['gauri',   'Cow_Gir',                      S.farm,  'Gauri',    'Cow',        'Gir',                      'Female',  5, 'Red and white', '2026-06-15', 'Healthy', 'Vaccinated',           'Available',       5000, 'Gentle Gir cow, needs a farm with open space.'],
    ['sultan',  'Horse_Marwari',                S.farm,  'Sultan',   'Horse',      'Marwari',                  'Male',    6, 'Bay',           '2026-07-20', 'Healthy', 'Vaccinated',           'Available',       8000, 'Proud Marwari with curved ears, trained for riding.'],
    ['daisy',   'Duck_Pekin',                   S.farm,  'Daisy',    'Duck',       'Pekin',                    'Female',  1, 'White',         '2026-06-30', 'Healthy', 'Vaccinated',           'Adopted',          400, 'Friendly duck who loves the pond.'],
    ['shelly',  'Turtle_Red_Eared_Slider',      S.farm,  'Shelly',   'Turtle',     'Red-Eared Slider',         'Unknown', 4, 'Green',         '2026-09-01', 'Healthy', 'Not Vaccinated',       'Available',        250, 'Slow and steady, needs a tank with a basking spot.'],
];
const animals = animalRows.map(([key, file, shelter, name, species, breed, gender, age, color, arrival, health, vacc, status, fee, desc], i) => {
    A[key] = uuid('a', i + 1);
    return { ID: A[key], animalID: 'ANM-' + String(i + 1).padStart(4, '0'), shelter_ID: shelter, name, species, breed, gender, age, color,
             arrivalDate: arrival, healthStatus: health, vaccinationStatus: vacc, adoptionStatus: status,
             adoptionEligible: health === 'Healthy', adoptionFee: fee, photo: photo(file), description: desc };
});

// occupancy = animals in the shelter that are not adopted (same rule as refreshShelter in admin-service.js)
for (const s of shelters) {
    s.currentOccupancy = animals.filter(a => a.shelter_ID === s.ID && a.adoptionStatus !== 'Adopted').length;
}

// ---------- Users (the logins in package.json; on BTP the email must match the login) ----------
const U = { admin: uuid('9', 1), asha: uuid('9', 2), vikram: uuid('9', 3), meera: uuid('9', 4) };
const users = [
    { ID: U.admin,  firstName: 'Ravi',   lastName: 'Kumar', email: 'admin@example.com',  phoneNumber: '+91 98480 00001', city: 'Hyderabad', state: 'Telangana',   role: 'Admin', status: 'Active' },
    { ID: U.asha,   firstName: 'Asha',   lastName: 'Reddy', email: 'asha@example.com',   phoneNumber: '+91 98480 00002', address: '7 Banjara Hills', city: 'Hyderabad', state: 'Telangana',   postalCode: '500034', role: 'User', status: 'Active' },
    { ID: U.vikram, firstName: 'Vikram', lastName: 'Singh', email: 'vikram@example.com', phoneNumber: '+91 98480 00003', address: '21 Koramangala',  city: 'Bengaluru', state: 'Karnataka',   postalCode: '560034', role: 'User', status: 'Active' },
    { ID: U.meera,  firstName: 'Meera',  lastName: 'Nair',  email: 'meera@example.com',  phoneNumber: '+91 98480 00004', address: '3 Kalyani Nagar', city: 'Pune',      state: 'Maharashtra', postalCode: '411006', role: 'User', status: 'Active' },
];

// ---------- Applications (every status once or more) + their history ----------
const P = {};
const apps = [];
const history = [];
let h = 0;
const hist = (app, oldStatus, newStatus, by, at, remarks) =>
    history.push({ ID: uuid('e', ++h), application_ID: app, oldStatus, newStatus, changedBy: by, changedAt: at, remarks });

// [key, animal, applicant, date, reason, housing, otherPets, experience, status, reviewedAt, staffRemarks, rejectionReason]
const appRows = [
    ['a1', 'bruno', 'asha',   '2026-10-01', 'I have a house with a garden',       'Independent House', false, 'Grew up with dogs',              'Submitted'],
    ['a2', 'max',   'vikram', '2026-10-03', 'Looking for a running partner',      'Independent House', false, 'Owned a German Shepherd before', 'Under Review', '2026-10-05T10:00:00Z', 'Home visit to be scheduled'],
    ['a3', 'goldie','asha',   '2026-09-05', 'Want a gentle dog for my family',    'Independent House', false, 'Had a Labrador for 8 years',     'Approved',     '2026-09-14T11:30:00Z', 'Great match'],
    ['a4', 'kiwi',  'asha',   '2026-09-20', 'My kids love birds',                 'Apartment',         true,  'No bird experience',             'Rejected',     '2026-09-24T09:15:00Z', null, 'Existing cat at home is a risk for the bird'],
    ['a5', 'simba', 'meera',  '2026-10-05', 'Company for my mother',              'Apartment',         false, 'Had cats for 10 years',          'Withdrawn'],
    ['a6', 'misty', 'meera',  '2026-10-12', 'Quiet home, I work from home',       'Apartment',         false, 'Fostered cats',                  'Submitted'],
    ['a7', 'daisy', 'vikram', '2026-08-02', 'We have a farm pond and other ducks', 'Farm',             true,  'Keeps poultry',                  'Approved',     '2026-08-09T09:00:00Z', 'Farm checked by phone'],
];
appRows.forEach(([key, animal, applicant, date, reason, housing, otherPets, exp, status, reviewedAt, remarks, rejection], i) => {
    P[key] = uuid('d', i + 1);
    const who = users.find(u => u.ID === U[applicant]).email;
    apps.push({ ID: P[key], applicationID: 'APP-' + String(i + 1).padStart(4, '0'), animal_ID: A[animal], applicant_ID: U[applicant],
                applicationDate: date, reasonForAdoption: reason, housingType: housing, hasOtherPets: otherPets, petExperience: exp,
                status, reviewedBy: reviewedAt ? 'admin' : null, reviewedAt, staffRemarks: remarks, rejectionReason: rejection });
    // history: Submitted first, then the steps that lead to the current status
    hist(P[key], null, 'Submitted', who, `${date}T08:00:00Z`);
    if (status === 'Withdrawn') hist(P[key], 'Submitted', 'Withdrawn', who, `${date}T18:00:00Z`);
    if (['Under Review', 'Approved', 'Rejected'].includes(status)) {
        hist(P[key], 'Submitted', 'Under Review', 'admin', status === 'Under Review' ? reviewedAt : `${date}T12:00:00Z`);
    }
    if (status === 'Approved' || status === 'Rejected') hist(P[key], 'Under Review', status, 'admin', reviewedAt, remarks || rejection);
});

// ---------- Adoptions (one per approved application) + inspections ----------
const adoptions = [
    { ID: uuid('f', 1), adoptionID: 'ADP-0001', application_ID: P.a7, animal_ID: A.daisy,  adoptionDate: '2026-08-10', status: 'Completed', completedBy: 'admin', remarks: 'Settled in with the other ducks' },
    { ID: uuid('f', 2), adoptionID: 'ADP-0002', application_ID: P.a3, animal_ID: A.goldie, adoptionDate: '2026-09-15', status: 'Active', remarks: 'Picked up by adopter' },
];
const inspections = [
    { ID: uuid('c', 1), adoption_ID: adoptions[0].ID, inspector_ID: U.admin, inspectionDate: '2026-09-10', inspectionType: 'Initial',
      animalCondition: 'Healthy and active', findings: 'Clean pond, safe night shelter', existingPetDetails: '4 ducks, 6 hens', result: 'Validated', remarks: 'All good' },
    { ID: uuid('c', 2), adoption_ID: adoptions[1].ID, inspector_ID: U.admin, inspectionDate: '2026-10-15', inspectionType: 'Initial',
      animalCondition: 'Healthy, settled in well', findings: 'Fenced garden, dog bed and bowls present', result: 'Pending', remarks: 'Waiting for the final sign-off' },
];

// ---------- Health records (one per animal; the newest one matches the animal's health fields) ----------
const vets = ['Dr. Mehta', 'Dr. Rao', 'Dr. Iyer'];
const healthRecords = [];
let r = 0;
animals.forEach((a, i) => {
    // Rocky also gets an older record, so the history of a sick animal shows two checkups
    if (a.name === 'Rocky') {
        healthRecords.push({ ID: uuid('b', ++r), animal_ID: a.ID, checkupDate: '2026-10-01', healthStatus: 'Injured', vaccinationStatus: 'Not Vaccinated',
            diagnosis: 'Paw wound', treatment: 'Cleaned and bandaged', medication: 'Antiseptic', veterinarianName: 'Dr. Rao', weight: 11.0,
            healthSummary: 'Minor injury', adoptionEligible: false, nextCheckupDate: '2026-10-08' });
    }
    const sick = a.healthStatus !== 'Healthy';
    healthRecords.push({ ID: uuid('b', ++r), animal_ID: a.ID,
        checkupDate: sick ? '2026-10-14' : a.arrivalDate, healthStatus: a.healthStatus, vaccinationStatus: a.vaccinationStatus,
        diagnosis: a.name === 'Rocky' ? 'Skin infection' : a.name === 'Snowy' ? 'Wing fracture' : null,
        treatment: a.name === 'Rocky' ? 'Medicated baths' : a.name === 'Snowy' ? 'Wing splint, cage rest' : null,
        medication: sick ? 'Antibiotics' : null,
        veterinarianName: vets[i % vets.length],
        healthSummary: sick ? 'Under treatment' : 'Fit for adoption',
        adoptionEligible: !sick,
        // sick animals are checked again soon (Rocky's date has passed -> shows as overdue on the dashboard)
        nextCheckupDate: a.name === 'Rocky' ? '2026-10-20' : sick ? '2026-11-01' : '2027-03-01' });
});

fs.mkdirSync(OUT, { recursive: true });
write('Shelters', shelters);
write('Animals', animals);
write('Users', users);
write('AdoptionApplications', apps);
write('ApplicationHistory', history);
write('Adoptions', adoptions);
write('Inspections', inspections);
write('HealthRecords', healthRecords);
console.log('\noccupancy:', shelters.map(s => `${s.shelterName} ${s.currentOccupancy}/${s.capacity}`).join(', '));
