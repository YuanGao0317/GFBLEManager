//
//  GFBLEDataReciever.h
//  SCSBLEDome
//
//  Created by GaoYuan on 16/2/5.
//  Copyright © 2016年 Yuan Gao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#pragma clang diagnostic ignored "-Wnullability-completeness"

typedef NS_ENUM(NSInteger, GFBLECommunicationError) {
    GFBLECommunicationErrorDisconnected,
    GFBLECommunicationErrorUnknownService,
    GFBLECommunicationErrorUnknownCharacteristic,
    GFBLECommunicationErrorDiscoverServiceFailed,
    GFBLECommunicationErrorDiscoverCharacteristicFailed,
    GFBLECommunicationErrorUpdateValueFailed,
    GFBLECommunicationUpdateValueSuccessed,
};



@protocol GFBLECommunicatorDelegate <NSObject>
@optional
-(void) didDiscoverCharacteristicsForService:(CBService *)service;
@required
-(void) didRecieveValue:(NSData *)data forCharacteristic:(CBCharacteristic *)characteristic error:(NSString * __autoreleasing)error;
@end


@interface GFBLECommunicator : NSObject

@property (nonatomic,strong,readonly) CBPeripheral *activePeripheral;
@property (nonatomic,assign) __unsafe_unretained id <GFBLECommunicatorDelegate> delegate;
@property (nonatomic,assign) GFBLECommunicationError communicationError;


// Initiallize active peripheral and delegate
-(id) initWithPeripheral:(CBPeripheral *)activePeripheral delegate:(nonnull id <GFBLECommunicatorDelegate>)delegate;

// Read value from multi services
-(void) activePeripheralReadValueForServiceUUIDs: (nonnull NSArray<CBUUID *> *)serviceUUIDs andCharacteristicUUID:(nonnull NSArray<CBUUID *> *)characteristicsUUIDs;

// Read value from all services and characteristics
-(void) activePeripheralReadAllCharacteristicsValue;

-(void) printPeripheralInfo:(CBPeripheral*)peripheral;
@end
