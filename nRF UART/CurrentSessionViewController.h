//
//  ViewController.h
//  nRF UART
//
//  Created by Ole Morten on 1/11/13.
//  Copyright (c) 2013 Nordic Semiconductor. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "UARTPeripheral.h"
#import "Messages.h"

@interface CurrentSessionViewController : UITableViewController <UITextFieldDelegate, CBCentralManagerDelegate, UARTPeripheralDelegate>
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *connectButton;
@property (weak, nonatomic) IBOutlet UITextView *consoleTextView;
@property (weak, nonatomic) IBOutlet UITextField *sendTextField;
@property (weak, nonatomic) IBOutlet UIButton *sendButton;

- (void) processGloveStatus: (MsgHeader_s)header : (NSData*)data;
- (void) processHitData: (MsgHeader_s)header : (NSData*)data;

- (IBAction)connectButtonPressed:(id)sender;
- (IBAction)sendButtonPressed:(id)sender;
- (void)gloveConnected;
@end
