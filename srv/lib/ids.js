// shared helpers used by both services (admin-service.js and user-service.js)
const cds = require('@sap/cds');
// take SELECT from cds.ql instead of the global one: the Fiori UI plugin loads a second copy
// of @sap/cds, and then the global SELECT belongs to the wrong copy
const { SELECT } = cds.ql;

// next number for a code like ANM-0001: takes the highest existing one and adds 1.
// (counting rows would repeat a number after a delete, the highest number never does)
// works for every prefix because all codes have the same length (4 digits after the prefix)
async function nextId(table, column, prefix) {
    const row = await SELECT.one.from(table).columns(`max(${column}) as last`);
    const lastNo = row?.last ? parseInt(row.last.slice(prefix.length), 10) : 0;
    return prefix + String(lastNo + 1).padStart(4, '0');
}

module.exports = { nextId };
