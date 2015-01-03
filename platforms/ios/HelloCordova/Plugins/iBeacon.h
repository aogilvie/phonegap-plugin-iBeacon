/**
 *
 * @author Ally Ogilvie
 * @copyright Ally Ogilvie 2014
 * @file iBeacon.h
 *
 */

#import <Cordova/CDV.h>
#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface iBeacon: CDVPlugin<CLLocationManagerDelegate>

- (void)startMonitoringForRegion:(CDVInvokedUrlCommand *)command;
- (void)stopMonitoringForRegion:(CDVInvokedUrlCommand *)command;
- (void)startRangingBeaconsInRegion:(CDVInvokedUrlCommand *)command;
- (void)stopRangingBeaconsInRegion:(CDVInvokedUrlCommand *)command;
- (void)isRangingAvailable:(CDVInvokedUrlCommand *)command;
- (void)getAuthorizationStatus:(CDVInvokedUrlCommand *)command;

@end

