sap.ui.define([
    "sap/fe/test/JourneyRunner",
	"adminapplications/test/integration/pages/AdoptionApplicationsList.gen",
	"adminapplications/test/integration/pages/AdoptionApplicationsObjectPage.gen"
], function (JourneyRunner, AdoptionApplicationsListGenerated, AdoptionApplicationsObjectPageGenerated) {
    'use strict';

    const runner = new JourneyRunner({
        launchUrl: sap.ui.require.toUrl('adminapplications') + '/test/flp.html#app-preview',
        pages: {
			onTheAdoptionApplicationsListGenerated: AdoptionApplicationsListGenerated,
			onTheAdoptionApplicationsObjectPageGenerated: AdoptionApplicationsObjectPageGenerated
        },
        async: true
    });

    return runner;
});

