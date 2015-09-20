//
//  ViewController.m
//  nRF UART
//
//  Created by Ole Morten on 1/11/13.
//  Copyright (c) 2013 Nordic Semiconductor. All rights reserved.
//

#import "ViewController.h"

typedef enum
{
    IDLE = 0,
    SCANNING,
    CONNECTED,
} ConnectionState;

@interface ViewController ()
@property CBCentralManager *cm;
@property ConnectionState state;
@property UARTPeripheral *currentPeripheral;
@end

@implementation ViewController
@synthesize cm = _cm;
@synthesize currentPeripheral = _currentPeripheral;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.cm = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [self.tableView setSeparatorColor:[UIColor clearColor]];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)connectButtonPressed:(id)sender
{
    switch (self.state) {
        case IDLE:
            self.state = SCANNING;
            
            NSLog(@"Started scan ...");
            [self.connectButton setTitle:@"Scanning ..." forState:UIControlStateNormal];
            
            [self.cm scanForPeripheralsWithServices:@[UARTPeripheral.uartServiceUUID] options:@{CBCentralManagerScanOptionAllowDuplicatesKey: [NSNumber numberWithBool:NO]}];
            break;
            
        case SCANNING:
            self.state = IDLE;

            NSLog(@"Stopped scan");
            [self.connectButton setTitle:@"Connect" forState:UIControlStateNormal];

            [self.cm stopScan];
            break;
            
        case CONNECTED:
            NSLog(@"Disconnect peripheral %@", self.currentPeripheral.peripheral.name);
            [self.cm cancelPeripheralConnection:self.currentPeripheral.peripheral];
            break;
    }
}

- (void) gloveConnected
{
    self.state = CONNECTED;
    [self.connectButton setTitle:@"Disconnect" forState:UIControlStateNormal];
    
}

- (void) startSession
{
    if (self.state != CONNECTED)
    {
        return;
    }
    
    StartSessionMessage startMsg;
    startMsg.header.msgID = START_SESSION;
    startMsg.header.time.major = 0;
    startMsg.header.time.minor = 0;
    startMsg.header.dataLength = 0;
    
    NSData *msgData = [NSData dataWithBytes:&startMsg length:sizeof(startMsg)];
    [self.currentPeripheral writeRawData:msgData];
}

- (void) endSession
{
    if (self.state != CONNECTED)
    {
        return;
    }
    
    EndSessionMessage startMsg;
    startMsg.header.msgID = END_SESSION;
    startMsg.header.time.major = 0;
    startMsg.header.time.minor = 0;
    startMsg.header.dataLength = 0;
    
    NSData *msgData = [NSData dataWithBytes:&startMsg length:sizeof(startMsg)];
    [self.currentPeripheral writeRawData:msgData];
}


- (void) didReceiveData:(NSData *)data
{
    MsgHeader_s header;
    [data getBytes:&header length:sizeof(MsgHeader_s)];

    switch(header.msgID)
    {
        case GLOVE_STATUS:
            [self processGloveStatus:header :data];
            break;
        case HIT_DATA:
            [self processHitData:header :data];
            break;
        default:
            break;
    }
}

- (void) processGloveStatus:(MsgHeader_s)header :(NSData*)data
{
    GloveStatusData_s gloveStatusData;
    [data getBytes:&gloveStatusData length:sizeof(gloveStatusData)];
    
    return;
}

- (void) processHitData:(MsgHeader_s)header :(NSData*)data
{
    HitData_s hitData;
    [data getBytes:&hitData length:sizeof(hitData)];
    
    return;
}


- (void) centralManagerDidUpdateState:(CBCentralManager *)central
{
    if (central.state == CBCentralManagerStatePoweredOn)
    {
        [self.connectButton setEnabled:TRUE];
    }
    else if (central.state == CBCentralManagerStatePoweredOff)
    {
        [self.connectButton setEnabled:FALSE];
    }
}

- (void) centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSLog(@"Did discover peripheral %@", peripheral.name);
    [self.cm stopScan];
    
    self.currentPeripheral = [[UARTPeripheral alloc] initWithPeripheral:peripheral delegate:self];
    
    [self.cm connectPeripheral:peripheral options:@{CBConnectPeripheralOptionNotifyOnDisconnectionKey: [NSNumber numberWithBool:YES]}];
}

- (void) centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"Did connect peripheral %@", peripheral.name);

    [self gloveConnected];
    
    if ([self.currentPeripheral.peripheral isEqual:peripheral])
    {
        [self.currentPeripheral didConnect];
    }
}

- (void) centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"Did disconnect peripheral %@", peripheral.name);

    self.state = IDLE;
    [self.connectButton setTitle:@"Connect" forState:UIControlStateNormal];

    if ([self.currentPeripheral.peripheral isEqual:peripheral])
    {
        [self.currentPeripheral didDisconnect];
    }
}
@end
