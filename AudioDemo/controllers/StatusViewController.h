//
//  StatusViewController.h
//  AudioDemo
//
//  Created by Harry Ng on 18/7/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <REFrostedViewController/REFrostedViewController.h>

@interface StatusViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UILabel *locationLabel;

- (IBAction)showMenu;

@end
