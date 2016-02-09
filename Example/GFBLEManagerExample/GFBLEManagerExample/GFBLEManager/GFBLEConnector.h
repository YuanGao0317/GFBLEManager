//
//  GFBLEConnector.h
//  SCSBLEDome
//
//  Created by GaoYuan on 16/2/5.
//  Copyright © 2016年 Yuan Gao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

#pragma clang diagnostic ignored "-Wnullability-completeness"


@protocol GFBLEConnectorDelegate <NSObject>
@optional
-(void) bleDidDisconnectToPeripheral:(CBPeripheral *)peripheral withError:(NSError * __autoreleasing)error;

@required
-(void) bleDidDiscoverPeripheral:(CBPeripheral *)peripheral;
-(void) bleDidConnectToPeripheral:(CBPeripheral *)activePeripheral;
@end



@interface GFBLEConnector : NSObject

typedef void (^ScaningState)(BOOL success, NSString *message);

@property (nonatomic,strong) CBCentralManager *centralManager;
@property (nonatomic,strong) CBPeripheral *activePeripheral;
@property (nonatomic,assign) id <GFBLEConnectorDelegate> delegate;

@property (nonatomic,assign) float scanTimeout;
@property (nonatomic,assign) BOOL isConnectedToPeripheral;



-(id) initWithQueue:(nullable dispatch_queue_t)queue andDelegate:(nonnull id <GFBLEConnectorDelegate>)delegate;

-(void) startBLEConnectionWithCompletion:(nullable ScaningState)state;

-(void) startBLEConnectionWithTimeout:(float)timeout completion:(nullable ScaningState)state;

/**
 * YES: Turn On | NO:  Turn Off
 **/
-(void) centralManagerScanSwitch:(BOOL)switchState;

/**
 * Must call this method after discovered peripherals to connect to a peripheral
 **/
-(void) connectPeripheral:(nullable CBPeripheral *)peripheral;

-(void) printPeripheralInfo:(CBPeripheral*)peripheral;

-(void) cleanBLEConnection;
@end
