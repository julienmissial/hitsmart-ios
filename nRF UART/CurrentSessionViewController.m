//
//  ViewController.m
//  nRF UART
//
//  Created by Ole Morten on 1/11/13.
//  Copyright (c) 2013 Nordic Semiconductor. All rights reserved.
//

#import "CurrentSessionViewController.h"

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]
#define SCREEN_HEIGHT self.view.frame.size.height
#define SCREEN_WIDTH self.view.frame.size.width

typedef enum
{
    IDLE = 0,
    SCANNING,
    CONNECTED,
} ConnectionState;

@interface CurrentSessionViewController (){
    UILabel * time;
    UILabel * punchesLabelTitle;
    UILabel * punchesLabel;
    UILabel * forceLabelTitle;
    UILabel * force;
    UILabel * caloriesTitle;
    UILabel * calories;
    
    UIButton * startStop;
    UIButton * resetButton;
    NSTimer * stopTimer;
    NSDate * startDate;
    BOOL running;
}

@property CBCentralManager *cm;
@property ConnectionState state;
@property UARTPeripheral *currentPeripheral;
@end

@implementation CurrentSessionViewController
@synthesize cm = _cm;
@synthesize currentPeripheral = _currentPeripheral;

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setNeedsStatusBarAppearanceUpdate];
	// Do any additional setup after loading the view, typically from a nib.
    self.cm = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [self.tableView setSeparatorColor:[UIColor clearColor]];
    
    [self loadInterface];
    
}-(void)loadInterface{
    
#pragma mark - main interface
    self.title = @"CURRENT SESSION";
    self.navigationController.navigationBar.topItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    self.view.backgroundColor = UIColorFromRGB(0x262626);
    
    [self.navigationController.navigationBar setTintColor:UIColorFromRGB(0xF6320B)];
    UIImageView * logo_transparent = [[UIImageView alloc]initWithFrame:CGRectMake(SCREEN_WIDTH/2 - 114.5, SCREEN_HEIGHT/2 - 53, 229, 106)];
    logo_transparent.image = [UIImage imageNamed:@"logo_transparent.png"];
    
    [self.view addSubview:logo_transparent];
    
#pragma mark - shareButton
    /* self.navigationController.navigationBar.topItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:nil action:nil];*/
#pragma mark - timer
    time = [[UILabel alloc]init];
    time.text = @"00.00.000";
    time.textColor = UIColorFromRGB(0xFFFFFF);
    [time setFont:[UIFont fontWithName:@"Futura-CondensedExtraBold" size:60.0]];
    [time sizeToFit];
    time.center = CGPointMake(SCREEN_WIDTH/2, SCREEN_HEIGHT/2 - 200);
    [self.view addSubview:time];
    running = FALSE;
    
#pragma mark - stopTimerButton
    startStop = [UIButton buttonWithType:UIButtonTypeSystem];
    [self formatTheButtonMyWay:startStop withText:@"START"];
    startStop.frame = CGRectMake(0, 0, 125, 125);
    startStop.layer.cornerRadius = 62.5;
    startStop.center = CGPointMake(SCREEN_WIDTH/2, SCREEN_HEIGHT/2 - 100);
    [startStop addTarget:self action:@selector(startStopTimer) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:startStop];
    
#pragma mark - resetTimerButton
    resetButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self formatTheButtonMyWay:resetButton withText:@"RESET"];
    
    resetButton.frame = CGRectMake(0, 0, 75, 75);
    resetButton.layer.cornerRadius = 37.5;
    resetButton.center = CGPointMake(SCREEN_WIDTH/2, SCREEN_HEIGHT/2 + 10);
    [resetButton addTarget:self action:@selector(resetPressed) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:resetButton];
#pragma mark - startDate
    startDate = [NSDate date];
    
#pragma TODO - Labels
    punchesLabel = [[UILabel alloc]init];
    punchesLabel.text = self.consoleTextView.text;
    punchesLabel.textColor = UIColorFromRGB(0xFFFFFF);
    [punchesLabel sizeToFit];
    [punchesLabel setFont:[UIFont fontWithName:@"Futura-CondensedExtraBold" size:20.0]];
    punchesLabel.center = CGPointMake(SCREEN_WIDTH/2, SCREEN_HEIGHT/2 + 80);
    [punchesLabel sizeToFit];
    
    [self.view addSubview:punchesLabel];
    
#pragma TODO - Force
    force = [[UILabel alloc]init];
    //force.text = @"Average Force: 3297 N     ";
    force.textColor = UIColorFromRGB(0xFFFFFF);
    [force sizeToFit];
    [force setFont:[UIFont fontWithName:@"Futura-CondensedExtraBold" size:20.0]];
    force.center = CGPointMake(SCREEN_WIDTH/2, SCREEN_HEIGHT/2 + 105);
    [force sizeToFit];
    
    [self.view addSubview:force];
    
}

- (void)formatTheButtonMyWay:(UIButton *)b withText:(NSString *)text{
    [b setTitle:text forState:UIControlStateNormal];
    [b.titleLabel setFont:[UIFont fontWithName:@"Futura-CondensedExtraBold" size:24.0]];
    b.tintColor = UIColorFromRGB(0xFFFFFF);
    b.backgroundColor = UIColorFromRGB(0xF6320B);
    
}

-(void)startStopTimer{
    if(!running){
        running = TRUE;
        [startStop setTitle:@"STOP" forState:UIControlStateNormal];
        
        if(stopTimer == nil) stopTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/10.0 target:self selector:@selector(updateTimer) userInfo:nil repeats:YES];
    }else{
        running = FALSE;
        [startStop setTitle:@"START" forState:UIControlStateNormal];
        [stopTimer invalidate];
        stopTimer = nil;
    }
    
}

-(void)updateTimer{
    NSDate * currentDate = [NSDate date];
    NSTimeInterval timeInterval = [currentDate timeIntervalSinceDate:startDate];
    NSDateFormatter * d = [[NSDateFormatter alloc]init];
    [d setDateFormat:@"mm:ss.SSS"];
    [d setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0.0]];
    time.text = [d stringFromDate:[NSDate dateWithTimeIntervalSince1970:timeInterval]];
}

-(void)resetPressed{
    [stopTimer invalidate];
    stopTimer = nil;
    startDate = [NSDate date];
    time.text = @"00:00.000";
    running = FALSE;
    
    [startStop setTitle:@"START" forState:UIControlStateNormal];
    
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

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}
@end
