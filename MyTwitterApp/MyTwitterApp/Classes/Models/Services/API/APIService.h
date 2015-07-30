//
//  APIService.h
//  twitterSample
//
//  Created by 大久保直昭 on 2015/07/24.
//  Copyright (c) 2015年 大久保直昭. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Accounts/Accounts.h>
#import <Social/Social.h>
#import "ConnectionService.h"
#import "MyCache.h"
#import "MyTweet.h"
#import "MyUser.h"

typedef void(^APIServiceResponseHandler)(NSArray *result, NSError *error);

typedef NS_ENUM(NSInteger, kAPIServiceErrorCode) {
    kAPIServiceErrorApiRateLimited,
    kAPIServiceErrorInvalidUserId
};

@interface APIService : NSObject
/// APIに使用するTwitterアカウント
@property (readonly, weak) ACAccount *account;
/// ユーザーキャッシュ
@property (readonly, strong) MyCache *userCache;

/// initは使わない
- (instancetype) __unavailable init;

/// Twitterアカウントを利用してクラスを初期化する
- (instancetype)initWithAccount:(ACAccount *)account;

/// fromは含まないが、toは含むことに留意すること！
- (BOOL)getHomeTimeLineWithCount:(NSUInteger)count rangeFrom:(NSString *)from rangeTo:(NSString *)to completion:(APIServiceResponseHandler)handler;
- (BOOL)getUserTimeLineWithUserId:(NSString *)userId count:(NSUInteger)count rangeFrom:(NSString *)from rangeTo:(NSString *)to completion:(APIServiceResponseHandler)handler;

- (BOOL)sendTweet:(NSString *)body replyTo:(NSString *)tweetId completion:(APIServiceResponseHandler)handler;
@end
