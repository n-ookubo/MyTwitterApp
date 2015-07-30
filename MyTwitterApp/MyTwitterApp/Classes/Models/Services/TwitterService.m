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
+ (NSUInteger)countTweetLength:(NSString *)str
{
    if (!str) {
        return 0;
    }
    
    NSUInteger count = str.length;
    
    NSDataDetector *detector = [[NSDataDetector alloc] initWithTypes:NSTextCheckingTypeLink error:nil];
    NSArray *matches = [detector matchesInString:str options:0 range:NSMakeRange(0, [str length])];
    for (NSTextCheckingResult *result in matches) {
        NSString *urlString = [result.URL absoluteString];
        NSUInteger baseCount = result.range.length;
        if ([urlString hasPrefix:@"http://"]) {
            baseCount = 22;
        } else if ([urlString hasPrefix:@"https://"]) {
            baseCount = 23;
        }
        count += (baseCount - result.range.length);
    }
    return count;
}

+ (BOOL)isNotEmptyStringAsTweet:(NSString *)str
{
    return str && ([str stringByReplacingOccurrencesOfString:@" " withString:@""].length > 0);
}

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
