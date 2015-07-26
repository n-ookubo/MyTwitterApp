//
//  MyCache.h
//  twitterSample
//
//  Created by 大久保直昭 on 2015/07/24.
//  Copyright (c) 2015年 大久保直昭. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MyCacheMSHR.h"

///
typedef void (^MyCacheMissResponseHandler)(NSDictionary *values, NSDictionary *costs, NSDictionary *errors);
///
typedef void (^MyCacheMissRequestHandler)(NSArray *keys, MyCacheMissResponseHandler handler);

@interface MyCache : NSObject<NSCacheDelegate>

- (instancetype) __unavailable init;
- (instancetype)initWithHandler:(MyCacheMissRequestHandler)handler cancelHandler:(MyCacheMissCancelHandler)cancelHandler countLimit:(NSNumber *)countLimit totalCostLimit:(NSNumber *)totalCostLimit;
- (void)lookupWithKey:(NSString *)key owner:(id)owner handler:(MyCacheDataHandler)handler;
- (void)cancelLookupWithKey:(NSString *)key owner:(id)owner;
- (void)prefetchWithKeys:(NSArray *)keys forceReloading:(BOOL)reloading completion:(void (^)(void))handler;
@end
