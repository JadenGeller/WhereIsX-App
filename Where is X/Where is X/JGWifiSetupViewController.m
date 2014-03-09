//
//  JGWifiSetupViewController.m
//  Where is X
//
//  Created by Jaden Geller on 2/27/14.
//  Copyright (c) 2014 Jaden Geller. All rights reserved.
//

#import "JGWifiSetupViewController.h"
#import "JGConfigureLocationViewController.h"
#import "JGWifiLocation.h"


@interface JGWifiSetupViewController ()

@property (nonatomic) JGBSSIDRanger *ranger;
@property (nonatomic, readonly) JGWifiLocation *location;
@property (nonatomic) CLLocationManager *manager;
@property (nonatomic) CLLocation *here;

@end

@implementation JGWifiSetupViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.addButton.enabled = NO;
    self.manager = [[CLLocationManager alloc]init];
    self.manager.delegate = self;
    [self.manager startUpdatingLocation];
    // Do any additional setup after loading the view.
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    if (locations.count){
        self.here = locations[0];
        
    }
    
}

-(JGBSSIDRanger*)ranger{
    if (!_ranger) {
        _ranger = [[JGBSSIDRanger alloc]init];
        _ranger.delegate = self;
        _ranger.record = YES;
    }
    return _ranger;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)recordPress:(id)sender {
    if (self.ranger.ranging) {
        self.recordButton.title = @"Record";
        self.ranger.ranging = NO;
    }
    else{
        self.recordButton.title = @"Pause";
        self.ranger.ranging = YES;
    }
}
- (IBAction)clearPress:(id)sender {
    if (self.ranger.ranging) [self recordPress:sender];
    [self.ranger clear];
    self.addButton.enabled = NO;
    [self.tableView reloadData];
}

-(void)foundNewBSSID:(NSString*)BSSID{
    self.addButton.enabled = YES;
    [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:[self.tableView numberOfRowsInSection:0] inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.ranger.BSSIDs.count;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"wifiCell"];
    cell.textLabel.text = [self.ranger.BSSIDs objectAtIndex:indexPath.row];
    //cell.textLabel.textAlignment = NSTextAlignmentCenter;
    return cell;
}

-(NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    return @"Found Routers";    
}

-(JGWifiLocation*)location{
    CLCircularRegion *circularRegion = [[CLCircularRegion alloc]initWithCenter:self.here.coordinate radius:1000 identifier:[[NSUUID UUID]UUIDString]];
    return [[JGWifiLocation alloc]initWithNetworkData:self.ranger.BSSIDs circularRegion:circularRegion];
}

- (IBAction)addPress:(id)sender {
    NSArray *viewcontrollers = self.navigationController.viewControllers;

    JGConfigureLocationViewController *main = viewcontrollers[0];
    
    [main addLocation:self.location withDescription:self.locationDescription];
    [self.navigationController popToViewController:main animated:YES];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
