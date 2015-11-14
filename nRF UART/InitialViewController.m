//
//  InitialViewController.m
//  HitSmart
//
//  Created by PatrickShickel on 11/13/15.
//  Copyright © 2015 Nordic Semiconductor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "InitialViewController.h"
#import <ParseFacebookUtilsV4/PFFacebookUtils.h>

@implementation InitialViewController

- (void)viewDidAppear:(BOOL)animated {
    if ([PFUser currentUser] || // Check if user is cached
        [PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) { // Check if user is linked to Facebook
        NSLog(@"user cached");
        [self performSegueWithIdentifier:@"UserCached" sender:self];
    }
    else{
        [self performSegueWithIdentifier:@"UserNotCached" sender:self];
    }
}

@end