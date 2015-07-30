//
//  TweetDetailViewController.h
//  MyTwitterApp
//
//  Created by 大久保直昭 on 2015/07/28.
//  Copyright (c) 2015年 大久保直昭. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TimelineViewController.h"
#import "MyTweet.h"
#import "TTTAttributedLabel.h"

@interface TweetDetailViewController : UITableViewController<TTTAttributedLabelDelegate>
@property (weak, nonatomic) TimelineViewController *parentTimeline;
@property (strong, nonatomic) MyTweet *selfTweet;

@end
