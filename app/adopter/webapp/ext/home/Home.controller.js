// controller of the adopter start page
// PageController = the base class Fiori elements gives custom pages (router, editFlow, routing helpers)
sap.ui.define(["sap/fe/core/PageController"], function (PageController) {
    "use strict";

    return PageController.extend("adopter.ext.home.Home", {
        onBrowse: function () {
            this.getAppComponent().getRouter().navTo("AnimalsList");
        },

        onApplications: function () {
            this.getAppComponent().getRouter().navTo("AdoptionApplicationsList");
        },

        // My Profile: the server only returns MY row (the @restrict rule email = $user),
        // so: one row -> open it, no row -> start a new one (registration form)
        onProfile: async function () {
            const oModel = this.getView().getModel();
            // IsActiveEntity eq true = only the saved profile, not an unsaved draft copy
            const oList = oModel.bindList("/Users", undefined, undefined, undefined, { $filter: "IsActiveEntity eq true" });
            const aContexts = await oList.requestContexts(0, 1);
            if (aContexts.length) {
                this.routing.navigateToContext(aContexts[0]);
            } else {
                // creates a draft and opens it as an empty form; Save runs the registration checks
                this.editFlow.createDocument("/Users", { creationMode: "NewPage" });
            }
        }
    });
});
