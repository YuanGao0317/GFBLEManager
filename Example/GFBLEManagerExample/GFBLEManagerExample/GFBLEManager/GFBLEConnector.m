//
//  GFBLEConnector.m
//  SCSBLEDome
//
//  Created by GaoYuan on 16/2/5.
//  Copyright © 2016年 Yuan Gao. All rights reserved.
//

#import "GFBLEConnector.h"

@interface GFBLEConnector ()<CBCentralManagerDelegate>

@end

@implementation GFBLEConnector

#pragma mark - Initiallization

-(id) initWithQueue:(nullable dispatch_queue_t)queue andDelegate:(nonnull id <GFBLEConnectorDelegate>)delegate
{
    self = [super init];
    if (self) {
        _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:queue];
        _delegate = delegate;
        _isConnectedToPeripheral = NO;
        _scanTimeout = 0;
    }
    return self;
}


#pragma mark - Connection Control

-(void) startBLEConnectionWithTimeout:(float)timeout completion:(nullable ScaningState)state
{
    self.scanTimeout = timeout;
    
    if ([self.centralManager state] == CBCentralManagerStatePoweredOn) {
        
        // Start scanning for peripherals
        [self centralManagerScanSwitch:YES];
        if (state) {
            state(YES, [self _centralManagerStateToString:[self.centralManager state]]);
        }
        [NSTimer scheduledTimerWithTimeInterval:self.scanTimeout target:self selector:@selector(stopScan) userInfo:nil repeats:NO];
    } else {
        
        if (state) {
            state(NO, [self _centralManagerStateToString:[self.centralManager state]]);
        }
    }
}

-(void) startBLEConnectionWithCompletion:(nullable ScaningState)state
{
    self.scanTimeout = 0;
    
    if ([self.centralManager state] == CBCentralManagerStatePoweredOn) {
        // Start scanning for peripherals
        [self centralManagerScanSwitch:YES];
        if (state) {
            state(YES, [self _centralManagerStateToString:[self.centralManager state]]);
        }
    }
    
    if (state) {
        state(NO, [self _centralManagerStateToString:[self.centralManager state]]);
    }
}

-(void) cleanBLEConnection
{
    if (self.activePeripheral) {
        [self.centralManager stopScan];
        [self.centralManager cancelPeripheralConnection:self.activePeripheral];
    }
}



#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if (!self.isConnectedToPeripheral &&
        [central state] == CBCentralManagerStatePoweredOn) {
        [self startBLEConnectionWithCompletion:^(BOOL success, NSString *message) {
            NSLog(@"Central manager is scanning for peripherals: %d", success);
        }];
    }
    NSLog(@"Status of CoreBluetooth central manager changed %ld (%@)", (long)central.state, [self _centralManagerStateToString:central.state]);
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    // Retrieve the peripheral name from the advertisement data using the "kCBAdvDataLocalName" key
    NSString *peripheralName = [advertisementData objectForKey:@"kCBAdvDataLocalName"];
//    NSString *peripheralUUID = peripheral.identifier.UUIDString;
    NSLog(@"PERIPHERAL ------> %@ (%@)", peripheralName, peripheral.identifier.UUIDString);
    
    // Discover all peripherals
    if ([self.delegate conformsToProtocol:@protocol(GFBLEConnectorDelegate)] &&
        [self.delegate respondsToSelector:@selector(bleDidDiscoverPeripheral:)]) {
        [self.delegate bleDidDiscoverPeripheral:peripheral];
    }
}


