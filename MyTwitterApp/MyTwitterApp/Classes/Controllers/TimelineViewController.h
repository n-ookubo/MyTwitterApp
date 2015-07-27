//
//  TimelineViewController.h
//  MyTwitterApp
//
//  Created by 大久保直昭 on 2015/07/27.
//  Copyright (c) 2015年 大久保直昭. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TimelineService.h"
#import "TTTAttributedLabel.h"

@interface TimelineViewController : UITableViewController<TTTAttributedLabelDelegate>
@property (strong, nonatomic) TimelineService *timelineService;

@end
