// Starts the app router on your machine / in BAS (http://localhost:5000) in front of `cds watch`.
// The XSUAA credentials come from `cds bind --exec` (see the router:hybrid script in the root package.json);
// this file only adds the destination to the local CAP server, which on Cloud Foundry comes from mta.yaml.
process.env.destinations ??= JSON.stringify([
    { name: 'srv-api', url: 'http://localhost:4004', forwardAuthToken: true }
]);
process.env.PORT ??= '5000';
require('@sap/approuter')().start({ workingDir: __dirname });
