//
//  PeripheralTableViewController.m
//  GFBLEManagerExample
//
//  Created by GaoYuan on 16/2/5.
//  Copyright © 2016年 Yuan Gao. All rights reserved.
//

#import "GFPeripheralTableViewController.h"

#define SCS_WEIGHT_VALUE_SERVICE_UUID @"00661335-5779-9180-7968-aabbccddeeff"
#define SCS_WV_CHARACTERISTIC_UUID @"00661102-5779-9180-7968-aabbccddeeff"

@interface GFPeripheralTableViewController () {
    NSMutableArray<CBService *> *_servicesArray;
    NSArray<CBUUID *> *_serviceUUIDs;
    NSArray<CBUUID *> *_characteristicUUIDs;
    NSDictionary *_serviceDictionary;
}

@end

@implementation GFPeripheralTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    _servicesArray = [[NSMutableArray alloc] initWithArray:self.activePeripheral.services];
    _communicator = [[GFBLECommunicator alloc] initWithPeripheral:_activePeripheral delegate:self];
    
//    [self setUpService];
}

-(void) setUpService
{
    _serviceUUIDs = @[SCS_WEIGHT_VALUE_SERVICE_UUID];
    _characteristicUUIDs = @[SCS_WV_CHARACTERISTIC_UUID];
    _serviceDictionary = @{SCS_WEIGHT_VALUE_SERVICE_UUID : @[SCS_WV_CHARACTERISTIC_UUID]};
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.communicator activePeripheralReadAllCharacteristicsValue];
//    [self.communicator activePeripheralReadValueForServiceUUIDs:_serviceUUIDs
//                                          andCharacteristicUUID:_characteristicUUIDs];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSLog(@"service array count : %lu", (unsigned long)_servicesArray.count);
    return _servicesArray.count;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    CBService *s = [_servicesArray objectAtIndex:section];
    
    return s.UUID.UUIDString;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    UITableViewHeaderFooterView *v = (UITableViewHeaderFooterView *)view;
    v.backgroundView.backgroundColor = [UIColor greenColor];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    CBService *s = [_servicesArray objectAtIndex:section];
    
    return s.characteristics.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    CBService *s = [_servicesArray objectAtIndex:indexPath.section];
    NSArray *characteristicArray = s.characteristics;
    CBCharacteristic *characteristic = [characteristicArray objectAtIndex:indexPath.row];
    
    static NSString *cellIndentifier = @"Data Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIndentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIndentifier];
    }
    
    cell.textLabel.text = characteristic.UUID.UUIDString;

    return cell;
}


-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 54;
}


-(void)didDiscoverCharacteristicsForService:(CBService *)service
{
    if (service) {
        [_servicesArray addObject:service];
        [self.tableView reloadData];
    }
}

-(void)didRecieveValue:(NSData *)data forCharacteristic:(CBCharacteristic *)characteristic error:(NSString *__autoreleasing)error
{

//    NSLog(@"Data from characheristic: %@", characteristic.UUID.UUIDString);
    
    __weak typeof(self) weakSelf = self;
    for (int i=0;i<_servicesArray.count;i++) {
        
        CBService *s = [_servicesArray objectAtIndex:i];
        NSArray *characteristicArray = s.characteristics;
        
        for (int j = 0; j < characteristicArray.count; j++) {
            CBCharacteristic *characteristic = [characteristicArray objectAtIndex:j];
            UITableViewCell *cell = [weakSelf.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:j inSection:i]];
            NSString *UUID1 = cell.textLabel.text;
            NSString *UUID2 = characteristic.UUID.UUIDString;
            if ([UUID1 caseInsensitiveCompare:UUID2] == NSOrderedSame) {
                NSLog(@"cell text: %@", UUID1);
                cell.detailTextLabel.text = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
            }
        }
    }
}

@end
