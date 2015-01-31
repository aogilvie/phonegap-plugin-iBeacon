# iBeacon Plugin

### iOS Only

plist requirements:

- NSLocationAlwaysUsageDescription
- NSLocationWhenInUseUsageDescription

optional

- Required device capabilities (bluetooth-le + armv7)

Framework requirements

- CoreBluetooth
- CoreLocation

### API

#### `iBeacon.startMonitoringBeaconsInRegion()`


####  `iBeacon.startRangingBeaconsInRegion()`

Get the distance information for any beacons in the area.

#### `iBeacon.addBeacons(beacons)`

Add beacons to look for when ranging

`Beacons` is an array of beacon objects for example:

```
[{ uuid: "1234-1234-1234-1234" }, .... ]
```

### Events

```
document.addEventListener('iBeaconRanging', function (event) {
	// event.unknown []
	// event.immediate []
	// event.near []
	// event.far []
	
	// Each beacon in the array has the following properties:
	// event.immediate[0].uuid
	// event.immediate[0].accuracy (cm)
	if (event.immediate.length > 0) {
    	console.log("Beacon: " + event.immediate[0].uuid + " - " + event.immediate[0].accuracy)
    }
}, false);
```