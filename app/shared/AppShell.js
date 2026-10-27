// Top bar shared by the admin and the adopter app (sap.f.ShellBar above every page).
//   left:  logo + app title -> back to the start page of the app (Dashboard / Home)
//   right: avatar -> account menu with name, email, role, "My Profile" (adopter app) and "Sign out"
// Each app's Component.js calls AppShell.create(...) once. The bar is placed into <div id="shellbar">
// of the app's index.html; the account data comes from UserService.myRoles() (/user/myRoles()).
sap.ui.define([
    "sap/f/ShellBar",
    "sap/m/Avatar",
    "sap/m/ResponsivePopover",
    "sap/m/VBox",
    "sap/m/HBox",
    "sap/m/Title",
    "sap/m/Text",
    "sap/m/ObjectStatus",
    "sap/m/List",
    "sap/m/StandardListItem",
    "sap/base/Log"
], function (ShellBar, Avatar, ResponsivePopover, VBox, HBox, Title, Text, ObjectStatus, List, StandardListItem, Log) {
    "use strict";

    // the app router (deployed app) offers /do/logout; cds watch (port 4004) has no logout
    const LOCAL = location.port === "4004" || location.hostname.startsWith("port4004-");
    // both apps live one folder below the root (/admin-app/, /adopter-app/)
    const ROOT = new URL("../", location.href).pathname;

    function initials(sName) {
        const aParts = String(sName || "?").split("@")[0].split(/[\s._-]+/).filter(Boolean);
        return ((aParts[0] || "?")[0] + (aParts[1] ? aParts[1][0] : "")).toUpperCase();
    }

    async function readAccount() {
        try {
            const oResponse = await fetch(ROOT + "user/myRoles()", { headers: { Accept: "application/json" }, credentials: "same-origin" });
            if (!oResponse.ok) throw new Error(`${oResponse.status} ${oResponse.statusText}`);
            return await oResponse.json();
        } catch (e) {
            Log.error("Top bar: reading the account failed", e);
            return { user: "", name: "", email: "", admin: false, adopter: false };
        }
    }

    return {
        /**
         * @param {sap.ui.core.UIComponent} oComponent the app component
         * @param {object} mSettings
         * @param {string} mSettings.title       app title in the bar
         * @param {string} mSettings.homeRoute   route of the start page (logo / title press)
         * @param {boolean} [mSettings.profile]  show "My Profile" in the account menu (adopter app)
         */
        create: function (oComponent, mSettings) {
            if (!document.getElementById("shellbar")) return; // started without our index.html (e.g. in a launchpad)

            const oAvatar = new Avatar({ initials: "", displaySize: "XS", backgroundColor: "Accent6", tooltip: "Account" });
            const oShellBar = new ShellBar({
                title: mSettings.title,
                homeIcon: sap.ui.require.toUrl("animaladoption/shared/logo.svg"),
                homeIconTooltip: "Start page",
                showCopilot: false,
                profile: oAvatar,
                homeIconPressed: () => oComponent.getRouter().navTo(mSettings.homeRoute)
            });

            let oAccount = { user: "", name: "", email: "" };
            const oPopover = this._createAccountMenu(oComponent, mSettings, () => oAccount);
            oShellBar.attachAvatarPressed((oEvent) => oPopover.openBy(oEvent.getParameter("avatar") || oAvatar));
            oShellBar.placeAt("shellbar");

            readAccount().then((oResult) => {
                oAccount = oResult;
                oAvatar.setInitials(initials(oResult.name || oResult.user));
                oAvatar.setTooltip(oResult.name || oResult.user);
            });
        },

        _createAccountMenu: function (oComponent, mSettings, fnAccount) {
            const oAvatar = new Avatar({ displaySize: "M", backgroundColor: "Accent6" });
            const oName = new Title({ level: "H3", wrapping: true });
            const oEmail = new Text({ wrapping: true });
            const oRole = new ObjectStatus({ state: "Information", inverted: true });

            const aItems = [];
            if (mSettings.profile) {
                aItems.push(new StandardListItem({
                    title: "My Profile", icon: "sap-icon://person-placeholder", type: "Active",
                    press: () => { oPopover.close(); this._openProfile(oComponent, mSettings.homeRoute); }
                }));
            }
            if (!LOCAL) {
                aItems.push(new StandardListItem({
                    title: "Sign out", icon: "sap-icon://log", type: "Active",
                    press: () => { location.href = ROOT + "do/logout"; }
                }));
            }

            const oPopover = new ResponsivePopover({
                showHeader: false,
                placement: "Bottom",
                contentWidth: "18rem",
                content: [
                    new HBox({
                        alignItems: "Center",
                        items: [oAvatar, new VBox({ items: [oName, oEmail, oRole] }).addStyleClass("sapUiSmallMarginBegin")]
                    }).addStyleClass("sapUiSmallMargin"),
                    new List({ items: aItems, showNoData: false })
                ],
                beforeOpen: () => {
                    const oAccount = fnAccount();
                    oAvatar.setInitials(initials(oAccount.name || oAccount.user));
                    oName.setText(oAccount.name || oAccount.user);
                    oEmail.setText(oAccount.email && oAccount.email !== oAccount.name ? oAccount.email : "");
                    oEmail.setVisible(!!oEmail.getText());
                    oRole.setText(oAccount.admin ? "Shelter administrator" : oAccount.adopter ? "Adopter" : "No role assigned");
                    oRole.setState(oAccount.admin || oAccount.adopter ? "Information" : "Warning");
                }
            });
            return oPopover;
        },

        // My Profile is handled by the start page of the app (Home controller): it has the Fiori elements
        // edit flow, which opens the saved profile or starts the registration form with Create / Cancel.
        // If the start page was already shown it listens on the event bus, otherwise it picks the
        // request up when it is opened.
        _openProfile: function (oComponent, sHomeRoute) {
            if (oComponent._homeReady) {
                oComponent.getEventBus().publish("animaladoption", "openProfile");
            } else {
                oComponent._openProfileOnHome = true;
                oComponent.getRouter().navTo(sHomeRoute);
            }
        }
    };
});
