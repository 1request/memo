//
//  ViewController.h
//  AudioDemo
//
//  Created by Simon on 24/2/13.
//  Copyright (c) 2013 Appcoda. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreLocation/CoreLocation.h>
#import <REFrostedViewController/REFrostedViewController.h>

static NSString * const kUUID_Estimote = @"B9407F30-F5F8-466E-AFF9-25556B57FE6D";
static NSString * const kUUID_AirLocate = @"E2C56DB5-DFFB-48D2-B060-D0F5A71096E0";
static NSString * const kUUID_Radius = @"2F234454-CF6D-4A0F-ADF2-F4911BA9FFA6";

@interface ViewController : UIViewController <AVAudioRecorderDelegate, AVAudioPlayerDelegate, CLLocationManagerDelegate>

// Record and Play controls
@property (weak, nonatomic) IBOutlet UIButton *recordPauseButton;
@property (weak, nonatomic) IBOutlet UIButton *stopButton;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (nonatomic, strong) CLLocationManager *locationManager;

// About the user
@property (nonatomic, weak) IBOutlet UIImageView *maskImage;
@property (nonatomic, weak) IBOutlet UILabel *nameLabel;

// About Debugging messages
@property (weak, nonatomic) IBOutlet UIView *statusView;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UILabel *locationLabel;

- (IBAction)recordPauseTapped:(id)sender;
- (IBAction)stopTapped:(id)sender;
- (IBAction)playTapped:(id)sender;

- (IBAction)showMenu;
- (IBAction)showStatusView;

@end
