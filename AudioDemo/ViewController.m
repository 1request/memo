//
//  ViewController.m
//  AudioDemo
//
//  Created by Simon on 24/2/13.
//  Copyright (c) 2013 Appcoda. All rights reserved.
//

#include "TargetConditionals.h"

#import "ViewController.h"
#import <Parse/Parse.h>

@interface ViewController () {
    AVAudioRecorder *recorder;
    AVAudioPlayer *player;
    
    AVPlayer *avPlayer;
    
    BOOL fileDownloaded;
    NSTimer *playTimer;
}

@end

@implementation ViewController
@synthesize stopButton, playButton, recordPauseButton;
@synthesize nameLabel;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Show another view controller
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"username"] == nil) {
        UIViewController *nameViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"nameController"];
        [self presentViewController:nameViewController animated:YES completion:nil];
    } else {
        nameLabel.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"username"];
    }
	
    // Disable Stop/Play button when application launches
#if !(TARGET_IPHONE_SIMULATOR)
    [playButton setEnabled:NO];
#else
    [self downloadAudio];
#endif
    
    // Set the audio file
    NSArray *pathComponents = [NSArray arrayWithObjects:
                               [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject],
                               @"MyAudioMemo.m4a",
                               nil];
    NSURL *outputFileURL = [NSURL fileURLWithPathComponents:pathComponents];

    // Setup audio session
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    
    NSError *error;
    [session overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&error];

    // Define the recorder setting
    NSMutableDictionary *recordSetting = [[NSMutableDictionary alloc] init];
    
    [recordSetting setValue:[NSNumber numberWithInt:kAudioFormatMPEG4AAC] forKey:AVFormatIDKey];
    [recordSetting setValue:[NSNumber numberWithFloat:44100.0] forKey:AVSampleRateKey];
    [recordSetting setValue:[NSNumber numberWithInt: 2] forKey:AVNumberOfChannelsKey];
    
    // Initiate and prepare the recorder
    recorder = [[AVAudioRecorder alloc] initWithURL:outputFileURL settings:recordSetting error:nil];
    recorder.delegate = self;
    recorder.meteringEnabled = YES;
    [recorder prepareToRecord];
    
    // Beacon
    if (!self.locationManager) {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
    }
    
    if (![CLLocationManager isMonitoringAvailableForClass:[CLBeaconRegion class]]) {
        NSLog(@"Couldn't turn on region monitoring: Region monitoring is not available for CLBeaconRegion class.");
        return;
    }
    
    if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
        [self.locationManager requestAlwaysAuthorization];
    }
    
    NSUUID *proximityUUID = [[NSUUID alloc] initWithUUIDString:kUUID_AirLocate];
    CLBeaconRegion *beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:proximityUUID major:100 minor:5 identifier:@"beacon"];
    beaconRegion.notifyEntryStateOnDisplay = YES;
    beaconRegion.notifyOnEntry = YES;
    beaconRegion.notifyOnExit = YES;
    
    [self.locationManager startRangingBeaconsInRegion:beaconRegion];
    [self.locationManager startMonitoringForRegion:beaconRegion];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)recordPauseTapped:(id)sender {
    // Stop the audio player before recording
    if (player.playing) {
        [player stop];
    }
    
    if (!recorder.recording) {
        AVAudioSession *session = [AVAudioSession sharedInstance];
        [session setActive:YES error:nil];
        
        // Start recording
        [recorder record];
        
        self.statusLabel.text = @"Recording...";
        self.maskImage.hidden = NO;

    } else {

        // Pause recording
        [recorder pause];
        
        self.statusLabel.text = @"Record Pause";
        
    }

}

- (IBAction)stopTapped:(id)sender {
    [recorder stop];
    self.maskImage.hidden = YES;
    
    [self uploadAudio];
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setActive:NO error:nil];
}

- (IBAction)playTapped:(id)sender {
    if (!recorder.recording) {
        // Play audio just recorded
//        player = [[AVAudioPlayer alloc] initWithContentsOfURL:recorder.url error:nil];
//        [player setDelegate:self];
//        [player play];
        
        // Play audio downloaded from Parse
        [self playAudio];
    }
}

#pragma mark - AVAudioRecorderDelegate

- (void) audioRecorderDidFinishRecording:(AVAudioRecorder *)avrecorder successfully:(BOOL)flag
{
    self.statusLabel.text = @"Recorded";
    NSLog(@"Finish recording");
}

#pragma mark - AVAudioPlayerDelegate

- (void) audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    self.statusLabel.text = @"Played";
    NSLog(@"Finish playing");
    
    PFPush *push = [[PFPush alloc] init];
    [push setChannel:@"all"];
    [push setMessage:@"Your message is read"];
    [push sendPushInBackground];
}

#pragma mark - Parse

- (void)uploadAudio
{
    self.statusLabel.text = @"Uploading...";
    
    NSString *vendorId = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    
    PFObject *testObject = [PFObject objectWithClassName:@"Memo"];
    
    //get the audio in NSData format
    NSData *audioData = [NSData dataWithContentsOfURL:recorder.url];
    
    //create PFFile to store audio data
    PFFile *audioFile = [PFFile fileWithName:@"memo.m4a" data:audioData];
    testObject[@"audioFile"] = audioFile;
    testObject[@"deviceId"] = vendorId;
    
    //save
    [testObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            self.statusLabel.text = @"Uploaded";
        }
    }];
}

