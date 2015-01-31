/**
 *
 * @author Ally Ogilvie
 * @copyright Ally Ogilvie 2014
 * @file iBeacon.m
 *
 */

#import "iBeacon.h"
#import "iBeaconDefaults.h"

@implementation iBeacon {
    CLLocationManager *_locationManager;
    
    // Monitoring properties
    BOOL _enabled;
    NSUUID *_uuid;
    NSNumber *_major;
    NSNumber *_minor;
    BOOL _notifyOnEntry;
    BOOL _notifyOnExit;
    BOOL _notifyOnDisplay;
    
    UISwitch *_enabledSwitch;
    
    UITextField *_uuidTextField;
    UIPickerView *_uuidPicker;
    
    NSNumberFormatter *_numberFormatter;
    UITextField *_majorTextField;
    UITextField *_minorTextField;
    
    UISwitch *_notifyOnEntrySwitch;
    UISwitch *_notifyOnExitSwitch;
    UISwitch *_notifyOnDisplaySwitch;
    
    // Ranging properties
    NSMutableDictionary *_beacons;
    NSMutableArray *_rangedRegions;
}

# pragma mark CDVPlugin
+ (void)load {
    // Register for didFinishLaunching notifications in class load method so that
    // this class can observe launch events.  Do this here because this needs to be
    // registered before the AppDelegate's application:didFinishLaunchingWithOptions:
    // method finishes executing.  A class's load method gets invoked before
    // application:didFinishLaunchingWithOptions is invoked (even if the plugin is
    // not loaded/invoked in the JavaScript).
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didFinishLaunching:)
                                                 name:UIApplicationDidFinishLaunchingNotification
                                               object:nil];
    // Register for willTerminate notifications here so that we can observer terminate
    // events and unregister observing launch notifications.  This isn't strictly
    // required (and may not be called according to the docs).
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willTerminate:)
                                                 name:UIApplicationWillTerminateNotification
                                               object:nil];
}

