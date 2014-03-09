//
//  JGLocationManager.m
//  Where is X
//
//  Created by Jaden Geller on 2/27/14.
//  Copyright (c) 2014 Jaden Geller. All rights reserved.
//

#import "JGLocationManager.h"
#import "JGWifiLocation.h"

NSString * const JGLocationsArrayKey = @"com.whereis.locations.saved";

@interface JGLocationManager ()
{
    NSMutableArray *_locations;
}

@property (nonatomic) CLLocationManager *regionManager;
@property (nonatomic) JGWifiLocationManager *wifiManager;

@property (nonatomic) NSMutableArray *insideLocations;

@end

@implementation JGLocationManager

@synthesize highestPriorityEnteredRegion = _highestPriorityEnteredRegion;

-(id)init{
    if (self = [super init]) {
        _locations = [[NSKeyedUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults]objectForKey:JGLocationsArrayKey]] mutableCopy];
        if (!_locations) {
            _locations = [NSMutableArray array];
        }
        [self.regionManager startMonitoringSignificantLocationChanges];
        [self trackAllLocations];
    }
    return self;
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    CLLocation *current = [locations lastObject];
    
    CLGeocoder *geocode = [[CLGeocoder alloc]init];
    [geocode reverseGeocodeLocation:current completionHandler:^(NSArray *placemarks, NSError *error) {
        CLPlacemark *place = placemarks[0]; //disregard any other possible responses
        self.city = place.locality;
        
        if (self.insideLocations.count == 0) {
            [self.delegate locationChanged];
        }
    }];
}

-(void)trackAllLocations{
    for (NSObject *obj in self.locations) [self trackLocation:obj];
}

-(void)trackLocation:(NSObject*)location{
    if ([location isKindOfClass:[CLRegion class]]) {
        [self.regionManager startMonitoringForRegion:(CLRegion*)location];
        [self.regionManager requestStateForRegion:(CLRegion*)location];
    }
    else if([location isKindOfClass:[JGWifiLocation class]]){
        [self.wifiManager startMonitoringForLocation:(JGWifiLocation*)location];
    }
}

-(void)addLocation:(NSObject*)location{
    [_locations addObject:location];
    [self trackLocation:location];
    [self save];
}

-(void)stopTrackingLocation:(NSObject*)location{
    if ([location isKindOfClass:[CLRegion class]]) {
        [self.regionManager stopMonitoringForRegion:(CLRegion*)location];
    }
    else if([location isKindOfClass:[JGWifiLocation class]]){
        [self.wifiManager stopMonitoringForLocation:(JGWifiLocation*)location];
    }
}

-(void)removeLocationAtIndex:(NSInteger)index{
    NSObject *location = [self.locations objectAtIndex:index];
    [self stopTrackingLocation:location];
    [_locations removeObjectAtIndex:index];
    [self save];
}

-(void)moveLocationAtIndex:(NSInteger)oldIndex toIndex:(NSInteger)newIndex{
    NSObject *obj = [self.locations objectAtIndex:oldIndex];
    [_locations removeObjectAtIndex:oldIndex];
    [_locations insertObject:obj atIndex:newIndex];
    [self save];
}

-(NSArray*)locations{
    return _locations.copy;
}

-(CLLocationManager*)regionManager{
    if (!_regionManager) {
        _regionManager = [[CLLocationManager alloc]init];
        _regionManager.delegate = self;
    }
    return _regionManager;
}

-(JGWifiLocationManager*)wifiManager{
    if (!_wifiManager) {
        _wifiManager = [[JGWifiLocationManager alloc]init];
        _wifiManager.delegate = self;
    }
    return _wifiManager;
}

-(NSMutableArray*)insideLocations{
    if (!_insideLocations) {
        _insideLocations = [NSMutableArray array];
    }
    return _insideLocations;
}

-(void)updateHighestPriorityEnteredRegion{
    NSObject *new;
    
    for (NSObject *location in self.locations) {
        if ([self.insideLocations containsObject:location]){
            new = location;
            break;
        }
    }
    
    BOOL changed = ![new isEqual:_highestPriorityEnteredRegion];
    _highestPriorityEnteredRegion = new;

    if (changed) [self.delegate locationChanged];
}

-(void)save{
    [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:self.locations] forKey:JGLocationsArrayKey];
}

-(void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region{
    if (CLRegionStateInside == state) [self didEnterLocation:region];
    else if (CLRegionStateOutside == state) [self didExitLocation:region];
}

-(void)locationManager:(JGWifiLocationManager*)manager didEnterLocation:(JGWifiLocation*)location{
    [self didEnterLocation:location];
}

-(void)locationManager:(JGWifiLocationManager*)manager didExitLocation:(JGWifiLocation*)location{
    [self didExitLocation:location];
}

-(void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region{
    [self didEnterLocation:region];
}

-(void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region{
    [self didExitLocation:region];
}

-(void)didEnterLocation:(NSObject*)location{
    if (![self.insideLocations containsObject:location]) {
        [self.insideLocations addObject:location];
        [self updateHighestPriorityEnteredRegion];
    }
}

-(void)didExitLocation:(NSObject*)location{
    if ([self.insideLocations containsObject:location]) {
        [self.insideLocations removeObject:location];
        [self updateHighestPriorityEnteredRegion];
    }
}

@end
