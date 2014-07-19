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

@interface ViewController : UIViewController <AVAudioRecorderDelegate, AVAudioPlayerDelegate, CLLocationManagerDelegate>

@property (weak, nonatomic) IBOutlet UIButton *recordPauseButton;
@property (weak, nonatomic) IBOutlet UIButton *stopButton;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (weak, nonatomic) IBOutlet UIView *statusView;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UILabel *locationLabel;

- (IBAction)recordPauseTapped:(id)sender;
- (IBAction)stopTapped:(id)sender;
- (IBAction)playTapped:(id)sender;

- (IBAction)showMenu;
- (IBAction)showStatusView;

@end
