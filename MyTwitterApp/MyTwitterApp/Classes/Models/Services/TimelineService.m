//
//  TimelineService.m
//  twitterSample
//
//  Created by 大久保直昭 on 2015/07/26.
//  Copyright (c) 2015年 大久保直昭. All rights reserved.
//

#import "TimelineService.h"

@interface TimelineService ()
@property (weak) APIService *apiService;
@property (copy) NSString *timelineUserId;
@property (strong) NSMutableArray *timelineArray;

@end

@implementation TimelineService
const NSUInteger kLoadingTweetCountAtOnce = 40;

- (instancetype)init
{
    [NSException raise:NSGenericException format:@"init is not available. use [[%@ alloc] %@] instead.", NSStringFromClass(self.class), NSStringFromSelector(@selector(initWithAccount:))];
    return nil;
}

- (instancetype)initWithAPIService:(APIService *)service timelineUserId:(NSString *)userId
{
    self = [super init];
    if (self) {
        if (!service) {
            return nil;
        }
        
        self.apiService = service;
        self.timelineUserId = userId;
        self.timelineArray = [[NSMutableArray alloc] init];
    }
    return self;
}

- (NSUInteger)count
{
    return self.timelineArray.count;
}

- (kTimelineObjectType)getObjectTypeAtIndex:(NSUInteger)index
{
    if (index >= self.timelineArray.count) {
        return kTimelineObjectUnknown;
    }
    
    id obj = [self.timelineArray objectAtIndex:index];
    if ([obj isKindOfClass:[MyTweet class]]) {
        return kTimelineObjectTweet;
    } else if ([obj isKindOfClass:[MyTweetJoint class]]) {
        return kTimelineObjectJoint;
    } else {
        return kTimelineObjectUnknown;
    }
}

- (MyTweet *)getTweetAtIndex:(NSUInteger)index
{
    if (index >= self.timelineArray.count) {
        return nil;
    }
    
    id obj = [self.timelineArray objectAtIndex:index];
    if ([obj isKindOfClass:[MyTweet class]]) {
        return obj;
    } else {
        return nil;
    }
}

- (BOOL)loadRecentTweetWithHandler:(TimelineServiceLoadCompletionHandler)handler
{
    if (!handler) {
        return NO;
    }
    
    NSString *rangeFrom = nil;
    if (self.timelineArray.count > 0) {
        MyTweet *tweet = [self.timelineArray objectAtIndex:0];
        rangeFrom = tweet.tweetId;
    }
    
    void (^apiHandler)(NSArray *result, NSError *error) = ^(NSArray *result, NSError *error) {
        NSUInteger startIndex = 0;
        NSUInteger count = 0;
        if (!error) {
            NSArray *array = result;
            if (result.count == kLoadingTweetCountAtOnce) {
                // Jointの作成
                MyTweetJoint *joint = [[MyTweetJoint alloc] initFrom:rangeFrom to:((MyTweet *)[result lastObject]).tweetId];
                
                NSMutableArray *newArray = [[NSMutableArray alloc] initWithArray:result];
                [newArray addObject:joint];
                array = newArray;
            }
            count = array.count;
            if (count > 0) {
                NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(startIndex, count)];
                [self.timelineArray insertObjects:array atIndexes:indexes];
                
                id lastObj = [self.timelineArray lastObject];
                if ([lastObj isKindOfClass:[MyTweet class]]) {
                    // 末尾にJointを追加
                    MyTweetJoint *joint = [[MyTweetJoint alloc] initFrom:nil to:((MyTweet *)lastObj).tweetId];
                    [self.timelineArray addObject:joint];
                }
            }
        }
        handler(startIndex, count, error);
    };
    
    if (self.timelineUserId) {
        return [self.apiService getUserTimeLineWithUserId:self.timelineUserId count:kLoadingTweetCountAtOnce rangeFrom:rangeFrom rangeTo:nil completion:apiHandler];
    } else {
        return [self.apiService getHomeTimeLineWithCount:kLoadingTweetCountAtOnce rangeFrom:rangeFrom rangeTo:nil completion:apiHandler];
    }
}

- (BOOL)loadJointAtIndex:(NSUInteger)index completion:(TimelineServiceLoadCompletionHandler)handler;
{
    if (!handler) {
        return NO;
    }
    
    if (index >= self.timelineArray.count) {
        return NO;
    }
    
    id obj = [self.timelineArray objectAtIndex:index];
    if (![obj isKindOfClass:[MyTweetJoint class]]) {
        return NO;
    }
    MyTweetJoint *joint = obj;
    __block NSMutableArray *timelineArray = self.timelineArray;
    void (^apiHandler)(NSArray *result, NSError *error) = ^(NSArray *result, NSError *error) {
        NSUInteger startIndex = [timelineArray indexOfObject:obj]; // insert to joint index
        NSUInteger count = 0;
        if (!error && result.count > 1) {
            NSMutableArray * array = [NSMutableArray arrayWithArray:result];
            [array removeObjectAtIndex:0];
            BOOL removeJoint = (array.count < kLoadingTweetCountAtOnce && joint.from);
            if (removeJoint) {
                // Jointを破棄する
                [timelineArray removeObjectAtIndex:index];
            } else {
                // Jointの維持
                joint.to = ((MyTweet *)[array lastObject]).tweetId;
            }
            count = array.count;
            NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(startIndex, count)];
            [timelineArray insertObjects:array atIndexes:indexes];
            
            if (removeJoint) {
                count--;
            }
        }
        handler(startIndex, count, error);
    };
    
    if (self.timelineUserId) {
        return [self.apiService getUserTimeLineWithUserId:self.timelineUserId count:kLoadingTweetCountAtOnce + 1 rangeFrom:joint.from rangeTo:joint.to completion:apiHandler];
    } else {
        return [self.apiService getHomeTimeLineWithCount:kLoadingTweetCountAtOnce rangeFrom:joint.from rangeTo:joint.to completion:apiHandler];
    }
}

@end
