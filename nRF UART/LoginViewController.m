//
//  LoginViewController.m
//  HitSmart
//
//  Created by PatrickShickel on 11/12/15.
//  Copyright © 2015 Nordic Semiconductor. All rights reserved.
//

#import <Parse/Parse.h>
#import "LoginViewController.h"
#import <ParseFacebookUtilsV4/PFFacebookUtils.h>
#import "CurrentSessionViewController.h"
#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]
#define SCREEN_HEIGHT self.view.frame.size.height
#define SCREEN_WIDTH self.view.frame.size.width

@interface LoginViewController(){
    BOOL buttonWasClicked;
    UIImageView * logo;
}
@end
@implementation LoginViewController

@synthesize btnLogin;
@synthesize activityLogin;

@synthesize signupEmailField;
@synthesize signupPasswordField;
@synthesize signupPasswordConfirmField;
@synthesize signupBtnSubmit;
@synthesize signupBtnCancel;

@synthesize loginEmailField;
@synthesize loginPasswordField;
@synthesize loginBtnSubmit;
@synthesize loginBtnCancel;

- (void) viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = UIColorFromRGB(0x262626);
    /*
    logo = [[UIImageView alloc]initWithFrame:CGRectMake(SCREEN_WIDTH/2 - 114.5,10, 229, 106)];
    logo.image = [UIImage imageNamed:@"logo_noblack.png"];
    [self.view addSubview:logo];*/ 

}

// Outlet for FBLogin button
- (IBAction) fbLoginPressed:(id)sender
{
    // Disable the Login button to prevent multiple touches

    [btnLogin setEnabled:NO];
    
    // Show an activity indicator
    [activityLogin startAnimating];

    NSArray *permissionsArray = @[];
    [PFFacebookUtils logInInBackgroundWithReadPermissions:permissionsArray block:^(PFUser *user, NSError *error) {
        if (user){
            if (user.isNew) {
                NSLog(@"User signed up and logged in through Facebook");
            }
            else {
                NSLog(@"User logged in through Facebook");
            }
            [self performSegueWithIdentifier:@"LoginSuccessful" sender:self];
        }
        else {
            if (error) {
                NSLog(@"An error occurred: %@", error.localizedDescription);
            }
            else {
                NSLog(@"The user cancelled the Facebook login.");
            }
            [[[UIAlertView alloc] initWithTitle:@"Login Failed"
                                        message:@"Facebook Login failed. Please try again"
                                       delegate:nil
                              cancelButtonTitle:@"Ok"
                              otherButtonTitles:nil] show];
        }
    }];
}

- (IBAction) emailSignupPressed:(id)sender {

    [self performSegueWithIdentifier:@"SignupWithEmail" sender:self];
}

- (IBAction) emailLoginPressed:(id)sender {

    [self performSegueWithIdentifier:@"LoginWithEmail" sender:self];
}

- (IBAction) emailSignupSubmitPressed:(id)sender {
    [logo removeFromSuperview];
    [signupBtnSubmit setEnabled:NO];
    
    NSString *password = [signupPasswordField text];
    NSString *passwordConfirm = [signupPasswordConfirmField text];
    
    if (password != passwordConfirm) {
        [[[UIAlertView alloc] initWithTitle:@"Signup Failed"
                                    message:@"Passwords do not match"
                                   delegate:nil
                          cancelButtonTitle:@"Ok"
                          otherButtonTitles:nil] show];
        [signupBtnSubmit setEnabled:YES];
        return;
    }
    
    PFUser *user = [PFUser user];
    user.email = [signupEmailField text];
    user.username = user.email;
    user.password = password;
    
    [user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error) {
            NSLog(@"User signed up with email");
            [self performSegueWithIdentifier:@"SignupSuccessful" sender:self];
        }
        else {
            NSString *errorString = [error userInfo][@"error"];
            [[[UIAlertView alloc] initWithTitle:@"Signup Failed"
                                        message:errorString
                                       delegate:nil
                              cancelButtonTitle:@"Ok"
                              otherButtonTitles:nil] show];
            [self performSegueWithIdentifier:@"SignupFailed" sender:self];
        }
    }];
    [signupBtnSubmit setEnabled:YES];
}

- (IBAction) emailLoginSubmitPressed:(id)sender {
    [logo removeFromSuperview];
    NSString *email = [loginEmailField text];
    NSString *password = [loginPasswordField text];
    
    [PFUser logInWithUsernameInBackground:email password:password
                                    block:^(PFUser *user, NSError *error) {
        if (user) {
            NSLog(@"User logged in with email");
            [self performSegueWithIdentifier:@"LoginSuccessful" sender:self];
        }
        else {
            if (error) {
                NSLog(@"An error occurred: %@", error.localizedDescription);
            }
            else {
                NSLog(@"Login error");
            }
            [[[UIAlertView alloc] initWithTitle:@"Login Failed"
                                        message:@"Login failed. Please try again"
                                       delegate:nil
                              cancelButtonTitle:@"Ok"
                              otherButtonTitles:nil] show];
        }
    }];
}

- (IBAction) emailSignupCancelPressed:(id)sender {
    [self performSegueWithIdentifier:@"SignupFailed" sender:self];
}

- (IBAction) emailLoginCancelPressed:(id)sender {
    [self performSegueWithIdentifier:@"LoginUnsuccessful" sender:self];
}


-(BOOL)prefersStatusBarHidden{
    return YES;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{

    [signupEmailField resignFirstResponder];
    [signupPasswordField resignFirstResponder];
    [signupPasswordConfirmField resignFirstResponder];
    
    [loginEmailField resignFirstResponder];
    [loginPasswordField resignFirstResponder];
    
}

@end