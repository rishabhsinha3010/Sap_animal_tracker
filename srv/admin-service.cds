using { AnimalAdoption.db as db } from '../db/schema';

service AdminService @(path : '/admin', requires: 'Admin'){
    entity Shelters as projection on db.Shelters;
    entity Animals as projection on db.Animals;
    entity Users as projection on db.Users;
    entity AdoptionApplications as projection on db.AdoptionApplications;
    entity Adoptions as projection on db.Adoptions;
    entity HealthRecords as projection on db.HealthRecords;
    entity Inspections as projection on db.Inspections;
}