- (void) connectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"Connecting to peripheral with UUID : %@", peripheral.identifier.UUIDString);
    // Stop scanning
    [self centralManagerScanSwitch:NO];
    
    //    self.activePeripheral = peripheral;
    //    self.activePeripheral.delegate = self;
    [self.centralManager connectPeripheral:peripheral
                                   options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:CBConnectPeripheralOptionNotifyOnDisconnectionKey]];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"CONNECTION FAILED!!!");
    if (error) {
        NSLog(@"%@", [error localizedDescription]);
        return;
    }
    
    if ([self.delegate conformsToProtocol:@protocol(GFBLEConnectorDelegate)] &&
        [self.delegate respondsToSelector:@selector(bleDidDisconnectToPeripheral:withError:)]) {
        [self.delegate bleDidDisconnectToPeripheral:peripheral withError:error];
    }
    
    self.activePeripheral = nil;
    self.isConnectedToPeripheral = NO;
    
    // Restart scanning
    [self centralManagerScanSwitch:YES];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"DISCONNECTED FROM THE PERIPHERAL!!!");
    NSLog(@"%@", [error localizedDescription]);
    
    if ([self.delegate conformsToProtocol:@protocol(GFBLEConnectorDelegate)] &&
        [self.delegate respondsToSelector:@selector(bleDidDisconnectToPeripheral:withError:)]) {
        [self.delegate bleDidDisconnectToPeripheral:peripheral withError:error];
    }
    
    self.activePeripheral = nil;
    self.isConnectedToPeripheral = NO;
    
    // Restart scanning
//    [self centralManagerScanSwitch:YES];
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    if (peripheral.identifier != NULL)
        NSLog(@"Connected to %@ successful", peripheral.identifier.UUIDString);
    else
        NSLog(@"Connected to NULL successful");
    
    self.isConnectedToPeripheral = YES;
    self.activePeripheral = peripheral;
//    self.activePeripheral.delegate = self;
    NSLog(@"Central is connected to the peripheral: %@", peripheral.identifier.description);
    
    [self centralManagerScanSwitch:NO];
    
    [self.delegate bleDidConnectToPeripheral:self.activePeripheral];
}



#pragma mark - Common Methods

-(void) printPeripheralInfo:(CBPeripheral*)peripheral
{
    NSLog(@"------------------------------------");
    NSLog(@"Peripheral Info :");
    
    if (peripheral.identifier != NULL)
        NSLog(@"UUID : %@", peripheral.identifier.UUIDString);
    else
        NSLog(@"UUID : NULL");
    
    NSLog(@"Name : %@", peripheral.name);
    NSLog(@"-------------------------------------");
}


-(void) centralManagerScanSwitch:(BOOL)switchState
{
    if (switchState) {
        [self _startScan];
    } else {
        [self _stopScan];
    }
}



#pragma mark - Private Methods

-(void) _stopScan
{
    [self.centralManager stopScan];
    NSLog(@"Central manager stopped scan for peripherals.");
}

-(void) _startScan
{
    if (self.scanTimeout > 0) {
        [self.centralManager scanForPeripheralsWithServices:nil options:nil];
        [NSTimer scheduledTimerWithTimeInterval:self.scanTimeout target:self selector:@selector(stopScan) userInfo:nil repeats:NO];
    } else {
        [self.centralManager scanForPeripheralsWithServices:nil options:nil];
    }
    NSLog(@"Central manager is scanning for peripherals.");
}


- (NSString*) _centralManagerStateToString: (CBCentralManagerState)state
{
    switch(state)
    {
        case CBCentralManagerStateUnknown:
            return @"This device does not support Bluetooth Low Energy.";
        case CBCentralManagerStateResetting:
            return @"The BLE Manager is resetting; a state update is pending.";
        case CBCentralManagerStateUnsupported:
            return @"State BLE unsupported (CBCentralManagerStateResetting)";
        case CBCentralManagerStateUnauthorized:
            return @"This app is not authorized to use Bluetooth Low Energy.";
        case CBCentralManagerStatePoweredOff:
            return @"Bluetooth on this device is currently powered off.";
        case CBCentralManagerStatePoweredOn:
            return @"Bluetooth LE is turned on and scanning for peripherals.";
        default:
            return @"The state of the BLE Manager is unknown.";
    }
    
    return @"The state of the BLE Manager is unknown.";
}

@end
