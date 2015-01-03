cordova.define("com.github.aogilvie.phonegap.plugin.iBeacon", function(require, exports, module) {
    /**
     * 
     * @author Ally Ogilvie
     * @copyright Ally Ogilvie 2014
     * @file iBeacon.js for PhoneGap
     *
     */

    var exec = require("cordova/exec");

    if (window.cordova) {
        window.document.addEventListener("deviceready", function () {
            exec(null, null, "iBeacon", "ready", []);
        }, false);
    }

    var IBeacon = function () {};

    IBeacon.prototype.startRangingBeaconsInRegion = function (region, success, failure) {
        exec(success, failure, "iBeacon", "startRangingBeaconsInRegion", [region]);
    };

    IBeacon.prototype.startMonitoringBeaconsInRegion = function (region, success, failure) {
        exec(success, failure, "iBeacon", "startMonitoringBeaconsInRegion", [region]);
    };

    IBeacon.prototype.stopRangingBeaconsInRegion = function (region, success, failure) {
        exec(success, failure, "iBeacon", "stopRangingBeaconsInRegion", [region]);
    };

    IBeacon.prototype.stopMonitoringBeaconsInRegion = function (region, success, failure) {
        exec(success, failure, "iBeacon", "stopMonitoringBeaconsInRegion", [region]);
    };

    // Instantiate IBeacon
    window.iBeacon = new IBeacon();
    console.log("iBeacon Plugin JS API loaded");
    module.exports = iBeacon;
});