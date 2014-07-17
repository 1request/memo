//
//  DEMORootViewController.m
//  AudioDemo
//
//  Created by Harry Ng on 18/7/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import "DEMORootViewController.h"

@interface DEMORootViewController ()

@end

@implementation DEMORootViewController

- (void)awakeFromNib
{
    self.contentViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"contentController"];
    self.menuViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"menuController"];
}

@end
