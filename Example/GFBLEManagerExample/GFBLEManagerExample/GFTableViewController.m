//
//  ViewController.m
//  GFBLEManagerExample
//
//  Created by GaoYuan on 16/2/5.
//  Copyright © 2016年 Yuan Gao. All rights reserved.
//

#import "GFTableViewController.h"
#import "GFPeripheralTableViewController.h"

@interface GFTableViewController () {
    NSMutableArray <CBPeripheral *> *_discoveredPeripheral;
}
@end

@implementation GFTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Searching for Peripherals ...";
    
    _discoveredPeripheral = [NSMutableArray new];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    _centralManager = [[GFBLEConnector alloc] initWithQueue:nil andDelegate:self];
    
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [_discoveredPeripheral removeAllObjects];
    [self.centralManager cleanBLEConnection];
    [_centralManager startBLEConnectionWithCompletion:^(BOOL success, NSString *message) {
        NSLog(@"%@", message);
    }];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
//    [_discoveredPeripheral removeAllObjects];
//    [self.centralManager cleanBLEConnection];
}

-(void)bleDidDiscoverPeripheral:(CBPeripheral *)peripheral
{
    if ([_discoveredPeripheral containsObject:peripheral]) {
        return;
    }
    
    NSMutableArray *indexPaths = [[NSMutableArray alloc] init];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:_discoveredPeripheral.count inSection:0];
    [indexPaths addObject:indexPath];
    [_discoveredPeripheral addObject:peripheral];
    [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
    self.title = @"Choose a Peripheral ...";
//    [self.tableView reloadData];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _discoveredPeripheral.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIndentifier = @"Peripheral Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIndentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIndentifier];
    }
    
    CBPeripheral *peripheral = _discoveredPeripheral[indexPath.row];
    cell.textLabel.text = peripheral.name;
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    CBPeripheral *connectToPeripheral = _discoveredPeripheral[indexPath.row];
    if (connectToPeripheral) {
        self.title = [NSString stringWithFormat:@"Connecting to Peripheral: %@", connectToPeripheral.name];
        [self.centralManager connectPeripheral:connectToPeripheral];
    } else {
        NSLog(@"Could not find the peripheral.");
    }
}

-(void)bleDidConnectToPeripheral:(CBPeripheral *)activePeripheral
{
    if (activePeripheral) {
        [self.centralManager printPeripheralInfo:activePeripheral];
        
        GFPeripheralTableViewController *peripheralTVC = [[GFPeripheralTableViewController alloc] initWithStyle:UITableViewStylePlain];
        peripheralTVC.activePeripheral = activePeripheral;
        
        [self.navigationController pushViewController:peripheralTVC animated:YES];
    }
}

-(void)bleDidDisconnectToPeripheral:(CBPeripheral *)peripheral withError:(NSError *__autoreleasing)error
{
    [_discoveredPeripheral removeAllObjects];
//    [self.centralManager startBLEConnectionWithCompletion:nil];
    [self.tableView reloadData];
}

@end