+ (void)willTerminate:(NSNotification *)notification {
    // Stop the class from observing all notification center notifications.
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (void)didFinishLaunching:(NSNotification *)notification {

}

-(CDVPlugin *)initWithWebView:(UIWebView *)theWebView {
    self = (iBeacon *)[super initWithWebView:theWebView];
    
    // This location manager will be used to notify the user of region state transitions.
    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.delegate = self;

    // Check if iOS 8, then request iBeacon permissions
    if ([_locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
        [_locationManager requestAlwaysAuthorization];
    }
    
    // Check if iOS 8, then request notification permissions
    if ([UIApplication instancesRespondToSelector:@selector(registerUserNotificationSettings:)]) {
        [[UIApplication sharedApplication] registerUserNotificationSettings:
         [UIUserNotificationSettings settingsForTypes:
          (UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound) categories:NULL]];
    }

    // Register the instance to observe CDVLocalNotification notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(notificationReceived:)
                                                 name:CDVLocalNotification
                                               object:nil];
    
    // Setup monitoring defaults
    CLBeaconRegion *region = [[CLBeaconRegion alloc] initWithProximityUUID:[NSUUID UUID] identifier:@"com.apple.AirLocate"];
    region = [_locationManager.monitoredRegions member:region];
    if (region) {
        _enabled = YES;
        _uuid = region.proximityUUID;
        _major = region.major;
        _minor = region.minor;
        _notifyOnEntry = region.notifyOnEntry;
        _notifyOnExit = region.notifyOnExit;
        _notifyOnDisplay = region.notifyEntryStateOnDisplay;
    } else {
        // Default settings.
        _enabled = NO;
        _uuid = [iBeaconDefaults sharedDefaults].defaultProximityUUID;
        _major = _minor = nil;
        _notifyOnEntry = _notifyOnExit = YES;
        _notifyOnDisplay = NO;
    }
    
    // Setup ranging defaults
    // Populate the regions we will range once.
    _rangedRegions = [NSMutableArray array];
    [[iBeaconDefaults sharedDefaults].supportedProximityUUIDs enumerateObjectsUsingBlock:^(id uuidObj, NSUInteger uuidIdx, BOOL *uuidStop) {
        NSUUID *uuid = (NSUUID *)uuidObj;
        CLBeaconRegion *region = [[CLBeaconRegion alloc] initWithProximityUUID:uuid identifier:[uuid UUIDString]];
        [_rangedRegions addObject:region];
    }];
    
    _enabledSwitch.on = _enabled;
    _notifyOnEntrySwitch.on = _notifyOnEntry;
    _notifyOnExitSwitch.on = _notifyOnExit;
    _notifyOnDisplaySwitch.on = _notifyOnDisplay;
    
    return self;
}

- (void)ready:(CDVInvokedUrlCommand *)command {

}

- (void)notificationReceived:(UILocalNotification *)notification {
    if (notification.alertBody) {
        // If the application is in the foreground, we will notify the user of the region's state via an alert.
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:notification.alertBody message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}

# pragma mark CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager
      didDetermineState:(CLRegionState)state
              forRegion:(CLRegion *)region {

    // A user can transition in or out of a region while the application is not running.
    // When this happens CoreLocation will launch the application momentarily, call this delegate method
    // and we will let the user know via a local notification.
    UILocalNotification *notification = [[UILocalNotification alloc] init];

    if (state == CLRegionStateInside) {
        notification.alertBody = @"You're inside the region";
    } else if (state == CLRegionStateOutside) {
        notification.alertBody = @"You're outside the region";
    } else {
        return;
    }

    // If the application is in the foreground, it will get a callback to application:didReceiveLocalNotification:.
    // If its not, iOS will display the notification to the user.
    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    
}

-(void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {

}

- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region {
    
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error {
    
    NSLog(@"description %@", error.description);
    NSLog(@"code %ld", (long)error.code);
    // You can get an error if more than 20 regions! (MAX is 20)
    NSLog(@"regions: %lu", (unsigned long)_locationManager.monitoredRegions.count);
    
    NSLog(@"monitoringDidFailForRegion %@ %@", region, error.localizedDescription);
    
    for (CLRegion *monitoredRegion in manager.monitoredRegions) {
        
        NSLog(@"monitoredRegion: %@", monitoredRegion);
        
        [_locationManager stopMonitoringForRegion:monitoredRegion];
        
    }
    
    if ((error.domain != kCLErrorDomain || error.code != 5) && [manager.monitoredRegions containsObject:region]) {
        
        NSString *message = [NSString stringWithFormat:@"%@ %@", region, error.localizedDescription];
        NSLog(@"monitoringDidFailForRegion %@", message);
    }
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region {
    // NSLog(@"beacons: %@", beacons);
    // NSLog(@"region: %@", region);

    // CoreLocation will call this delegate method at 1 Hz with updated range information.
    // Beacons will be categorized and displayed by proximity.
    [_beacons removeAllObjects];
    NSArray *unknownBeacons = [beacons filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"proximity = %d", CLProximityUnknown]];
    if ([unknownBeacons count])
        [_beacons setObject:unknownBeacons forKey:[NSNumber numberWithInt:CLProximityUnknown]];

    NSArray *immediateBeacons = [beacons filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"proximity = %d", CLProximityImmediate]];
    if ([immediateBeacons count])
        [_beacons setObject:immediateBeacons forKey:[NSNumber numberWithInt:CLProximityImmediate]];
    
    NSArray *nearBeacons = [beacons filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"proximity = %d", CLProximityNear]];
    if ([nearBeacons count])
        [_beacons setObject:nearBeacons forKey:[NSNumber numberWithInt:CLProximityNear]];
    
    NSArray *farBeacons = [beacons filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"proximity = %d", CLProximityFar]];
    if ([farBeacons count])
        [_beacons setObject:farBeacons forKey:[NSNumber numberWithInt:CLProximityFar]];
    
    // Build JS Strings
    NSString *unknownBeaconString = [self createJSArrayFromNSArray:unknownBeacons];
    NSString *immediateBeaconString = [self createJSArrayFromNSArray:immediateBeacons];
    NSString *nearBeaconString = [self createJSArrayFromNSArray:nearBeacons];
    NSString *farBeaconString = [self createJSArrayFromNSArray:farBeacons];

    NSString *_beaconString = [NSString stringWithFormat:@"{"
    "\"unknown\": %@, "
    "\"immediate\": %@, "
    "\"near\": %@, "
    "\"far\": %@ }", unknownBeaconString, immediateBeaconString, nearBeaconString, farBeaconString];
    [self callEventEmitter:@"iBeaconRanging" withJSString:_beaconString];
}

// Call Javascript Event Emitter
- (void)callEventEmitter:(NSString *)event withJSString:(NSString *)jsString {
    // Send out event using Cordova event emitter
    NSString *evalString = [NSString stringWithFormat:@"cordova.fireDocumentEvent(\'%@\', %@)", event, jsString];
    // NSLog(@"Emitting %@ event", event);
    [self.commandDelegate evalJs:evalString];
}

- (NSString *)createJSArrayFromNSArray:(NSArray *)beacons {
    NSString *beaconString = @"";
    NSString *beaconArray = @"";
    if ([beacons count]) {
        int i;
        // Create JS Object
        for (i = 0; i < beacons.count; i++) {
            CLBeacon *beacon = [beacons objectAtIndex:i];
            
            if (i == beacons.count -1) {
                // No trailing comma
                beaconString = [NSString stringWithFormat:@"{"
                                "\"uuid\": \"%@\", "
                                "\"major\": %@, "
                                "\"minor\": %@, "
                                "\"accuracy\": %.2f }",
                                [beacon.proximityUUID UUIDString],
                                beacon.major,
                                beacon.minor,
                                beacon.accuracy];
            } else {
                // Add comma
                beaconString = [NSString stringWithFormat:@"{"
                                "\"uuid\": \"%@\", "
                                "\"major\": %@, "
                                "\"minor\": %@, "
                                "\"accuracy\": %.2f },",
                                [beacon.proximityUUID UUIDString],
                                beacon.major,
                                beacon.minor,
                                beacon.accuracy];
            }
            beaconArray = [NSString stringWithFormat:@"%@%@", beaconArray, beaconString];
        }
        beaconArray = [NSString stringWithFormat:@"[%@]", beaconArray];
    } else {
        beaconArray = @"[]";
    }
    return beaconArray;
}

# pragma mark Javascript Plugin API

- (void)startMonitoringForRegion:(CDVInvokedUrlCommand *)command {
    
    if (_enabled) {
        CLBeaconRegion *region = nil;
        if (_uuid && _major && _minor) {
            region = [[CLBeaconRegion alloc] initWithProximityUUID:_uuid major:[_major shortValue] minor:[_minor shortValue] identifier:@"com.apple.AirLocate"];
        } else if (_uuid && _major) {
            region = [[CLBeaconRegion alloc] initWithProximityUUID:_uuid major:[_major shortValue]  identifier:@"com.apple.AirLocate"];
        } else if (_uuid) {
            region = [[CLBeaconRegion alloc] initWithProximityUUID:_uuid identifier:@"com.apple.AirLocate"];
        }
        
        if (region) {
            region.notifyOnEntry = _notifyOnEntry;
            region.notifyOnExit = _notifyOnExit;
            region.notifyEntryStateOnDisplay = _notifyOnDisplay;
            
            [_locationManager startMonitoringForRegion:region];
        }
    } else {
        CLBeaconRegion *region = [[CLBeaconRegion alloc] initWithProximityUUID:[NSUUID UUID] identifier:@"com.apple.AirLocate"];
        [_locationManager stopMonitoringForRegion:region];
    }
}

- (void)stopMonitoringForRegion:(CDVInvokedUrlCommand *)command {
// TODO
}

- (void)startRangingBeaconsInRegion:(CDVInvokedUrlCommand *)command {
    
    // Start ranging beacons
    [_rangedRegions enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CLBeaconRegion *region = obj;
        [_locationManager startRangingBeaconsInRegion:region];
    }];
    
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)stopRangingBeaconsInRegion:(CDVInvokedUrlCommand *)command {
    
    // Stop ranging beacons
    [_rangedRegions enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CLBeaconRegion *region = obj;
        [_locationManager stopRangingBeaconsInRegion:region];
    }];
    
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)addBeacons:(CDVInvokedUrlCommand *)command {
    NSArray *beacons = [command.arguments objectAtIndex:0];
    if (beacons.count > 0) {
        int i;
        for (i = 0; i < beacons.count; i++) {
            NSDictionary *beacon = (NSDictionary *)[beacons objectAtIndex:i];
            [[iBeaconDefaults sharedDefaults] addProximityUUID:[beacon objectForKey:@"uuid"]];

        }
        // Clear rangedRegion, we'll re-populate it
        [_rangedRegions removeAllObjects];
        // Iterate and add new beacons to rangedRegions
        [[iBeaconDefaults sharedDefaults].supportedProximityUUIDs enumerateObjectsUsingBlock:^(id uuidObj, NSUInteger uuidIdx, BOOL *uuidStop) {
            NSUUID *uuid = (NSUUID *)uuidObj;
            CLBeaconRegion *region = [[CLBeaconRegion alloc] initWithProximityUUID:uuid identifier:[uuid UUIDString]];
            [_rangedRegions addObject:region];
        }];
    }
}

