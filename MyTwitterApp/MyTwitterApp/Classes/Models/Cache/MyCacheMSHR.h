//
//  MyCacheMSHR.h
//  twitterSample
//
//  Created by 大久保直昭 on 2015/07/24.
//  Copyright (c) 2015年 大久保直昭. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MyCacheContent.h"

typedef void (^MyCacheDataHandler) (NSString *key, id value, NSError *error);

typedef void (^MyCacheMissCancelHandler)(NSString *key);

@interface MyCacheMSHR : NSObject
- (instancetype) __unavailable init;
- (instancetype)initWithKey:(NSString *)key cancelHandler:(MyCacheMissCancelHandler)handler queue:(dispatch_queue_t)queue;
- (void)addHandler:(MyCacheDataHandler)handler owner:(id)owner;
- (NSUInteger)cancelHandlerWithOwner:(id)owner;
- (void)performHandlersWithValue:(id<MyCacheContent>)value error:(NSError *)error;

@end
