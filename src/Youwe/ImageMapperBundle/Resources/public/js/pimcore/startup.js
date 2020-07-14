pimcore.registerNS("pimcore.plugin.ImageMapperBundle");

pimcore.plugin.ImageMapperBundle = Class.create(pimcore.plugin.admin, {
    getClassName: function () {
        return "pimcore.plugin.ImageMapperBundle";
    },

    initialize: function () {
        pimcore.plugin.broker.registerPlugin(this);
    },

    pimcoreReady: function (params, broker) {
        // alert("ImageMapperBundle ready!");
    }
});

var ImageMapperBundlePlugin = new pimcore.plugin.ImageMapperBundle();
