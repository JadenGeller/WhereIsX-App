//
//  JGViewController.h
//  Where is X
//
//  Created by Jaden Geller on 2/25/14.
//  Copyright (c) 2014 Jaden Geller. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JGLocationManager.h"
#import "JGConfigureLocationViewController.h"

extern NSString * const JGLocationStringsDictionaryKey;

@interface JGViewController : UIViewController <JGLocationManagerDelegate, JGConfigureLocationProtocol>

@property (weak, nonatomic) IBOutlet UILabel *indicatorLabel;
-(BOOL)hidden;
-(void)hiddenChanged;

@end