- (void)playAudio
{
    if (avPlayer != nil) {
        [avPlayer seekToTime:kCMTimeZero];
        [avPlayer play];
        avPlayer.actionAtItemEnd = AVPlayerActionAtItemEndNone;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playerItemDidReachEnd:)
                                                     name:AVPlayerItemDidPlayToEndTimeNotification
                                                   object:[avPlayer currentItem]];
        
        self.statusLabel.text = @"Playing";
        self.maskImage.hidden = NO;
    } else {
        self.statusLabel.text = @"Player not ready";
    }
}

- (void)playerItemDidReachEnd:(NSNotification *)notification
{
    self.statusLabel.text = @"Play Finished";
    self.maskImage.hidden = YES;
}

- (void)downloadAudio
{
    self.statusLabel.text = @"Downloading...";
    
    PFQuery *query = [PFQuery queryWithClassName:@"Memo"];
    [query whereKeyExists:@"audioFile"];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error)
        {
            PFObject *testObject = [objects lastObject];
            PFFile *audioFile = testObject[@"audioFile"];
            NSString *filePath = [audioFile url];
            
            // No record / No audio file
            if (filePath == nil) {
                self.statusLabel.text = @"No Memo";
                return;
            }
            
            // Do nothing if current memo is the same as the most updated one on server
            if (fileDownloaded) {
                NSString *memoId = [[NSUserDefaults standardUserDefaults] objectForKey:@"memoId"];
                if (memoId != nil && memoId == [testObject objectId]) {
                    return;
                }
            }
            
            //play audiofile streaming
            avPlayer = [[AVPlayer alloc] initWithURL:[NSURL URLWithString:filePath]];
            avPlayer.volume = 1.0f;
            
            [playButton setEnabled:YES];
            
            fileDownloaded = YES;
            playTimer = [NSTimer scheduledTimerWithTimeInterval:60 * 1000 target:self selector:@selector(timeout) userInfo:nil repeats:NO];
            
            self.statusLabel.text = @"Downloaded";
        } else {
            
            NSLog(@"error = %@", [error userInfo]);
        }
    }];
}

- (void)timeout
{
    [playTimer invalidate];
    playTimer = nil;
    [playButton setEnabled:NO];
    self.locationLabel.text = @"Region Timeout";
}

#pragma mark - Beacon

#pragma mark - Location manager delegate methods
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (![CLLocationManager locationServicesEnabled]) {
        NSLog(@"Couldn't turn on monitoring: Location services are not enabled.");
        return;
    }
    
    if ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorized) {
        NSLog(@"Couldn't turn on monitoring: Location services not authorised.");
    }
    
    if ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorizedAlways) {
        NSLog(@"Couldn't turn on monitoring: Location services (Always) not authorised.");
        return;
    }
    
}

- (void)locationManager:(CLLocationManager *)manager
        didRangeBeacons:(NSArray *)beacons
               inRegion:(CLBeaconRegion *)region {
    
    NSLog(@"%s Range region: %@ with beacons %@",__PRETTY_FUNCTION__ ,region , beacons);
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLBeaconRegion *)region
{
    NSLog(@"Entered region: %@", region);
    
    self.locationLabel.text = @"Entered Region";
    
    [self downloadAudio];
    
    [self sendLocalNotificationWithMessage:@"You have a new Memo"];
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLBeaconRegion *)region
{
    NSLog(@"Exited region: %@", region);
    
    self.locationLabel.text = @"Exited Region";
    
    if (playTimer == nil) {
        [playButton setEnabled:NO];
    }
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    NSString *stateString = nil;
    switch (state) {
        case CLRegionStateInside:
            stateString = @"inside";
            break;
        case CLRegionStateOutside:
            stateString = @"outside";
            break;
        case CLRegionStateUnknown:
            stateString = @"unknown";
            break;
    }
    NSLog(@"State changed to %@ for region %@.", stateString, region);
    
    
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error
{
    NSString *message = [NSString stringWithFormat:@"error: %@ / region: %@", [error description], region.minor];
    NSLog(@"%@", message);
}

#pragma mark - Local notifications

- (void)sendLocalNotificationWithMessage:(NSString*)message
{
    UILocalNotification *notification = [UILocalNotification new];
    
    // Notification details
    notification.alertBody = message;
    // notification.alertBody = [NSString stringWithFormat:@"Entered beacon region for UUID: %@",
    //                         region.proximityUUID.UUIDString];   // Major and minor are not available at the monitoring stage
    notification.alertAction = NSLocalizedString(@"View Details", nil);
    notification.soundName = UILocalNotificationDefaultSoundName;
    
    if ([notification respondsToSelector:@selector(regionTriggersOnce)]) {
        notification.regionTriggersOnce = YES;
    }
    
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        UIUserNotificationType types = UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
        UIUserNotificationSettings *mySettings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:mySettings];
    }
    
    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
}

- (IBAction)showMenu
{
    // Dismiss keyboard (optional)
    //
    [self.view endEditing:YES];
    [self.frostedViewController.view endEditing:YES];
    
    // Present the view controller
    //
    [self.frostedViewController presentMenuViewController];
}

- (IBAction)showStatusView
{
    self.statusView.hidden = !self.statusView.hidden;
}

@end
