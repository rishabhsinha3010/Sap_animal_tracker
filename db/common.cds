// Common reusable aspects for the Animal Tracker domain
using { cuid, managed } from '@sap/cds/common';

// A reusable "Base" aspect that adds ID + audit fields to any entity
aspect Base : cuid, managed {}
