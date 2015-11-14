//
//  ViewController.m
//  nRF UART
//
//  Created by Ole Morten on 1/11/13.
//  Copyright (c) 2013 Nordic Semiconductor. All rights reserved.
//

#import "CurrentSessionViewController.h"
#import <Parse/Parse.h>

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]
#define SCREEN_HEIGHT self.view.frame.size.height
#define SCREEN_WIDTH self.view.frame.size.width
typedef enum
{
    IDLE = 0,
    SCANNING,
    CONNECTED,
} ConnectionState;

typedef enum
{
    LOGGING,
    RX,
    TX,
} ConsoleDataType;

@interface CurrentSessionViewController (){
    int punches;
    float force;
    float totalForce;
    UILabel * time;
    UILabel * punchesLabelTitle;
    UILabel * punchesLabel;
    UILabel * forceLabelTitle;
    UILabel * forceLabel;
    UILabel * averageForceLabel;
    UILabel * averageForceLabelTitle;
    UIButton * startStop;
    UIButton * resetButton;
    UIButton * logoutButton;
    NSTimer * stopTimer;
    NSDate * startDate;
    NSDate * pauseDate;
    BOOL running;
    BOOL paused;
}

@property CBCentralManager *cm;
@property ConnectionState state;
@property UARTPeripheral *currentPeripheral;
@end

@implementation CurrentSessionViewController
@synthesize cm = _cm;
@synthesize currentPeripheral = _currentPeripheral;
@synthesize consoleTextView;

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setNeedsStatusBarAppearanceUpdate];
    // Do any additional setup after loading the view, typically from a nib.
    self.cm = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    
    //[self addTextToConsole:@"Did start application" dataType:LOGGING];
    running = false;
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [self.tableView setSeparatorColor:[UIColor clearColor]];
    consoleTextView.textColor = UIColorFromRGB(0xFFFFFF);
    
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
    running = false;
    time = [[UILabel alloc]init];
    time.text = @"00:00.000";
    time.textColor = UIColorFromRGB(0xFFFFFF);
    [time setFont:[UIFont fontWithName:@"Futura-CondensedExtraBold" size:60.0]];
    [time sizeToFit];
    time.center = CGPointMake(SCREEN_WIDTH/2, SCREEN_HEIGHT/2 - 200);
    [self.view addSubview:time];
    paused = false;
    
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
    
#pragma mark - PunchesTitle
    punchesLabelTitle = [[UILabel alloc]init];
    punchesLabelTitle.text = @"PUNCHES";
    punchesLabelTitle.textColor = UIColorFromRGB(0xFFFFFF);
    [punchesLabelTitle sizeToFit];
    [punchesLabelTitle setFont:[UIFont fontWithName:@"Futura-CondensedExtraBold" size:20.0]];
    punchesLabelTitle.center = CGPointMake(SCREEN_WIDTH/4, SCREEN_HEIGHT/2.2 + 80);
    [punchesLabelTitle sizeToFit];
    [self.view addSubview:punchesLabelTitle];
    
#pragma mark - PunchesNumber
    punches = 0;
    punchesLabel = [[UILabel alloc]init];
    punchesLabel.text = [NSString stringWithFormat:@"%i", punches];
    punchesLabel.textColor = UIColorFromRGB(0xFFFFFF);
    [punchesLabel sizeToFit];
    [punchesLabel setFont:[UIFont fontWithName:@"Futura-CondensedExtraBold" size:20.0]];
    punchesLabel.center = CGPointMake(SCREEN_WIDTH/4, SCREEN_HEIGHT/2.4 + 80);
    [punchesLabel sizeToFit];
    [self.view addSubview:punchesLabel];
    
#pragma mark - ForceTitle
    forceLabelTitle = [[UILabel alloc]init];
    forceLabelTitle.text = @"FORCE (N)";
    forceLabelTitle.textColor = UIColorFromRGB(0xFFFFFF);
    [forceLabelTitle sizeToFit];
    [forceLabelTitle setFont:[UIFont fontWithName:@"Futura-CondensedExtraBold" size:20.0]];
    forceLabelTitle.center = CGPointMake(SCREEN_WIDTH/1.3, SCREEN_HEIGHT/2.4 + 105);
    [forceLabelTitle sizeToFit];
    
    [self.view addSubview:forceLabelTitle];
    
