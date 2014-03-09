//
//  JGViewController.m
//  Where is X
//
//  Created by Jaden Geller on 2/25/14.
//  Copyright (c) 2014 Jaden Geller. All rights reserved.
//

#import "JGViewController.h"
#import "ARServerUpdater.h"
#import "JGWifiLocation.h"

NSString * const JGBedroomBeaconUUID = @"23542266-18D1-4FE4-B4A1-23F8195B9D39";

NSString * const JGBedroomRegionIdentifier = @"com.JadenGeller.whereis.region.bedroom";
NSString * const JGCaltechRegionIdentifier = @"com.JadenGeller.whereis.region.caltech";

CLLocationDegrees const JGCaltechLatitude = 34.13724130951865;
CLLocationDegrees const JGCaltechLongitude = -118.12534332275385;
CLLocationDistance const JGCaltechRadiusMeters = 621.9538056207171;

NSString * const JGLocationStringsDictionaryKey = @"com.whereis.locationstrings.saved";

@interface JGViewController ()

@property (nonatomic) CLBeaconRegion *bedroomRegion;
@property (nonatomic) CLCircularRegion *caltechRegion;

@property (nonatomic) ARServerUpdater *updater;

@property (nonatomic) JGLocationManager *manager;
@property (nonatomic) NSMutableDictionary *locationStrings;

@end

@implementation JGViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    _manager = [[JGLocationManager alloc]init];
    _manager.delegate = self;
    
    
    
//    [self addLocation:[JGWifiLocation wifiLocationWithNetworkData:@[@"20:aa:4b:d5:3f:9e",@"0:b:86:32:f8:72",@"0:1a:1e:6d:45:12",@"0:b:86:32:f8:e2",@"0:b:86:32:f6:82",@"0:b:86:32:f7:12",@"0:b:86:33:16:22",@"0:b:86:32:f8:2"] circularRegion:self.caltechRegion] withDescriptor:@"in Ruddock"];
//    [self addLocation:[[CLBeaconRegion alloc]initWithProximityUUID:[[NSUUID alloc]initWithUUIDString:@"D57092AC-DFAA-446C-8EF3-C81AA22815B5"] identifier:@"blah"] withDescriptor:@"in his room"];
//    [self addLocation:self.caltechRegion withDescriptor:@"on campus"];

}

-(NSUInteger)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskPortrait;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

-(NSMutableDictionary*)locationStrings{
    if (!_locationStrings) {
        _locationStrings = [[NSKeyedUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults]objectForKey:JGLocationStringsDictionaryKey]]mutableCopy];
        if (!_locationStrings) {
            _locationStrings = [NSMutableDictionary dictionary];
        }
    }
    return _locationStrings;
}

-(NSString*)locationString{
    NSObject *location = self.manager.highestPriorityEnteredRegion;
    if (self.hidden) return @"somewhere";
    else if (location) return [self.locationStrings objectForKey:location];
    else if (self.manager.city) return [NSString stringWithFormat:@"in %@",self.manager.city];
    else return @"somewhere";
}

-(void)locationChanged{
    NSString *string = [self locationString];
    [self.updater updateLocation: string];
    self.indicatorLabel.text = string;
}

-(ARServerUpdater*)updater{
    if (!_updater) {
        _updater = [[ARServerUpdater alloc]initWithUsername:@"jgeller" password:@"12345"];
    }
    return _updater;
}

-(CLBeaconRegion*)bedroomRegion{
    if (!_bedroomRegion) {
        NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:JGBedroomBeaconUUID];
        _bedroomRegion = [[CLBeaconRegion alloc] initWithProximityUUID:uuid identifier:JGBedroomRegionIdentifier];
    }
    return _bedroomRegion;
}

-(CLCircularRegion*)caltechRegion{
    if (!_caltechRegion) {
        _caltechRegion = [[CLCircularRegion alloc]initWithCenter:CLLocationCoordinate2DMake(JGCaltechLatitude, JGCaltechLongitude) radius:JGCaltechRadiusMeters identifier:JGCaltechRegionIdentifier];
    }
    return _caltechRegion;
}
//
//-(void)addLocation:(NSObject<NSCopying> *)location withDescriptor:(NSString*)string{
//    [self.manager addLocation:location];
//    [self.locationStrings setObject:string forKey:location];
//    [[NSUserDefaults standardUserDefaults]setObject:[NSKeyedArchiver archivedDataWithRootObject:self.locationStrings] forKey:JGLocationStringsDictionaryKey];
//
//}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    UINavigationController *nav = segue.destinationViewController;
    if ([nav.viewControllers[0] isKindOfClass:[JGConfigureLocationViewController class]]) {
        JGConfigureLocationViewController *config = nav.viewControllers[0];
        config.delegate = self;
        config.manager = self.manager;
        config.locationStrings = self.locationStrings;
    }
}

-(BOOL)hidden{
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"shouldHide"];
}

-(void)hiddenChanged{
    [self locationChanged];
}

// TO DO: IMPLEMENT HASH FOR CUSTOM CLASSES

@end
