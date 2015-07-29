//
//  TwitterService.h
//  twitterSample
//
//  Created by 大久保直昭 on 2015/07/26.
//  Copyright (c) 2015年 大久保直昭. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Accounts/Accounts.h>
#include "APIService.h"
#include "TimelineService.h"

@interface TwitterService : NSObject
@property (readonly, strong) ACAccount *account;
@property (readonly, strong) APIService *apiService;
@property (readonly, strong) TimelineService *homeTimeline;

+ (NSUInteger)countTweetLength:(NSString *)str;

- (instancetype) __unavailable init;
- (instancetype)initWithAccount:(ACAccount *)account;
- (instancetype)resumeFromStorage;
@end
