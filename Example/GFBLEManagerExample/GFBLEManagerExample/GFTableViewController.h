//
//  ViewController.h
//  GFBLEManagerExample
//
//  Created by GaoYuan on 16/2/5.
//  Copyright © 2016年 Yuan Gao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GFBLEConnector.h"

@interface GFTableViewController : UITableViewController<UITableViewDataSource,UITableViewDelegate,GFBLEConnectorDelegate>
@property (nonatomic,strong) GFBLEConnector *centralManager;
@end

