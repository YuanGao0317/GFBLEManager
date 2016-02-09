//
//  PeripheralTableViewController.h
//  GFBLEManagerExample
//
//  Created by GaoYuan on 16/2/5.
//  Copyright © 2016年 Yuan Gao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GFBLECommunicator.h"

@interface GFPeripheralTableViewController : UITableViewController<GFBLECommunicatorDelegate>
@property (nonatomic,strong) CBPeripheral *activePeripheral;
@property (nonatomic,strong) GFBLECommunicator *communicator;
@end
