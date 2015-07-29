//
//  TimelineService.h
//  twitterSample
//
//  Created by 大久保直昭 on 2015/07/26.
//  Copyright (c) 2015年 大久保直昭. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "APIService.h"
#import "MyTweet.h"
#import "MyTweetJoint.h"

typedef NS_ENUM(NSUInteger, kTimelineObjectType) {
    kTimelineObjectTweet,
    kTimelineObjectJoint,
    kTimelineObjectUnknown
};

typedef void(^TimelineServiceLoadCompletionHandler) (NSUInteger startIndex, NSUInteger length, NSError *error);

@interface TimelineService : NSObject
@property (copy, readonly) NSString *timelineUserId;

- (instancetype) __unavailable init;
- (instancetype)initWithAPIService:(APIService *)service timelineUserId:(NSString *)userId;
- (instancetype)resumeFromCache;

- (NSUInteger)count;
- (kTimelineObjectType)getObjectTypeAtIndex:(NSUInteger)index;
- (MyTweet *)getTweetAtIndex:(NSUInteger)index;

- (BOOL)loadRecentTweetWithHandler:(TimelineServiceLoadCompletionHandler)handler;
- (BOOL)loadJointAtIndex:(NSUInteger)index completion:(TimelineServiceLoadCompletionHandler)handler;
@end
