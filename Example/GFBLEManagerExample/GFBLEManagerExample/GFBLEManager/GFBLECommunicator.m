//
//  GFBLEDataReciever.m
//  SCSBLEDome
//
//  Created by GaoYuan on 16/2/5.
//  Copyright © 2016年 Yuan Gao. All rights reserved.
//

#import "GFBLECommunicator.h"

@interface GFBLECommunicator ()<CBPeripheralDelegate> {
    NSArray<CBUUID *> *_serviceUUIDs;
    NSArray<CBUUID *> *_characteristicUUIDs;
    CBUUID *_serviceUUID;
    CBUUID *_characteristicUUID;
}
@end

@implementation GFBLECommunicator

#pragma mark - Initiallization

-(id) initWithPeripheral:(CBPeripheral *)activePeripheral delegate:(nonnull id <GFBLECommunicatorDelegate>)delegate
{
    self = [super init];
    if (self) {
        _activePeripheral = activePeripheral;
        _activePeripheral.delegate = self;
        _delegate = delegate;
    }
    
    return self;
}

#pragma mark - Communication Control

// Read value from multi services
-(void) activePeripheralReadValueForServiceUUIDs: (nonnull NSArray<CBUUID *> *)serviceUUIDs andCharacteristicUUID:(nonnull NSArray<CBUUID *> *)characteristicsUUIDs
{
    if (!self.activePeripheral &&
        ( serviceUUIDs.count < 1 || characteristicsUUIDs.count < 1 ))
    {
        // There is no peripheral connected
        [self _communicationErrorHandler:GFBLECommunicationErrorDisconnected];
        
        return;
    }
    
    _serviceUUIDs = [[NSArray alloc] initWithArray:serviceUUIDs];
    _characteristicUUIDs = [[NSArray alloc] initWithArray:characteristicsUUIDs];
    
    if ([self _isFoundServices:_serviceUUIDs inPeripheral:self.activePeripheral]) {
        if ([self _isFoundCharacteristics:_characteristicUUIDs inPeripheral:self.activePeripheral]) {
            [self.activePeripheral discoverServices:_serviceUUIDs];
        } else {
            // One or more characteristicUUIDs can't be found in peripheral
            [self _communicationErrorHandler:GFBLECommunicationErrorUnknownCharacteristic];
        }
    } else {
        // One or more serviceUUIDs can't be found in peripheral
        [self _communicationErrorHandler:GFBLECommunicationErrorUnknownService];
    }
}

// Read value from all services and characteristics
-(void) activePeripheralReadAllCharacteristicsValue
{
    if (self.activePeripheral) {
        _serviceUUIDs = nil;
        _characteristicUUIDs = nil;
        [self.activePeripheral discoverServices:nil];
    }
}


