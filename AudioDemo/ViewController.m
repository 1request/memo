//
//  ViewController.m
//  AudioDemo
//
//  Created by Simon on 24/2/13.
//  Copyright (c) 2013 Appcoda. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () {
    AVAudioRecorder *recorder;
    AVAudioPlayer *player;
    
    BOOL fileExists;
}

@end

@implementation ViewController
@synthesize stopButton, playButton, recordPauseButton;

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    // Disable Stop/Play button when application launches
    [playButton setEnabled:NO];
    
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
    fileExists = YES;
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setActive:NO error:nil];
}

- (IBAction)playTapped:(id)sender {
    if (!recorder.recording){
        player = [[AVAudioPlayer alloc] initWithContentsOfURL:recorder.url error:nil];
        [player setDelegate:self];
        [player play];
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
    
    self.statusLabel.text = @"Entered Region";
    
    if (fileExists) {
        [playButton setEnabled:YES];
    }
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLBeaconRegion *)region
{
    NSLog(@"Exited region: %@", region);
    
    self.statusLabel.text = @"Exited Region";
    
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
