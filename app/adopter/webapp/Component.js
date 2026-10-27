sap.ui.define([
    "sap/fe/core/AppComponent",
    "animaladoption/shared/AppShell"
], function (AppComponent, AppShell) {
    "use strict";

    return AppComponent.extend("animaladoption.adopter.Component", {
        metadata: {
            manifest: "json"
        },

        init: function () {
            AppComponent.prototype.init.apply(this, arguments);
            // top bar with the account menu (app/shared/AppShell.js)
            AppShell.create(this, { title: "Animal Adoption", homeRoute: "Home", profile: true });
        }
    });
});
