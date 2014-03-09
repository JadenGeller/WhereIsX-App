//
//  JGConfigureLocationViewController.m
//  Where is X
//
//  Created by Jaden Geller on 2/27/14.
//  Copyright (c) 2014 Jaden Geller. All rights reserved.
//

#import "JGConfigureLocationViewController.h"
#import "JGLocationManager.h"
#import "JGViewController.h"

@interface JGConfigureLocationViewController ()

@property (nonatomic) BOOL hidden;

@end

@implementation JGConfigureLocationViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.editing = YES;
    [self setHiddenButtonStyle:self.hidden];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

-(BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath{
    return YES;
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    return YES;
}

-(void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath{
    [self.manager moveLocationAtIndex:sourceIndexPath.row toIndex:destinationIndexPath.row];
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.manager removeLocationAtIndex:indexPath.row];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)donePress:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.manager.locations.count;
}

-(void)addLocation:(NSObject<NSCopying>*)location withDescription:(NSString*)description{
    [self.manager addLocation:location];
    [self.locationStrings setObject:description forKey:location];
    [[NSUserDefaults standardUserDefaults]setObject:[NSKeyedArchiver archivedDataWithRootObject:self.locationStrings] forKey:JGLocationStringsDictionaryKey];
    
    [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.manager.locations.count-1 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"locationCell" forIndexPath:indexPath];
    
    cell.textLabel.text = [self.locationStrings objectForKey:[self.manager.locations objectAtIndex:indexPath.row]];
    // Configure the cell...
    
    return cell;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
-(BOOL)hidden{
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"shouldHide"];
}

-(void)setHidden:(BOOL)hidden{
    [[NSUserDefaults standardUserDefaults] setBool:hidden forKey:@"shouldHide"];
    [self.delegate hiddenChanged];

}

-(void)setHiddenButtonStyle:(BOOL)hidden{
    if (hidden) {
        self.hiddenButton.title = @"Hidden";
        self.hiddenButton.tintColor = [UIColor redColor];
        self.hiddenButton.style = UIBarButtonItemStyleDone;
    }
    else {
        self.hiddenButton.title = @"Not Hidden";
        self.hiddenButton.tintColor = self.settingsButton.tintColor;
        self.hiddenButton.style = UIBarButtonItemStylePlain;
    }
}

- (IBAction)hiddenPress:(id)sender {
    BOOL hidden = !self.hidden;
    self.hidden = hidden;
    [self setHiddenButtonStyle:hidden];
}

@end
