//
//  JGBSSIDRanger.m
//  JGBSSIDRangerExample
//
//  Created by Jaden Geller on 2/25/14.
//  Copyright (c) 2014 Jaden Geller. All rights reserved.
//

#import "JGBSSIDRanger.h"
#import <SystemConfiguration/CaptiveNetwork.h>

@interface JGBSSIDRanger ()
{
    NSMutableArray *_BSSIDs;
}

@property (nonatomic) NSTimer *searchTimer;

@end

@implementation JGBSSIDRanger

-(id)init{
    if (self = [super init]) {
        _BSSIDs = [NSMutableArray array];
        
    }
    return self;
}

-(void)clear{
    [_BSSIDs removeAllObjects];
}

-(void)setRecord:(BOOL)record{
    _record = record;
    if (!record) {
        [self clear];
    }
}

-(void)setSearchInterval:(NSTimeInterval)searchInterval{
    _searchInterval = searchInterval;
    [self.searchTimer invalidate];
    if (self.ranging) [self startTimer];
}

-(void)startTimer{
    self.searchTimer = [NSTimer scheduledTimerWithTimeInterval:self.searchInterval target:self selector:@selector(performSearchForDelegate) userInfo:nil repeats:YES];
}

-(void)performSearchForDelegate{
    NSString *search = [self performSearch];
    if (search && [self.delegate respondsToSelector:@selector(foundNewBSSID:)]) [self.delegate foundNewBSSID:search];
}

-(NSString*)performSearch{
    NSString *BSSID = [JGBSSIDRanger currentBSSID];
    
    if (![_BSSIDs containsObject:BSSID]) {
        if (!self.record) [_BSSIDs removeAllObjects];
        [_BSSIDs addObject:BSSID];
        return BSSID;
    }
    return nil;
}

-(NSString*)BSSIDs{
    return [_BSSIDs copy];
}

-(void)setRanging:(BOOL)ranging{
    if (_ranging != ranging) {
        _ranging = ranging;
        
        if (ranging) {
            [self startTimer];
        }
        else{
            [self.searchTimer invalidate];
        }
    }
}

+ (NSString *)currentBSSID
{
    NSArray *ifs = (__bridge id)CNCopySupportedInterfaces();
    
    NSDictionary *info = nil;
    for (NSString *ifnam in ifs) {
        info = (__bridge_transfer NSDictionary*)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifnam);
        if (info && [info count]) break;
    }
    return info[@"BSSID"];
}

-(void)dealloc{
    [self.searchTimer invalidate];
}

@end
