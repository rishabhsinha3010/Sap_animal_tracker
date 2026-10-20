using { AnimalAdoption.db as db } from '../db/schema';

service UserService @(path: '/user', requires: 'authenticated-user') {
    entity Shelters as projection on db.Shelters;
    entity Animals as projection on db.Animals;
    entity Users as projection on db.Users;
    entity AdoptionApplications as projection on db.AdoptionApplications;
    entity Adoptions as projection on db.Adoptions;
}

 