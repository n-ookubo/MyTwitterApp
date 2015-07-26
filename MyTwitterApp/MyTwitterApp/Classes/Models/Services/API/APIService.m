//
//  APIService.m
//  twitterSample
//
//  Created by 大久保直昭 on 2015/07/24.
//  Copyright (c) 2015年 大久保直昭. All rights reserved.
//

#import "APIService.h"

@interface APIService ()
@property (weak, readwrite) ACAccount *account;
@property (strong, readwrite) MyCache *userCache;
@property (strong, readwrite) NSMutableDictionary *lastAccessed;

@end

@implementation APIService
const NSString *kHomeTimelineApiUrlString = @"https://api.twitter.com/1.1/statuses/home_timeline.json";
const NSString *kUserTimelineApiUrlString = @"https://api.twitter.com/1.1/statuses/user_timeline.json";
const NSString *kUserLookupApiUrlString = @"https://api.twitter.com/1.1/users/lookup.json";

const NSTimeInterval kHomeTimelineApiRateLimit = 60.0;
const NSTimeInterval kUserTimelineApiRateLimit = 5.0;
const NSTimeInterval kUserLookupApiRateLimit = 5.0;

+ (NSMutableArray *)parseTweetArrayWithData:(NSData *)data userset:(NSMutableSet **)set error:(NSError **)error
{
    NSArray *parsedArray = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:error];
    if (!*error) {
        NSMutableArray *tweetArray = [[NSMutableArray alloc] init];
        NSMutableSet *userSet = [[NSMutableSet alloc] init];
        for (NSDictionary *dic in parsedArray) {
            MyTweet *tweet = [[MyTweet alloc] initWithDictionary:dic];
            [tweetArray addObject:tweet];
            
            NSDictionary *user = [dic objectForKey:@"user"];
            NSString *userId = [user objectForKey:@"id_str"];
            [userSet addObject:userId];
        }
        *error = nil;
        *set = userSet;
        return tweetArray;
    }
    return nil;
}

+ (NSMutableArray *)parseUserArrayWithData:(NSData *)data error:(NSError **)error
{
    NSArray *parsedArray = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:error];
    if (!*error) {
        NSMutableArray *userArray = [[NSMutableArray alloc] init];
        for (NSDictionary *dic in parsedArray) {
            MyUser *user = [[MyUser alloc] initWithDictionary:dic];
            [userArray addObject:user];
        }
        *error = nil;
        return userArray;
    }
    return nil;
}

+ (NSError *)createApiRateLimitedError
{
    NSDictionary *userInfo = @{NSLocalizedDescriptionKey : @"api rate limited"};
    return [NSError errorWithDomain:@"jp.co.kenshu.APIService" code:kAPIServiceErrorApiRateLimited userInfo:userInfo];
}

+ (NSError *)createInvalidUserIdError
{
    NSDictionary *userInfo = @{NSLocalizedDescriptionKey : @"invalid user_id"};
    return [NSError errorWithDomain:@"jp.co.kenshu.APIService" code:kAPIServiceErrorInvalidUserId userInfo:userInfo];
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
        self.userCache = [self createUserCache];
    }
    return self;
}

- (MyCache *)createUserCache
{
    __block APIService *weakSelf = self;
    return [[MyCache alloc] initWithHandler:^(NSArray *keys, MyCacheMissResponseHandler handler) {
        BOOL rateLimitOK = [weakSelf getUsersWithArray:keys completion:^(NSArray *result, NSError *error) {
            NSMutableArray *remainingKeys = [[NSMutableArray alloc] initWithArray:keys];
            NSMutableDictionary *values = [[NSMutableDictionary alloc] init];
            NSMutableDictionary *costs = [[NSMutableDictionary alloc] init];
            NSMutableDictionary *errors = [[NSMutableDictionary alloc] init];
            for (MyUser *user in result) {
                [values setObject:user forKey:user.userId];
                [remainingKeys removeObject:user.userId];
            }
            for (NSString *k in remainingKeys) {
                [errors setObject:[APIService createInvalidUserIdError] forKey:k];
            }
            handler(values, costs, errors);
        }];
        
        if (!rateLimitOK) {
            NSMutableDictionary *values = [[NSMutableDictionary alloc] init];
            NSMutableDictionary *costs = [[NSMutableDictionary alloc] init];
            NSMutableDictionary *errors = [[NSMutableDictionary alloc] init];
            for (NSString *k in keys) {
                [errors setObject:[APIService createApiRateLimitedError] forKey:k];
            }
            handler(values, costs, errors);
        }
    } cancelHandler:nil countLimit:nil totalCostLimit:nil];
}