- (void)removeBeacons:(CDVInvokedUrlCommand *)command {
    NSArray *beacons = [command.arguments objectAtIndex:0];
    if (beacons.count > 0) {
        int i;
        for (i = 0; i < beacons.count; i++) {
            NSDictionary *beacon = (NSDictionary *)[beacons objectAtIndex:i];
            [[iBeaconDefaults sharedDefaults] removeProximityUUID:[beacon objectForKey:@"uuid"]];
        }
        // Clear rangedRegion, we'll re-populate it
        [_rangedRegions removeAllObjects];
        // Iterate and add new beacons to rangedRegions
        [[iBeaconDefaults sharedDefaults].supportedProximityUUIDs enumerateObjectsUsingBlock:^(id uuidObj, NSUInteger uuidIdx, BOOL *uuidStop) {
            NSUUID *uuid = (NSUUID *)uuidObj;
            CLBeaconRegion *region = [[CLBeaconRegion alloc] initWithProximityUUID:uuid identifier:[uuid UUIDString]];
            [_rangedRegions addObject:region];
        }];
    }
}

- (void)getAuthorizationStatus:(CDVInvokedUrlCommand *)command {
// TODO
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    NSLog(@"didChangeAuthorizationStatus");
}

/*
- (void)getMonitoredRegions:(CDVInvokedUrlCommand *)command {
    NSArray *arrayOfRegions = [self mapsOfRegions:_locationManager.monitoredRegions];
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:arrayOfRegions];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)getRangedRegions:(CDVInvokedUrlCommand *)command {
    NSArray *arrayOfRegions;
    
    if ([self isBelowIos7]) {
        NSLog(@"WARNING Ranging is an iOS 7+ feature.");
        arrayOfRegions = [NSArray new];
    } else {
        arrayOfRegions = [self mapsOfRegions:_locationManager.rangedRegions];
    }

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:arrayOfRegions];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}
*/

- (void)isRangingAvailable:(CDVInvokedUrlCommand *)command {
    BOOL isRangingAvailable;

    if ([self isBelowIos7]) {
        NSLog(@"WARNING Ranging is an iOS 7+ feature.");
        isRangingAvailable = false;
    } else {
        isRangingAvailable = [CLLocationManager isRangingAvailable];
    }

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool: isRangingAvailable];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (BOOL)isBelowIos7 {
    return [[[UIDevice currentDevice] systemVersion] floatValue] < 7.0;
}

@end
