//
//  TweetEditViewController.h
//  MyTwitterApp
//
//  Created by 大久保直昭 on 2015/07/29.
//  Copyright (c) 2015年 大久保直昭. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TimelineViewController.h"
#import "MyTweet.h"

@interface TweetEditViewController : UIViewController<UITextViewDelegate>
@property (weak, nonatomic) TimelineViewController *parentTimeline;
@property (strong, nonatomic) MyTweet *replyTweet;

@end