- (BOOL)accessToApiWithUrlString:(const NSString *)urlString method:(SLRequestMethod)method param:(NSDictionary *)param limitSeconds:(NSTimeInterval)limit completionHandler:(void (^)(NSData *data, NSHTTPURLResponse *response, NSError *error))handler
{
    NSDate *lastAccessed = [self.lastAccessed objectForKey:urlString];
    NSDate *now = [NSDate date];
    NSTimeInterval interval = [now timeIntervalSinceDate:lastAccessed];
    if (interval < limit) {
        // 指定した間隔より短い
        return NO;
    }
    [self.lastAccessed setObject:now forKey:urlString];
    
    SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:method URL:[NSURL URLWithString:(NSString *)urlString] parameters:param];
    request.account = self.account;
                          
    [[ConnectionService sharedService] addDataTaskWithRequest:[request preparedURLRequest] completionHandler:handler];
    return YES;
}

- (BOOL)getHomeTimeLineWithCount:(NSUInteger)count rangeFrom:(NSString *)from rangeTo:(NSString *)to completion:(APIServiceResponseHandler)handler
{
    if (!handler) {
        return NO;
    }
    
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    return [self getTimeLineWithURLString:kHomeTimelineApiUrlString limitSeconds:kHomeTimelineApiRateLimit parameters:dic count:count rangeFrom:from rangeTo:to completion:handler];
}

- (BOOL)getUserTimeLineWithUserId:(NSString *)userId count:(NSUInteger)count rangeFrom:(NSString *)from rangeTo:(NSString *)to completion:(APIServiceResponseHandler)handler{
    if (!userId || !handler) {
        return NO;
    }
    
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    [dic setObject:userId forKey:@"user_id"];
    return [self getTimeLineWithURLString:kUserTimelineApiUrlString limitSeconds:kUserTimelineApiRateLimit parameters:dic count:count rangeFrom:from rangeTo:to completion:handler];
}

- (BOOL)getTimeLineWithURLString:(const NSString *)urlString limitSeconds:(NSTimeInterval)limitSeconds parameters:(NSMutableDictionary *)parameter count:(NSUInteger)count rangeFrom:(NSString *)from rangeTo:(NSString *)to completion:(APIServiceResponseHandler)handler
{
    [parameter setObject:@"1" forKey:@"trim_user"];
    if (count > 200) {
        count = 200;
    }
    [parameter setObject:[NSString stringWithFormat:@"%lu", (unsigned long)count] forKey:@"count"];
    if (from) {
        [parameter setObject:from forKey:@"since_id"];
    }
    if (to) {
        [parameter setObject:to forKey:@"max_id"];
    }
    
    __block APIService *weakSelf = self;
    return [self accessToApiWithUrlString:urlString method:SLRequestMethodGET param:parameter limitSeconds:limitSeconds completionHandler:^(NSData *data, NSHTTPURLResponse *response, NSError *error) {
        NSError *errorForHandler = nil;
        if (error) {
            errorForHandler = error;
        } else if (response.statusCode < 200 || response.statusCode >= 300 ) {
            errorForHandler = [ConnectionService createErrorWithHttpStatus:response.statusCode];
        } else {
            //succeed
            NSMutableSet *userSet = nil;
            NSMutableArray *tweetArray = [APIService parseTweetArrayWithData:data userset:&userSet error:&errorForHandler];
            if (!errorForHandler && tweetArray && userSet) {
                [weakSelf.userCache prefetchWithKeys:[userSet allObjects] forceReloading:YES completion:^{
                    handler(tweetArray, errorForHandler);
                }];
                return;
            }
        }
        handler(nil, errorForHandler);
    }];
}

- (BOOL)getUsersWithArray:(NSArray *)userIds completion:(APIServiceResponseHandler)handler
{
    if (!userIds || userIds.count == 0 || !handler) {
        return NO;
    }
    
    NSMutableDictionary *parameter = [[NSMutableDictionary alloc] init];
    
    NSMutableString *users = [[NSMutableString alloc] init];
    for (NSString *userId in userIds) {
        if (users.length > 0) {
            [users appendString:@","];
        }
        [users appendString:userId];
    }
    [parameter setObject:users forKey:@"user_id"];
    
    return [self accessToApiWithUrlString:kUserLookupApiUrlString method:SLRequestMethodGET param:parameter limitSeconds:kUserLookupApiRateLimit completionHandler:^(NSData *data, NSHTTPURLResponse *response, NSError *error) {
        NSArray *resultArray = nil;
        NSError *errorForHandler = nil;
        if (error) {
            errorForHandler = error;
        } else if (response.statusCode < 200 || response.statusCode >= 300 ) {
            errorForHandler = [ConnectionService createErrorWithHttpStatus:response.statusCode];
        } else {
            resultArray = [APIService parseUserArrayWithData:data error:&errorForHandler];
        }
        
        handler(resultArray, errorForHandler);
    }];
}
@end
