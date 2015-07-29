//
//  MyTweet.h
//  twitterSample
//
//  Created by 大久保直昭 on 2015/07/23.
//  Copyright (c) 2015年 大久保直昭. All rights reserved.
//

#import "MyTwitterObj.h"

@interface MyTweet : MyTwitterObj
@property (weak, nonatomic) NSString *tweetId;
@property (weak, nonatomic) NSString *userId;

@property (weak, nonatomic) NSString *text;
@property (weak, nonatomic) NSDictionary *entities;

@property (weak, nonatomic) NSString *createdDateString;

@property (strong, nonatomic) MyTweet *retweet;

@property (copy, nonatomic) NSString *mediaUrl;
@property (copy, nonatomic) NSNumber *mediaWidth;
@property (copy, nonatomic) NSNumber *mediaHeight;

- (NSDate *)createdDate;
- (NSString *)mentionsForReply;
@end