#pragma mark - ForceNumber
    force = 0.00;
    forceLabel = [[UILabel alloc]init];
    forceLabel.text = [NSString stringWithFormat:@"%.2f", force];
    forceLabel.textColor = UIColorFromRGB(0xFFFFFF);
    [forceLabel sizeToFit];
    [forceLabel setFont:[UIFont fontWithName:@"Futura-CondensedExtraBold" size:20.0]];
    forceLabel.center = CGPointMake(SCREEN_WIDTH/1.3, SCREEN_HEIGHT/2.6 + 105);
    [forceLabel sizeToFit];
    
    [self.view addSubview:forceLabel];
    
#pragma mark - AverageForceTitle
    averageForceLabelTitle = [[UILabel alloc]init];
    averageForceLabelTitle.text = @"AVERAGE FORCE (N)";
    averageForceLabelTitle.textColor = UIColorFromRGB(0xFFFFFF);
    [averageForceLabelTitle sizeToFit];
    [averageForceLabelTitle setFont:[UIFont fontWithName:@"Futura-CondensedExtraBold" size:20.0]];
    averageForceLabelTitle.center = CGPointMake(SCREEN_WIDTH/2, SCREEN_HEIGHT/1.8 + 80);
    [averageForceLabelTitle sizeToFit];
    
    [self.view addSubview:averageForceLabelTitle];
    
#pragma mark - AverageForceNumber
    totalForce = 0.00;
    averageForceLabel = [[UILabel alloc]init];
    averageForceLabel.text = [NSString stringWithFormat:@"%.2f", totalForce];
    averageForceLabel.textColor = UIColorFromRGB(0xFFFFFF);
    [averageForceLabel sizeToFit];
    [averageForceLabel setFont:[UIFont fontWithName:@"Futura-CondensedExtraBold" size:20.0]];
    averageForceLabel.center = CGPointMake(SCREEN_WIDTH/2, SCREEN_HEIGHT/2 + 80);
    [averageForceLabel sizeToFit];
    
    [self.view addSubview:averageForceLabel];
    
    logoutButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self formatTheButtonMyWay:logoutButton withText:@"LOGOUT"];
    [logoutButton.titleLabel setFont:[UIFont fontWithName:@"Futura-CondensedExtraBold" size:12.0]];
    logoutButton.frame = CGRectMake(0, 0, 75, 75);
    logoutButton.layer.cornerRadius = 37.5;
    logoutButton.center = CGPointMake(SCREEN_WIDTH-50, SCREEN_HEIGHT-50);
    [logoutButton addTarget:self action:@selector(logout) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:logoutButton];
    
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

- (void)logout
{
    NSLog(@"User logged out");
    [PFUser logOut];
    [self performSegueWithIdentifier:@"UserLoggedOut" sender:self];
}

- (void) didReadHardwareRevisionString:(NSString *)string
{
    //[self addTextToConsole:[NSString stringWithFormat:@"Hardware revision: %@", string] dataType:LOGGING];
}

- (void) didReceiveData:(NSString *)string
{
    [self addTextToConsole:string dataType:RX];
}

- (void) addTextToConsole:(NSString *) string dataType:(ConsoleDataType) dataType
{
    NSString *direction;
    switch (dataType)
    {
        case RX:
            direction = @"RX";
            break;
            
        case TX:
            direction = @"TX";
            break;
            
        case LOGGING:
            direction = @"Log";
    }
    
    NSDateFormatter *formatter;
    formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm:ss.SSS"];
    
    
    self.consoleTextView.text = [self.consoleTextView.text stringByAppendingFormat:@"[%@] %@: %@\n",[formatter stringFromDate:[NSDate date]], direction, string];
    
    self.consoleTextView.text = [self.consoleTextView.text stringByAppendingFormat:@"%@\n", string];
    punchesLabel.text = [NSString stringWithFormat:@"%i", ++punches];
    [punchesLabel sizeToFit];
    
    force = [string floatValue];
    forceLabel.text = [NSString stringWithFormat:@"%.2f", force];
    [forceLabel sizeToFit];
    
    totalForce = (totalForce + force);
    averageForceLabel.text = [NSString stringWithFormat:@"%.2f", totalForce/punches];
    [averageForceLabel sizeToFit];
    
    [self.consoleTextView setScrollEnabled:NO];
    NSRange bottom = NSMakeRange(self.consoleTextView.text.length-1, self.consoleTextView.text.length);
    [self.consoleTextView scrollRangeToVisible:bottom];
    [self.consoleTextView setScrollEnabled:YES];
}

