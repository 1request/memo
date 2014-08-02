//
//  NameViewController.h
//  AudioDemo
//
//  Created by Harry Ng on 31/7/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NameViewController : UIViewController

@property (nonatomic, weak) IBOutlet UITextField *nameField;

- (IBAction)close:(id)sender;

@end
