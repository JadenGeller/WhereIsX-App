//
//  JGLocationManager.m
//  Where is X
//
//  Created by Jaden Geller on 2/25/14.
//  Copyright (c) 2014 Jaden Geller. All rights reserved.
//

#import "JGLocationManager.h"
#import <objc/runtime.h>
#import <SystemConfiguration/CaptiveNetwork.h>

NSTimeInterval const JGLocationManagerSearchIntervalMinimum = 0;

@interface JGLocationManager ()
{
    __weak id<CLLocationManagerDelegate> _delegate;
}

@property (nonatomic) NSMutableDictionary *networkRegions;
@property (nonatomic) NSMutableArray *currentlyMonitoredNetworks;
@property (nonatomic) NSMutableArray *currentlyInsideNetworks;

@property (nonatomic) BOOL fetching;

@end

@implementation JGLocationManager

-(id)init{
    self = [super init];
    if (self) {
        [super setDelegate:self];
    }
    return self;
}

#pragma mark - Overriding Methods

+(BOOL)isMonitoringAvailableForClass:(Class)regionClass{
    return ([super isMonitoringAvailableForClass:regionClass] || [regionClass isSubclassOfClass:[JGNetworkRegion class]]);
}

-(void)requestStateForRegion:(CLRegion *)region{
    if ([region.class isSubclassOfClass:[JGNetworkRegion class]]) {
        
        // ISSUE - calls delegate for every network region
        [super requestStateForRegion:[(JGNetworkRegion*)region circularRegion]];
    }
    else{
        [super requestStateForRegion:region];
    }
}

-(void)startMonitoringForRegion:(CLRegion *)region{
    if ([region.class isSubclassOfClass:[JGNetworkRegion class]]) {
        [self registerObject:region toCircularRegion:[(JGNetworkRegion*)region circularRegion]];
    }
    else if([region.class isSubclassOfClass:[CLCircularRegion class]]){
        [self registerObject:[NSNull null] toCircularRegion:(CLCircularRegion*)region];
    }
    else{
        [super startMonitoringForRegion:region];
    }
}

-(void)stopMonitoringForRegion:(CLRegion *)region{
    if ([region.class isSubclassOfClass:[JGNetworkRegion class]]) {
        [self deregisterObject:region fromCircularRegion:[(JGNetworkRegion*)region circularRegion]];
    }
    else if([region.class isSubclassOfClass:[CLCircularRegion class]]){
        [self deregisterObject:[NSNull null] fromCircularRegion:(CLCircularRegion*)region];
    }
    else{
        [super startMonitoringForRegion:region];
    }
}

#pragma mark - Properties

-(NSMutableArray*)currentlyMonitoredNetworks{
    if (!_currentlyMonitoredNetworks) {
        _currentlyMonitoredNetworks = [NSMutableArray array];
    }
    return _currentlyMonitoredNetworks;
}

-(NSMutableArray*)currentlyInsideNetworks{
    if (!_currentlyInsideNetworks) {
        _currentlyInsideNetworks = [NSMutableArray array];
    }
    return _currentlyInsideNetworks;
}

-(NSMutableDictionary*)networkRegions{
    if (!_networkRegions) {
        _networkRegions = [NSMutableDictionary dictionary];
    }
    return _networkRegions;
}

-(void)registerObject:(id)object toCircularRegion:(CLCircularRegion*)circularRegion{
    if (![self.networkRegions objectForKey:circularRegion]) {
        [self.networkRegions setObject:[NSMutableArray array] forKey:circularRegion];
        
        [super startMonitoringForRegion:circularRegion];
    }
    [[self.networkRegions objectForKey:circularRegion] addObject:object];
}

-(void)deregisterObject:(id)object fromCircularRegion:(CLCircularRegion*)circularRegion{
    [[self.networkRegions objectForKey:circularRegion]removeObject:object];
    
    if ([[self.networkRegions objectForKey:circularRegion] count] == 0) {
        [self.networkRegions removeObjectForKey:circularRegion];
        
        [super stopMonitoringForRegion:circularRegion];
    }
}

#pragma mark - Delegate interception

-(id)forwardingTargetForSelector:(SEL)aSelector{
    if ([_delegate respondsToSelector:aSelector]) return _delegate;
    else return [super forwardingTargetForSelector:aSelector];
}

-(BOOL)respondsToSelector:(SEL)aSelector{
    return ([super respondsToSelector:aSelector] || [_delegate respondsToSelector:aSelector]);
}

-(id<CLLocationManagerDelegate>)delegate{
    return self;
}

-(void)setDelegate:(id<CLLocationManagerDelegate>)delegate{
    _delegate = delegate;
}

#pragma mark - Delegate implementation

