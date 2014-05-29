//
//  MJViewController.m
//  AlertView
//
//  Created by Joan Martin on 29/05/14.
//  Copyright (c) 2014 Mobile Jazz. All rights reserved.
//

#import "MJViewController.h"

#import "MJAlertView.h"

@interface MJViewController ()

@end

@implementation MJViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        self.title = @"MJAlertViewManager";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)mjz_button1Action:(id)sender
{
    MJAlertView *alertView = [[MJAlertView alloc] initWithTitle:@"Welcome"
                                                       subtitle:@"This is a subtitle"
                                                        message:@"Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat."
                                              cancelButtonTitle:@"Dismiss"];
    
    [alertView show];
}

- (IBAction)mjz_button2Action:(id)sender
{
    {
        MJAlertView *alertView = [[MJAlertView alloc] initWithTitle:@"First AlertView"
                                                           subtitle:@"This is a subtitle"
                                                            message:@"Quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat."
                                                  cancelButtonTitle:@"Dismiss"];
        [alertView show];
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        MJAlertView *alertView = [[MJAlertView alloc] initWithTitle:@"Second AlertView"
                                                           subtitle:@"This is a subtitle"
                                                            message:@"Labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat."
                                                  cancelButtonTitle:@"Dismiss"];
        
        [alertView show];
    });
}

- (IBAction)mjz_button3Action:(id)sender
{
    {
        MJAlertView *alertView = [[MJAlertView alloc] initWithTitle:@"First AlertView"
                                                           subtitle:@"This is a subtitle"
                                                            message:@"Quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat."
                                                  cancelButtonTitle:@"Dismiss"];
        
        [alertView show];
    }
    
    {
        MJAlertView *alertView = [[MJAlertView alloc] initWithTitle:@"Second AlertView"
                                                           subtitle:@"This is a subtitle"
                                                            message:@"Labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat."
                                                  cancelButtonTitle:@"Dismiss"];
        
        [alertView show];
    }
}

@end
