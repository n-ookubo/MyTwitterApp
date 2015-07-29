//
//  TimelineService.m
//  twitterSample
//
//  Created by 大久保直昭 on 2015/07/26.
//  Copyright (c) 2015年 大久保直昭. All rights reserved.
//

#import "TimelineService.h"
#import "FileCacheService.h"

@interface TimelineService ()
@property (weak) APIService *apiService;
@property (copy) NSString *timelineUserId;
@property (strong) NSMutableArray *timelineArray;
@property (strong) NSLock *timelineLock;

@end

@implementation TimelineService
const NSUInteger kLoadingTweetCountAtOnce = 100;//50;
const NSUInteger kMaximumBackupTweetCount = 500;

const NSString *kTimelineCacheGroupName = @"timelines";

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
        self.timelineLock = [[NSLock alloc] init];
    }
    return self;
}

- (instancetype)resumeFromCache
{
    NSString *identifier = self.apiService.account.identifier;
    NSString *tweetsURLString = [FileCacheService urlStringWithName:identifier group:(NSString *)kTimelineCacheGroupName];

    NSArray *array = [[FileCacheService sharedService] readCacheFileFromURLString:tweetsURLString];
    if (array) {
        [self.timelineLock lock];
        for (NSDictionary *dic in array) {
            MyTwitterObj *obj = nil;
            if ([MyTweetJoint isSuitableForJoint:dic]) {
                obj = [[MyTweetJoint alloc] initWithDictionary:dic];
            } else {
                obj = [[MyTweet alloc] initWithDictionary:dic];
            }
            [self.timelineArray addObject:obj];
        }
        [self.timelineLock unlock];
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
    
    [self.timelineLock lock];
    
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
                [self saveTimelineToFile];
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            handler(startIndex, count, error);
            [self.timelineLock unlock];
        });
    };
    
    BOOL requested = NO;
    if (self.timelineUserId) {
        requested = [self.apiService getUserTimeLineWithUserId:self.timelineUserId count:kLoadingTweetCountAtOnce rangeFrom:rangeFrom rangeTo:nil completion:apiHandler];
    } else {
        requested = [self.apiService getHomeTimeLineWithCount:kLoadingTweetCountAtOnce rangeFrom:rangeFrom rangeTo:nil completion:apiHandler];
    }
    
    if (!requested) {
        [self.timelineLock unlock];
    }
    return requested;
}

- (BOOL)loadJointAtIndex:(NSUInteger)index completion:(TimelineServiceLoadCompletionHandler)handler;
{
    if (!handler) {
        return NO;
    }
    
    if (index >= self.timelineArray.count) {
        return NO;
    }
    
    [self.timelineLock lock];
    
    id obj = [self.timelineArray objectAtIndex:index];
    if (![obj isKindOfClass:[MyTweetJoint class]]) {
        [self.timelineLock unlock];
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
            [self saveTimelineToFile];
            
            if (removeJoint) {
                count--;
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            handler(startIndex, count, error);
            [self.timelineLock unlock];
        });
    };
    
    BOOL requested = NO;
    if (self.timelineUserId) {
        requested =  [self.apiService getUserTimeLineWithUserId:self.timelineUserId count:kLoadingTweetCountAtOnce + 1 rangeFrom:joint.from rangeTo:joint.to completion:apiHandler];
    } else {
        requested =  [self.apiService getHomeTimeLineWithCount:kLoadingTweetCountAtOnce rangeFrom:joint.from rangeTo:joint.to completion:apiHandler];
    }
    
    if (!requested) {
        [self.timelineLock unlock];
    }
    return requested;
}

- (void)saveTimelineToFile
{
    if (self.timelineUserId) {
        return;
    }
    
    NSString *identifier = self.apiService.account.identifier;
    NSString *userFileName = [NSString stringWithFormat:@"%@.users", identifier];
    
    [[FileCacheService sharedService] createCacheFileDirectoryWithGroupName:(NSString *)kTimelineCacheGroupName];
    
    //[self.timelineLock lock];
    NSArray *tweets = self.timelineArray;
    if (tweets.count > kMaximumBackupTweetCount) {
        tweets = [tweets subarrayWithRange:NSMakeRange(0, kMaximumBackupTweetCount)];
    }
    
    if (tweets.count > 0) {
        NSMutableSet *userSet = [[NSMutableSet alloc] init];
        NSMutableArray *saveTweetArray = [[NSMutableArray alloc] init];
        for (MyTwitterObj *obj in tweets) {
            [saveTweetArray addObject:obj.dictionary];
            if ([obj isKindOfClass:[MyTweet class]]) {
                MyTweet *tw = (MyTweet *)obj;
                [userSet addObject:tw.userId];
                if (tw.retweet) {
                    [userSet addObject:tw.retweet.userId];
                }
            }
        }
        if (userSet.count > 0) {
            dispatch_semaphore_t waitingSemaphore = dispatch_semaphore_create(0);
            [self.apiService.userCache prefetchWithKeys:[userSet allObjects] forceReloading:NO completion:^(NSDictionary *dictionary) {
                NSMutableArray *saveUserArray = [[NSMutableArray alloc] init];
                for (MyUser *user in dictionary.allValues) {
                    [saveUserArray addObject:user.dictionary];
                }
                NSString *usersURLString = [FileCacheService urlStringWithName:userFileName group:(NSString *)kTimelineCacheGroupName];
                [[FileCacheService sharedService] writeCacheFileToURLString:usersURLString array:saveUserArray];
                dispatch_semaphore_signal(waitingSemaphore);
            }];
            dispatch_semaphore_wait(waitingSemaphore, DISPATCH_TIME_FOREVER);
        }
        NSString *tweetsURLString = [FileCacheService urlStringWithName:identifier group:(NSString *)kTimelineCacheGroupName];
        [[FileCacheService sharedService] writeCacheFileToURLString:tweetsURLString array:saveTweetArray];
    } else {
        FileCacheService *service = [FileCacheService sharedService];
        [service removeCacheFileWithName:identifier group:(NSString *)kTimelineCacheGroupName];
        [service removeCacheFileWithName:userFileName group:(NSString *)kTimelineCacheGroupName];
    }
    //[self.timelineLock unlock];
}
@end
