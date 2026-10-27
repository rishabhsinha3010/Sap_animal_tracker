// controller of the dashboard custom page
// PageController = the base class Fiori elements gives custom pages (it knows the app and its router)
sap.ui.define([
    "sap/fe/core/PageController",
    "sap/ui/model/json/JSONModel"
], function (PageController, JSONModel) {
    "use strict";

    // every application status, so a status without applications still shows up as 0 in the bar chart
    const STATUSES = [
        { status: "Submitted",    color: "Neutral",  state: "None" },
        { status: "Under Review", color: "Critical", state: "Warning" },
        { status: "Approved",     color: "Good",     state: "Success" },
        { status: "Rejected",     color: "Error",    state: "Error" },
        { status: "Withdrawn",    color: "Neutral",  state: "None" }
    ];
    const MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

    return PageController.extend("animaladoption.admin.ext.dashboard.Dashboard", {
        onInit: function () {
            PageController.prototype.onInit.apply(this, arguments);
            this.getView().setModel(new JSONModel({ busy: true, kpi: {}, statuses: [], trend: [], shelters: [], pending: [], overdue: [] }), "dash");
            // reload every time the dashboard is shown (also when coming back from a list or object page)
            this.getAppComponent().getRouter().getRoute("Dashboard").attachPatternMatched(this._load, this);
        },

        onRefresh: function () {
            this._load();
        },

        // a button or card header was pressed: open the route written in its app:route custom data
        onOpen: function (oEvent) {
            this._navTo(oEvent.getSource().data("route"));
        },

        // a bar was pressed: open the applications list
        onStatusSelected: function () {
            this._navTo("AdoptionApplicationsList");
        },

        onOpenApplication: function (oEvent) {
            const oItem = oEvent.getSource().getBindingContext("dash").getObject();
            this._navTo("AdoptionApplicationsObjectPage", { key: oItem.ID });
        },

        // health records use draft, so the key also names the saved (active) version
        onOpenCheckup: function (oEvent) {
            const oItem = oEvent.getSource().getBindingContext("dash").getObject();
            this._navTo("HealthRecordsObjectPage", { key: `ID=${oItem.ID},IsActiveEntity=true` });
        },

        _navTo: function (sRoute, oParams) {
            this.getAppComponent().getRouter().navTo(sRoute, oParams || {});
        },

        // reads rows from the OData service (/admin) as plain objects
        _rows: async function (sPath, mParameters, iMax) {
            const oModel = this.getAppComponent().getModel();
            const aContexts = await oModel.bindList(sPath, undefined, undefined, undefined, mParameters).requestContexts(0, iMax || 100);
            return aContexts.map((oContext) => oContext.getObject());
        },

        _load: async function () {
            const oDash = this.getView().getModel("dash");
            const oModel = this.getAppComponent().getModel();
            oDash.setProperty("/busy", true);
            try {
                const [oKpi, aStatuses, aTrend, aShelters, aPending, aOverdue] = await Promise.all([
                    oModel.bindContext("/AnimalSummary(1)").requestObject(),
                    this._rows("/ApplicationsByStatus", { $select: "status,total" }),
                    this._rows("/AdoptionTrend", { $select: "year,month,total" }),
                    this._rows("/ShelterOccupancy", { $select: "ID,shelterName,city,currentOccupancy,capacity,occupancyPercentage", $orderby: "shelterName" }),
                    this._rows("/AdoptionApplications", {
                        $select: "ID,applicationID,status,applicationDate",
                        $expand: "animal($select=ID,name),applicant($select=ID,fullName)",
                        $filter: "status eq 'Submitted' or status eq 'Under Review'",
                        $orderby: "applicationDate"
                    }, 6),
                    this._rows("/OverdueCheckups", { $select: "ID,nextCheckupDate,healthStatus", $expand: "animal($select=ID,name)", $orderby: "nextCheckupDate" }, 6)
                ]);

                oDash.setProperty("/kpi", oKpi || {});
                oDash.setProperty("/statuses", STATUSES.map((s) => {
                    const oRow = aStatuses.find((r) => r.status === s.status);
                    return { ...s, total: oRow ? oRow.total : 0 };
                }));
                this._setTrend(oDash, aTrend);
                oDash.setProperty("/shelters", aShelters.map((s) => {
                    // Decimal arrives as text from OData
                    const nPercent = Math.round(Number(s.occupancyPercentage) || 0);
                    return { ...s, percent: nPercent, state: nPercent >= 90 ? "Error" : nPercent >= 70 ? "Warning" : "Success" };
                }));
                oDash.setProperty("/pending", aPending.map((a) => ({
                    ID: a.ID,
                    applicationID: a.applicationID,
                    status: a.status,
                    state: a.status === "Under Review" ? "Warning" : "Information",
                    animalName: a.animal ? a.animal.name : "",
                    applicant: a.applicant ? a.applicant.fullName : ""
                })));
                oDash.setProperty("/pendingCount", String(aStatuses.filter((r) => r.status === "Submitted" || r.status === "Under Review")
                    .reduce((n, r) => n + r.total, 0)));
                oDash.setProperty("/overdue", aOverdue.map((c) => ({ ...c, animalName: c.animal ? c.animal.name : "" })));
                oDash.setProperty("/overdueCount", aOverdue.length >= 6 ? "6+" : String(aOverdue.length));
            } finally {
                oDash.setProperty("/busy", false);
            }
        },

        // last 12 months, ending with the current one; months without adoptions are 0
        _setTrend: function (oDash, aTrend) {
            const oToday = new Date();
            const aPoints = [];
            let iTotal = 0;
            for (let i = 11; i >= 0; i--) {
                const oMonth = new Date(oToday.getFullYear(), oToday.getMonth() - i, 1);
                const iYear = oMonth.getFullYear(), iMonth = oMonth.getMonth() + 1;
                const oRow = aTrend.find((r) => r.year === iYear && r.month === iMonth);
                const iCount = oRow ? oRow.total : 0;
                iTotal += iCount;
                aPoints.push({ label: MONTHS[iMonth - 1], year: String(iYear), total: iCount });
            }
            oDash.setProperty("/trend", aPoints);
            oDash.setProperty("/trendSubtitle", this.getAppComponent().getModel("i18n").getResourceBundle()
                .getText("chartTrendSubtitle", [iTotal]));
        }
    });
});
