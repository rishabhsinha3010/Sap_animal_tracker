// controller of the adopter start page
// PageController = the base class Fiori elements gives custom pages (router, editFlow, routing helpers)
sap.ui.define([
    "sap/fe/core/PageController",
    "sap/ui/model/json/JSONModel",
    "sap/ui/core/format/NumberFormat",
    "sap/base/Log"
], function (PageController, JSONModel, NumberFormat, Log) {
    "use strict";

    const STATUS_STATE = { "Submitted": "Information", "Under Review": "Warning", "Approved": "Success", "Rejected": "Error", "Withdrawn": "None" };
    // the adoption fees are in Indian rupees (the sample shelters are in India)
    const oFee = NumberFormat.getIntegerInstance({ groupingEnabled: true });

    return PageController.extend("animaladoption.adopter.ext.home.Home", {
        onInit: function () {
            PageController.prototype.onInit.apply(this, arguments);
            this.getView().setModel(new JSONModel({ busy: true, isAdopter: true, hasProfile: true, greeting: "", applications: [], animals: [] }), "home");
            // reload every time the page is shown, so new applications appear after Apply
            this.getAppComponent().getRouter().getRoute("Home").attachPatternMatched(this._load, this);
            // "My Profile" in the top bar (app/shared/AppShell.js) is handled here, where the edit flow is
            const oComponent = this.getAppComponent();
            oComponent._homeReady = true;
            oComponent.getEventBus().subscribe("animaladoption", "openProfile", this.onProfile, this);
        },

        onBrowse: function () {
            this.getAppComponent().getRouter().navTo("AnimalsList");
        },

        onApplications: function () {
            this.getAppComponent().getRouter().navTo("AdoptionApplicationsList");
        },

        onOpenAnimal: function (oEvent) {
            const oAnimal = oEvent.getSource().getBindingContext("home").getObject();
            this.getAppComponent().getRouter().navTo("AnimalsObjectPage", { key: oAnimal.ID });
        },

        onOpenApplication: function (oEvent) {
            const oApplication = oEvent.getSource().getBindingContext("home").getObject();
            this.getAppComponent().getRouter().navTo("AdoptionApplicationsObjectPage", { key: oApplication.ID });
        },

        // My Profile: the server only returns MY row (the @restrict rule email = $user),
        // so: one row -> open it, no row -> start a new one (registration form)
        onProfile: async function () {
            const oModel = this.getView().getModel();
            // IsActiveEntity eq true = only the saved profile, not an unsaved draft copy
            const oList = oModel.bindList("/Users", undefined, undefined, undefined, { $filter: "IsActiveEntity eq true", $select: "ID" });
            const aContexts = await oList.requestContexts(0, 1);
            if (aContexts.length) {
                const sID = aContexts[0].getProperty("ID");
                this.getAppComponent().getRouter().navTo("UsersObjectPage", { key: `ID=${sID},IsActiveEntity=true` });
            } else {
                // creates a draft and opens it as an empty form; Save runs the registration checks
                this.editFlow.createDocument("/Users", { creationMode: "NewPage" });
            }
        },

        // reads rows from the OData service (/user) as plain objects.
        // $direct = its own HTTP request, not part of a $batch: in a batch, one failed read (e.g. 403 on
        // /Users for a login without the User role) cancels all the reads after it.
        // A failed read gives null, so the caller can tell "failed" from "no rows".
        _rows: async function (sPath, mParameters, iMax) {
            const oModel = this.getAppComponent().getModel();
            try {
                const oList = oModel.bindList(sPath, undefined, undefined, undefined, { ...mParameters, $$groupId: "$direct" });
                const aContexts = await oList.requestContexts(0, iMax);
                return aContexts.map((oContext) => oContext.getObject());
            } catch (e) {
                Log.error(`Home page: reading ${sPath} failed`, e);
                return null;
            }
        },

        _load: async function () {
            // the top bar asked for My Profile before this page existed
            const oComponent = this.getAppComponent();
            if (oComponent._openProfileOnHome) {
                oComponent._openProfileOnHome = false;
                // one tick later: the page's edit flow is ready only after it has been displayed
                setTimeout(() => this.onProfile(), 0);
            }
            const oHome = this.getView().getModel("home");
            const oBundle = this.getAppComponent().getModel("i18n").getResourceBundle();
            oHome.setProperty("/busy", true);
            try {
                const [aProfile, aApplications, aAnimals] = await Promise.all([
                    this._rows("/Users", { $select: "ID,firstName", $filter: "IsActiveEntity eq true" }, 1),
                    this._rows("/AdoptionApplications", {
                        $select: "ID,applicationID,applicationDate,status",
                        $expand: "animal($select=ID,name,photo)",
                        $orderby: "applicationDate desc"
                    }, 3),
                    this._rows("/Animals", {
                        $select: "ID,name,breed,gender,age,photo,adoptionFee",
                        $expand: "shelter($select=ID,shelterName,city)",
                        $filter: "adoptionStatus eq 'Available'",
                        $orderby: "name"
                    }, 12)
                ]);

                // the profile read fails (403) when the login has no User role, e.g. admin
                oHome.setProperty("/isAdopter", aProfile !== null);
                const oProfile = (aProfile || [])[0];
                oHome.setProperty("/hasProfile", !!oProfile);
                oHome.setProperty("/greeting", oProfile
                    ? oBundle.getText("greetingNamed", [oProfile.firstName])
                    : oBundle.getText("greeting"));
                oHome.setProperty("/applications", (aApplications || []).map((a) => ({
                    ID: a.ID,
                    applicationID: a.applicationID,
                    applicationDate: a.applicationDate,
                    status: a.status,
                    state: STATUS_STATE[a.status] || "None",
                    animalName: a.animal ? a.animal.name : "",
                    photo: (a.animal && a.animal.photo) || "sap-icon://heart"
                })));
                oHome.setProperty("/animals", (aAnimals || []).map((a) => ({
                    ID: a.ID,
                    name: a.name,
                    breed: a.breed,
                    gender: a.gender,
                    photo: a.photo,
                    ageText: oBundle.getText(a.age === 1 ? "ageYear" : "ageYears", [a.age]),
                    fee: Number(a.adoptionFee) ? "₹ " + oFee.format(Number(a.adoptionFee)) : oBundle.getText("free"),
                    shelter: a.shelter ? `${a.shelter.shelterName}, ${a.shelter.city}` : ""
                })));
            } finally {
                oHome.setProperty("/busy", false);
            }
        }
    });
});
