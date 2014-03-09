//
//  JGWifiLocationManager.m
//  Where is X
//
//  Created by Jaden Geller on 2/28/14.
//  Copyright (c) 2014 Jaden Geller. All rights reserved.
//

#import "JGWifiLocationManager.h"
#import "JGWifiLocation.h"

@interface JGWifiLocationManager ()

@property (nonatomic) CLLocationManager *manager;
@property (nonatomic) NSCountedSet *regions;
@property (nonatomic) NSMutableArray *locations;

@property (nonatomic) NSMutableArray *watched;
@property (nonatomic) NSMutableArray *inside;

@property (nonatomic) JGBSSIDRanger *ranger;

@end

@implementation JGWifiLocationManager

-(id)init{
    if (self = [super init]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willResignActive) name:UIApplicationWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchRequested:) name:@"fetchRequested" object:nil];

    }
    return self;
}

-(void)fetchRequested:(NSNotification*)notification{
    void (^completionHandler)(UIBackgroundFetchResult) = notification.object;
    NSString *search = [self.ranger performSearch];
    
    if (search) {
        [self foundNewBSSID:search];
        BOOL new = [self changedRegion:search];
        completionHandler(new ? UIBackgroundFetchResultNewData : UIBackgroundFetchResultNoData);
    }
    else completionHandler(UIBackgroundFetchResultNoData);
}

-(void)willResignActive{
    self.ranger.ranging = NO;
}

-(void)willEnterForeground{
    if (self.watched.count != 0) {
        self.ranger.ranging = YES;
    }
}

-(void)startMonitoringForLocation:(JGWifiLocation*)location{
    [self.locations addObject:location];
    [self.regions addObject:location.associatedCircularRegion];

    if ([self.regions countForObject:location.associatedCircularRegion] == 0) {
        [self.manager startMonitoringForRegion:location.associatedCircularRegion];
         NSLog(@"a");
    }
    // this will add it to watched if we are in the region
    [self.manager requestStateForRegion:location.associatedCircularRegion];
    
    
    // Core location is a bitch
    [self startWatching:location];
    
}

-(void)stopMonitoringForLocation:(JGWifiLocation*)location{
    [self stopWatching:location];
    [self.locations removeObject:location];
    
    [self.regions removeObject:location.associatedCircularRegion];
    
    if ([self.regions countForObject:location.associatedCircularRegion] == 0) {
        [self.manager stopMonitoringForRegion:location.associatedCircularRegion];
    }
}

-(CLLocationManager*)manager{
    if (!_manager) {
        _manager = [[CLLocationManager alloc]init];
        _manager.delegate = self;
    }
    return _manager;
}

-(NSCountedSet*)regions{
    if (!_regions) {
        _regions = [NSCountedSet set];
    }
    return _regions;
}

-(NSMutableArray*)locations{
    if (!_locations) {
        _locations = [NSMutableArray array];
    }
    return _locations;
}

-(NSMutableArray*)watched{
    if (!_watched) {
        _watched = [NSMutableArray array];
    }
    return _watched;
}

-(NSMutableArray*)inside{
    if (!_inside) {
        _inside = [NSMutableArray array];
    }
    return _inside;
}

-(JGBSSIDRanger*)ranger{
    if (!_ranger) {
        _ranger = [[JGBSSIDRanger alloc]init];
        _ranger.delegate = self;
    }
    return _ranger;
}
-(void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region{
     NSLog(@"B");
    for (JGWifiLocation *location in self.locations) {
        if ([location.associatedCircularRegion.identifier isEqualToString:region.identifier]) {
             NSLog(@"C");
            // this location wants to start being updated
            if (state == CLRegionStateInside)[self startWatching:location];
            else if (state == CLRegionStateOutside) [self stopWatching:location];
        }
    }

}

-(void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region{
    for (JGWifiLocation *location in self.locations) {
        if ([location.associatedCircularRegion.identifier isEqualToString:region.identifier]) {
            // this location wants to start being updated
            [self startWatching:location];
        }
    }
}

-(void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region{
    for (JGWifiLocation *location in self.locations) {
        if ([location.associatedCircularRegion.identifier isEqualToString:region.identifier]) {
            // this location wants to stop being updated
            [self stopWatching:location];
        }
    }
}

-(void)startWatching:(JGWifiLocation*)location{
     NSLog(@"D");
    NSString *currentBSSID = self.ranger.BSSIDs.count?self.ranger.BSSIDs[0]:nil;
    if (self.watched.count == 0) {
        self.ranger.ranging = YES;
        
        [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:self.searchInterval];
    }
    else if(currentBSSID && [location.networkData containsObject:currentBSSID]){
        [self changedRegion:currentBSSID];
    }
    
    [self.watched addObject:location];
}

-(void)setSearchInterval:(NSTimeInterval)searchInterval{
    if (self.watched.count != 0) [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:_searchInterval];
    _searchInterval = searchInterval;

}

-(void)stopWatching:(JGWifiLocation*)location{
    [self.watched removeObject:location];
    
    if (self.watched.count == 0) {
        self.ranger.ranging = NO;
        
        [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalNever];

    }
}

-(BOOL)ranging{
    return self.ranger.ranging;
}

-(void)foundNewBSSID:(NSString *)BSSID{
    [self changedRegion:BSSID];
}

// returns if this is a watched region
-(BOOL)changedRegion:(NSString*)BSSID
{
    BOOL isWatched = NO;
    for (JGWifiLocation *location in self.watched) {
        if ([location.networkData containsObject:BSSID] && ![self.inside containsObject:location]) {
            [self.inside addObject:location];
            [self.delegate locationManager:self didEnterLocation:location];
            isWatched = YES;
        }
        else if([self.inside containsObject:location]){
            [self.inside removeObject:location];
            [self.delegate locationManager:self didExitLocation:location];
            isWatched = YES;
        }
    }
    return isWatched;
}

// initial ranging (we need to put regions we are already in in the watched)

@end