-(void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region{
    if ([region isKindOfClass:[CLCircularRegion class]]) {
        NSArray *networkRegionsForCircularRegion = [self.networkRegions objectForKey:region];
        
        for (JGNetworkRegion *networkRegion in networkRegionsForCircularRegion) {
            if ([networkRegion isKindOfClass:[JGNetworkRegion class]]) {
                // Let the users know what the state of our network region is
                // We are nearby, so we need to use our magical network detection skills to find out if we are in the region
                
                NSString *BSSID = [self currentBSSID];
                BOOL found = [networkRegion.networkData containsObject:BSSID];
                CLRegionState state = found ? CLRegionStateInside : CLRegionStateOutside;
                [_delegate locationManager:manager didDetermineState:state forRegion:networkRegion];
            }
            else{
                // An actual circular region that the user cared about
                [_delegate locationManager:manager didDetermineState:state forRegion:region];
            }
        }

    }
    else{
        [_delegate locationManager:manager didDetermineState:state forRegion:region];
    }
}

-(void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    if ([region isKindOfClass:[CLCircularRegion class]]) {
        NSArray *networkRegionsForCircularRegion = [self.networkRegions objectForKey:region];
        
        for (JGNetworkRegion *networkRegion in networkRegionsForCircularRegion) {
            if ([networkRegion isKindOfClass:[JGNetworkRegion class]]) {
                // Start tracking network because we entered the relevant region
                [self stopMonitoringNetwork:networkRegion];
            }
            else{
                // An actual circular region that the user cared about
                [_delegate locationManager:manager didEnterRegion:region];
            }
        }
    }
    else{
        [_delegate locationManager:manager didEnterRegion:region];
    }
}

-(void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    if ([region isKindOfClass:[CLCircularRegion class]]) {
        NSArray *networkRegionsForCircularRegion = [self.networkRegions objectForKey:region];
        
        for (JGNetworkRegion *networkRegion in networkRegionsForCircularRegion) {
            if ([networkRegion isKindOfClass:[JGNetworkRegion class]]) {
                // Stop tracking network because we left the relevant region
                [self stopMonitoringNetwork:networkRegion];
            }
            else{
                // An actual circular region that the user cared about
                [_delegate locationManager:manager didExitRegion:region];
            }
        }
        
    }
    else{
        [_delegate locationManager:manager didExitRegion:region];
    }
}

#pragma mark - Fetching

-(void)startMonitoringNetwork:(JGNetworkRegion*)network{
    [self.currentlyMonitoredNetworks addObject:network];
    
    self.fetching = self.currentlyMonitoredNetworks.count;
}

-(void)stopMonitoringNetwork:(JGNetworkRegion*)network{
    [self.currentlyMonitoredNetworks removeObject:network];
    [self.currentlyInsideNetworks removeObject:network];
    
    self.fetching = self.currentlyMonitoredNetworks.count;
}

-(void)setFetching:(BOOL)fetching{
    // ISSUE - doesn't refresh in foreground
    
    if (fetching != _fetching) {
        _fetching = fetching;
        
        if (fetching){
            [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:self.searchInterval];
            
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(backgroundFetch:) name:@"fetchRequested" object:nil];
        }
        else{
            [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalNever];
        }

    }
}

-(void)setSearchInterval:(NSTimeInterval)searchInterval{
    _searchInterval = searchInterval;
    
    if (self.fetching) [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:searchInterval];
}

-(void)backgroundFetch:(NSNotification*)notification{
    void (^completionHandler)(UIBackgroundFetchResult) = notification.object;
    
    NSString *currentBSSID = [self currentBSSID];
    
    BOOL newData = NO;
    for (JGNetworkRegion *region in self.currentlyMonitoredNetworks) {
        BOOL insideNetwork = [region.networkData containsObject:currentBSSID];
        
        if (insideNetwork && ![self.currentlyInsideNetworks containsObject:region]) {
            [self.currentlyInsideNetworks addObject:region];
            [_delegate locationManager:self didEnterRegion:region];
            newData = YES;
        }
        else if(!insideNetwork && [self.currentlyInsideNetworks containsObject:region]){
            [self.currentlyInsideNetworks removeObject:region];
            [_delegate locationManager:self didExitRegion:region];
            newData = YES;
        }
    }
    
    completionHandler(newData ? UIBackgroundFetchResultNewData : UIBackgroundFetchResultNoData);
}

#pragma mark - Network

- (NSString *)currentBSSID
{
    NSArray *ifs = (__bridge id)CNCopySupportedInterfaces();
    
    NSDictionary *info = nil;
    for (NSString *ifnam in ifs) {
        info = (__bridge_transfer NSDictionary*)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifnam);
        if (info && [info count]) break;
    }
    return info[@"BSSID"];
}

@end