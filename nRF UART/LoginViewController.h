//
//  LoginViewController.h
//  HitSmart
//
//  Created by PatrickShickel on 11/12/15.
//  Copyright © 2015 Nordic Semiconductor. All rights reserved.
//

#ifndef LoginViewController_h
#define LoginViewController_h

@interface LoginViewController : UIViewController

@property (nonatomic, strong) IBOutlet UIButton *btnLogin;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityLogin;

@property (nonatomic, strong) IBOutlet UITextField *signupEmailField;
@property (nonatomic, strong) IBOutlet UITextField *signupPasswordField;
@property (nonatomic, strong) IBOutlet UITextField *signupPasswordConfirmField;
@property (nonatomic, strong) IBOutlet UIButton *signupBtnSubmit;
@property (nonatomic, strong) IBOutlet UIButton *signupBtnCancel;

@property (nonatomic, strong) IBOutlet UITextField *loginEmailField;
@property (nonatomic, strong) IBOutlet UITextField *loginPasswordField;
@property (nonatomic, strong) IBOutlet UIButton *loginBtnSubmit;
@property (nonatomic, strong) IBOutlet UIButton *loginBtnCancel;

@end

#endif /* LoginViewController_h */