#pragma mark - CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error) {
        NSLog(@"%@", [error localizedDescription]);
        [self _communicationErrorHandler:GFBLECommunicationErrorDiscoverServiceFailed];
        return;
    }
    
    if (_serviceUUIDs && _characteristicUUIDs) {
        for (CBService *service in _serviceUUIDs) {
            NSLog(@"Discovered service: %@", service);
            [peripheral discoverCharacteristics:_characteristicUUIDs forService:service];
        }
    } else {
        // Discover all services' characteristics
        for (CBService *service in peripheral.services) {
            NSLog(@"Discovered service: %@", service);
            [peripheral discoverCharacteristics:nil forService:service];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if (error) {
        NSLog(@"%@", [error localizedDescription]);
        [self _communicationErrorHandler:GFBLECommunicationErrorDiscoverCharacteristicFailed];
        return;
    }
    
    if ([self.delegate conformsToProtocol:@protocol(GFBLECommunicatorDelegate)] &&
        [self.delegate respondsToSelector:@selector(didDiscoverCharacteristicsForService:)]) {
        [self.delegate didDiscoverCharacteristicsForService:service];
    }
    
    NSLog(@"<------SET NOTIFY: YES------>");
    for (CBCharacteristic *aChar in service.characteristics) {
        [self.activePeripheral setNotifyValue:YES forCharacteristic:aChar];
        NSLog(@"Set notifiy: YES for characteristic: %@", aChar.UUID);
        [self.activePeripheral readValueForCharacteristic:aChar];
        NSLog(@"Is reading value from characteristic: %@", aChar.UUID);
    }
    
    NSLog(@"GET VALUE IN DELEGATE---> didRecieveValue:forCharacteristic:error:");
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
    if (error) {
        NSLog(@"%@", [error localizedDescription]);
        // Characteristic can't update value
        [self _communicationErrorHandler:GFBLECommunicationErrorUpdateValueFailed];
        return;
    }
    
    NSData *dataBytes = characteristic.value;
    NSLog(@"DATA recieved: %@", [[NSString alloc]initWithData:dataBytes encoding:NSUTF8StringEncoding]);
    
    /** Value type: float, NSString
    uint32_t hostData = CFSwapInt32BigToHost(*(const uint32_t *)[dataBytes bytes]);
    float floatValue = *(float *)(&hostData);
    NSString *stringValue = [[NSString alloc]initWithData:dataBytes encoding:NSUTF8StringEncoding];
    **/
    
    // Update characteristic value in delegate - didRecieveValue:forCharacteristic:error:
    if ([self.delegate conformsToProtocol:@protocol(GFBLECommunicatorDelegate)] &&
        [self.delegate respondsToSelector:@selector(didRecieveValue:forCharacteristic:error:)]) {
        self.communicationError = GFBLECommunicationUpdateValueSuccessed;
        [self.delegate didRecieveValue:dataBytes
                     forCharacteristic:characteristic
                                 error:nil];
    }
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



#pragma mark - Private Methods

-(void) _communicationErrorHandler:(GFBLECommunicationError)error
{
    self.communicationError = error;
    if ([self.delegate conformsToProtocol:@protocol(GFBLECommunicatorDelegate)] &&
        [self.delegate respondsToSelector:@selector(didRecieveValue:forCharacteristic:error:)]) {
        [self.delegate didRecieveValue:nil
                     forCharacteristic:nil
                                 error:[self _communicationErrorToString:error]];
    }
}

-(BOOL) _isFoundServices:(nonnull NSArray<CBUUID *> *)serviceUUIDs inPeripheral:(CBPeripheral *)peripheral
{
    for(int i = 0; i < peripheral.services.count; i++)
    {
        CBService *service = [peripheral.services objectAtIndex:i];
        for (int j = 0; j < serviceUUIDs.count; j++) {
            CBUUID *UUID = [serviceUUIDs objectAtIndex:j];
            if ([self _UUID:service.UUID isEqualToUUID:UUID])
                return YES;
        }
    }
    
    return NO;
}

-(BOOL) _isFoundCharacteristics:(nonnull NSArray<CBUUID *> *)characteristicsUUIDs inPeripheral:(CBPeripheral *)peripheral
{
    for(int i = 0; i < peripheral.services.count; i++)
    {
        CBService *service = [peripheral.services objectAtIndex:i];
        for (int t = 0; t < service.characteristics.count; t++)
        {
            CBCharacteristic *characteristic = [service.characteristics objectAtIndex:t];
            for (int j = 0; j < characteristicsUUIDs.count; j++)
            {
                CBUUID *UUID = [characteristicsUUIDs objectAtIndex:j];
                if ([self _UUID:characteristic.UUID isEqualToUUID:UUID])
                    return YES;
            }
        }
    }
    
    return NO;
}

-(BOOL) _UUID:(CBUUID *)UUID1 isEqualToUUID:(CBUUID *)UUID2
{
    char b1[16];
    char b2[16];
    NSUInteger l1;
    NSUInteger l2;
    [UUID1.data getBytes:b1 length:l1];
    [UUID2.data getBytes:b2 length:l2];
    
    if (l1 == l2) {
        if (memcmp(b1, b2, UUID1.data.length) == 0)
            return YES;  //equal
        else
            return NO;
    } else {
        return NO;
    }
}

- (NSString*) _communicationErrorToString: (GFBLECommunicationError)error
{
    switch(error)
    {
        case GFBLECommunicationErrorDisconnected:
            return @"There is no active peripheral with services and characteristics.";
        case GFBLECommunicationErrorUnknownService:
            return @"Can't find serviceUUID(s) in the active peripheral.";
        case GFBLECommunicationErrorUnknownCharacteristic:
            return @"Can't find Characteristic(s) in the active peripheral.";
        case GFBLECommunicationErrorDiscoverServiceFailed:
            return @"Discovering services failed.";
        case GFBLECommunicationErrorDiscoverCharacteristicFailed:
            return @"Discovering characteristics failed.";
        case GFBLECommunicationErrorUpdateValueFailed:
            return @"Characteristic can't update value.";
        case GFBLECommunicationUpdateValueSuccessed:
            return @"Characteristic update value successfully.";
        default:
            return @"Unknown communication error.";
    }
    
    return @"Unknown communication error.";
}

@end
