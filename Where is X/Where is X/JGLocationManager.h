//
//  JGLocationManager.h
//  Where is X
//
//  Created by Jaden Geller on 2/27/14.
//  Copyright (c) 2014 Jaden Geller. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "JGWifiLocationManager.h"

@protocol JGLocationManagerDelegate <NSObject>

-(void)locationChanged;

@end

@interface JGLocationManager : NSObject <CLLocationManagerDelegate, JGWifiLocationManagerDelegate>

@property (nonatomic) NSString *locationString;

@property (nonatomic) id<JGLocationManagerDelegate> delegate;

@property (nonatomic) NSString *city;
@property (nonatomic) NSArray *locations;

@property (nonatomic) NSObject *highestPriorityEnteredRegion;

-(void)addLocation:(NSObject*)location;
-(void)removeLocationAtIndex:(NSInteger)index;
-(void)moveLocationAtIndex:(NSInteger)oldIndex toIndex:(NSInteger)newIndex;
-(void)updateHighestPriorityEnteredRegion;

@end
