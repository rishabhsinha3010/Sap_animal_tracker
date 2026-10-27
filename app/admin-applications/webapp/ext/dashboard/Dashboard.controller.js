// controller of the dashboard custom page
// PageController = the base class Fiori elements gives custom pages (it knows the app and its router)
sap.ui.define(["sap/fe/core/PageController"], function (PageController) {
    "use strict";

    return PageController.extend("adminapplications.ext.dashboard.Dashboard", {
        // a tile was pressed: open the route written in its app:route custom data (see the view)
        onOpen: function (oEvent) {
            const sRoute = oEvent.getSource().data("route");
            this.getAppComponent().getRouter().navTo(sRoute);
        }
    });
});
