//
//  TwitterService.m
//  twitterSample
//
//  Created by 大久保直昭 on 2015/07/26.
//  Copyright (c) 2015年 大久保直昭. All rights reserved.
//

#import "TwitterService.h"

@interface TwitterService ()
@property (strong, readwrite) ACAccount *account;
@property (strong, readwrite) APIService *apiService;
@property (strong, readwrite) TimelineService *homeTimeline;

@end

@implementation TwitterService
- (instancetype)init
{
    [NSException raise:NSGenericException format:@"init is not available. use [[%@ alloc] %@] instead.", NSStringFromClass(self.class), NSStringFromSelector(@selector(initWithAccount:))];
    return nil;
}

- (instancetype)initWithAccount:(ACAccount *)account
{
    self = [super init];
    if (self) {
        if (!account) {
            return nil;
        }
        
        self.account = account;
        self.apiService = [[APIService alloc] initWithAccount:account];
        //self.apiService.userCache
        self.homeTimeline = [[[TimelineService alloc] initWithAPIService:self.apiService timelineUserId:nil] resumeFromCache];
    }
    return self;
}

- (instancetype)resumeFromStorage
{
    return self;
}
@end
