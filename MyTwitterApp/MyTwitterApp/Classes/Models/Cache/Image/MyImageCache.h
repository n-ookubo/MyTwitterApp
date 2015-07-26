//
//  MyImageCache.h
//  twitterSample
//
//  Created by 大久保直昭 on 2015/07/25.
//  Copyright (c) 2015年 大久保直昭. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MyCache.h"

@interface MyImageCache : MyCache
- (instancetype) __unavailable initWithHandler:(MyCacheMissRequestHandler)handler cancelHandler:(MyCacheMissCancelHandler)cancelHandler countLimit:(NSNumber *)countLimit totalCostLimit:(NSNumber *)totalCostLimit;
- (instancetype)initWithCacheName:(NSString *)name useStorage:(BOOL)useStorage countLimit:(NSNumber *)countLimit totalCostLimit:(NSNumber *)totalCostLimit;

- (instancetype)resumeCacheFromStorage;
@end
