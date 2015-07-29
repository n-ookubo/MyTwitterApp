//
//  TweetCell.h
//  MyTwitterApp
//
//  Created by 大久保直昭 on 2015/07/27.
//  Copyright (c) 2015年 大久保直昭. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MyCache.h"
#import "MyUser.h"
#import "MyTweet.h"
#import "TTTAttributedLabel.h"
#import "UIImageView+MyImageCache.h"

@interface TweetCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *screenNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *largeTimeLabel;
@property (weak, nonatomic) IBOutlet TTTAttributedLabel *contentLabel;

@property (weak, nonatomic) IBOutlet UIImageView *tweetImageView;
@property (weak, nonatomic) IBOutlet UILabel *retweetLabel;

@property (weak, nonatomic) MyTweet *selfTweet;

+ (CGFloat)heightForCellWithTweet:(MyTweet *)tweet withCellWidth:(CGFloat)width;
+ (CGFloat)heightForLargeCellWithTweet:(MyTweet *)tweet withCellWidth:(CGFloat)width;
+ (NSString *)parseLabelLinkURL:(NSURL *)url;

- (void)setDelegate:(id<TTTAttributedLabelDelegate>)delegate;
- (void)setTweet:(MyTweet *)tweet userCache:(MyCache *)userCache;
@end
