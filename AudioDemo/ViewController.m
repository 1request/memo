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
    
    BOOL fileExists;
    BOOL fileDownloaded;
}

@end

@implementation ViewController
@synthesize stopButton, playButton, recordPauseButton;

- (void)viewDidLoad
{
    [super viewDidLoad];
	
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
    
    NSUUID *proximityUUID = [[NSUUID alloc] initWithUUIDString:kUUID_Estimote];
    CLBeaconRegion *beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:proximityUUID major:1000 minor:2000 identifier:@"beacon"];
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
        [recordPauseButton setTitle:@"Pause" forState:UIControlStateNormal];

    } else {

        // Pause recording
        [recorder pause];
        [recordPauseButton setTitle:@"Record" forState:UIControlStateNormal];
    }

}

- (IBAction)stopTapped:(id)sender {
    [recorder stop];
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

- (void) audioRecorderDidFinishRecording:(AVAudioRecorder *)avrecorder successfully:(BOOL)flag{
    [recordPauseButton setTitle:@"Record" forState:UIControlStateNormal];
}

#pragma mark - AVAudioPlayerDelegate

- (void) audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag{
    NSLog(@"Finish playing");
}

#pragma mark - Parse

- (void)uploadAudio
{
    NSString *vendorId = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    
    PFObject *testObject = [PFObject objectWithClassName:@"Memo"];
    
    //get the audio in NSData format
    NSData *audioData = [NSData dataWithContentsOfURL:recorder.url];
    
    //create PFFile to store audio data
    PFFile *audioFile = [PFFile fileWithName:@"memo.m4a" data:audioData];
    testObject[@"audioFile"] = audioFile;
    testObject[@"deviceId"] = vendorId;
    
    self.statusLabel.text = @"Uploading...";
    
    //save
    [testObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            fileExists = YES;
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
        
        self.statusLabel.text = @"Playing";
    } else {
        self.statusLabel.text = @"No Memo";
    }
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
            
            //play audiofile streaming
            avPlayer = [[AVPlayer alloc] initWithURL:[NSURL URLWithString:filePath]];
            avPlayer.volume = 1.0f;
            
            [playButton setEnabled:YES];
            
            fileDownloaded = YES;
            
            self.statusLabel.text = @"Downloaded";
        } else {
            
            NSLog(@"error = %@", [error userInfo]);
        }
    }];
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
    
    if (fileExists && !fileDownloaded) {
        [self downloadAudio];
    }
    
    if (fileDownloaded) {
        [playButton setEnabled:YES];
    }
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLBeaconRegion *)region
{
    NSLog(@"Exited region: %@", region);
    
    self.locationLabel.text = @"Exited Region";
    
    [playButton setEnabled:NO];
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

@end