- (void) centralManagerDidUpdateState:(CBCentralManager *)central
{
    if (central.state == CBCentralManagerStatePoweredOn)
    {
        [self.connectButton setEnabled:YES];
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
    
    //[self addTextToConsole:[NSString stringWithFormat:@"Did connect to %@", peripheral.name] dataType:LOGGING];
    
    self.state = CONNECTED;
    [self.connectButton setTitle:@"Disconnect" forState:UIControlStateNormal];
    [self.sendButton setUserInteractionEnabled:YES];
    [self.sendTextField setUserInteractionEnabled:YES];
    
    if ([self.currentPeripheral.peripheral isEqual:peripheral])
    {
        [self.currentPeripheral didConnect];
    }
}

- (void) centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"Did disconnect peripheral %@", peripheral.name);
    
    //[self addTextToConsole:[NSString stringWithFormat:@"Did disconnect from %@, error code %d", peripheral.name, error.code] dataType:LOGGING];
    
    self.state = IDLE;
    [self.connectButton setTitle:@"Connect" forState:UIControlStateNormal];
    [self.sendButton setUserInteractionEnabled:NO];
    [self.sendTextField setUserInteractionEnabled:NO];
    
    if ([self.currentPeripheral.peripheral isEqual:peripheral])
    {
        [self.currentPeripheral didDisconnect];
    }
}
- (void)formatTheButtonMyWay:(UIButton *)b withText:(NSString *)text{
    [b setTitle:text forState:UIControlStateNormal];
    [b.titleLabel setFont:[UIFont fontWithName:@"Futura-CondensedExtraBold" size:24.0]];
    b.tintColor = UIColorFromRGB(0xFFFFFF);
    b.backgroundColor = UIColorFromRGB(0xF6320B);
}

-(void)startStopTimer{
    if(running == false){
        
        if(paused == true) startDate = pauseDate;
        else startDate = [NSDate date];
        
        running = true;
        [startStop setTitle:@"STOP" forState:UIControlStateNormal];
        
        if(stopTimer == nil)stopTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/100.0 target:self selector:@selector(updateTimer) userInfo:nil repeats:YES];
    }else{
        running = false;
        [startStop setTitle:@"START" forState:UIControlStateNormal];
        [stopTimer invalidate];
        stopTimer = nil;
        pauseDate = startDate;
        paused = true;
    }

}

-(void)updateTimer{
    // Create date from the elapsed time
    NSDate *currentDate = [NSDate date];
    
    NSTimeInterval timeInterval = [currentDate timeIntervalSinceDate:startDate];
    NSDate *timerDate = [NSDate dateWithTimeIntervalSince1970:timeInterval];
    
    // Create a date formatter
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"mm:ss.SSS"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0.0]];
    
    // Format the elapsed time and set it to the label
    NSString *timeString = [dateFormatter stringFromDate:timerDate];
    time.text = timeString;
}

-(void)resetPressed{
    running = false;
    paused = false;
    [stopTimer invalidate];
    stopTimer = nil;
    startDate = [NSDate date];
    time.text = @"00:00.000";
    consoleTextView.text = @"";
    [self updateTimer];
    
    punches = 0;
    punchesLabel.text = [NSString stringWithFormat:@"%i", punches];
    
    force = 0;
    forceLabel.text = [NSString stringWithFormat:@"%.2f", force];
    
    totalForce = 0;
    averageForceLabel.text = [NSString stringWithFormat:@"%.2f", totalForce];
    
    [startStop setTitle:@"START" forState:UIControlStateNormal];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    //[self.currentPeripheral writeRawData:msgData];
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
    //[self.currentPeripheral writeRawData:msgData];
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


- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}
@end
