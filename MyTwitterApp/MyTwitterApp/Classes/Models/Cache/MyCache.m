//
//  MyCache.m
//  twitterSample
//
//  Created by 大久保直昭 on 2015/07/24.
//  Copyright (c) 2015年 大久保直昭. All rights reserved.
//

#import "MyCache.h"

@interface MyCache ()
{
    MyCacheMissRequestHandler requestHandler;
    MyCacheMissCancelHandler missCancelHandler;
    
    dispatch_queue_t myCacheDispatchQueue;
    
    NSCache *cache;
    
    NSMutableDictionary *mshrDictionary;
    NSLock *mshrLock;
}

@end

@implementation MyCache
- (instancetype)init
{
    [NSException raise:NSGenericException format:@"init is not available. use [[%@ alloc] %@] instead.", NSStringFromClass(self.class), NSStringFromSelector(@selector(initWithHandler:cancelHandler:countLimit:totalCostLimit:))];
    return nil;
}

- (instancetype)initWithHandler:(MyCacheMissRequestHandler)handler cancelHandler:(MyCacheMissCancelHandler)cancelHandler countLimit:(NSNumber *)countLimit totalCostLimit:(NSNumber *)totalCostLimit
{
    self = [super init];
    if (self) {
        if (!handler) {
            return nil;
        }

        requestHandler = [handler copy];
        if (cancelHandler) {
            missCancelHandler = [cancelHandler copy];
        } else {
            missCancelHandler = nil;
        }
        cache = [[NSCache alloc] init];
        if (countLimit) {
            [cache setCountLimit:countLimit.unsignedIntegerValue];
        }
        if (totalCostLimit) {
            [cache setTotalCostLimit:totalCostLimit.unsignedIntegerValue];
        }
        mshrDictionary = [[NSMutableDictionary alloc] init];
        
        myCacheDispatchQueue = dispatch_queue_create(NULL, DISPATCH_QUEUE_CONCURRENT);
        dispatch_set_target_queue(myCacheDispatchQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
    }
    return self;
}

- (NSCache *)cache
{
    return cache;
}

- (void)lookupWithKey:(NSString *)key owner:(id)owner handler:(MyCacheDataHandler)handler
{
    if (!key) {
        return;
    }
    
    id<MyCacheContent> value = [cache objectForKey:key];
    if (value) {
        if (handler) {
            id cachedValue = [value cachedValue];
            dispatch_async(dispatch_get_main_queue(), ^{
                handler(key, cachedValue, nil);
            });
        }
        return;
    }
    
    BOOL mshrCreated = NO;
    
    [mshrLock lock];
    MyCacheMSHR *mshr = [mshrDictionary objectForKey:key];
    if (!mshr) {
        mshr = [[MyCacheMSHR alloc] initWithKey:key cancelHandler:missCancelHandler queue:myCacheDispatchQueue];
        [mshrDictionary setValue:mshr forKey:key];
        mshrCreated = YES;
    }
    
    if (handler) {
        [mshr addHandler:handler owner:owner];
    }
    [mshrLock unlock];
    
    if (mshrCreated) {
        NSArray *keys = @[key];
        dispatch_async(myCacheDispatchQueue, ^{
            requestHandler(keys, ^(NSDictionary *values, NSDictionary *costs, NSDictionary *errors) {
                [self handleMissResponseHandlerWithKeys:keys values:values costs:costs errors:errors];
            });
        });
    }
}

- (void)prefetchWithKeys:(NSArray *)keys forceReloading:(BOOL)reloading completion:(void (^)(void))handler
{
    if (!keys) {
        return;
    }
    
    NSMutableArray *uncachedKeys = [[NSMutableArray alloc] init];
    for (NSString *key in keys) {
        if(reloading || ![cache objectForKey:key]) {
            [uncachedKeys addObject:key];
        }
    }
    
    [mshrLock lock];
    NSMutableArray *unRequestedKeys = [[NSMutableArray alloc] init];
    for (NSString *key in uncachedKeys) {
        if (![mshrDictionary objectForKey:key]) {
            MyCacheMSHR *mshr = [[MyCacheMSHR alloc] initWithKey:key cancelHandler:missCancelHandler queue:myCacheDispatchQueue];
            [mshrDictionary setValue:mshr forKey:key];
            [unRequestedKeys addObject:key];
        }
    }
    
    if (unRequestedKeys.count > 0) {
        void (^completionHandler)() = [handler copy];
        dispatch_async(myCacheDispatchQueue, ^{
            requestHandler(unRequestedKeys, ^(NSDictionary *values, NSDictionary *costs, NSDictionary *errors) {
                [self handleMissResponseHandlerWithKeys:unRequestedKeys values:values costs:costs errors:errors];
                if (completionHandler) {
                    dispatch_async(dispatch_get_main_queue(), completionHandler);
                }
            });
        });
    }
    [mshrLock unlock];
    
}

- (void)handleMissResponseHandlerWithKeys:(NSArray *)keys values:(NSDictionary *)values costs:(NSDictionary *)costs errors:(NSDictionary *)errors
{
    if (!keys || !values || !errors) {
        [NSException raise:NSInvalidArgumentException format:@"MyCacheMissResponseHandler: invalid arguments."];
    }
    
    for (NSString *key in keys) {
        id value = [values objectForKey:key];
        NSError *error = [errors objectForKey:key];
        if (!error) {
            if (value) {
                if (![value conformsToProtocol:@protocol(MyCacheContent)]) {
                    [NSException raise:NSInvalidArgumentException format:@"MyCacheMissResponseHandler: value['%@'] is not match for id<%@>", key, @protocol(MyCacheContent)];
                }
                
                NSNumber *cost;
                if (cache.totalCostLimit > 0 && costs && (cost = [costs objectForKey:key])) {
                    [cache setObject:value forKey:key cost:[cost unsignedIntegerValue]];
                } else {
                    [cache setObject:value forKey:key];
                }
            } else {
                [NSException raise:NSInvalidArgumentException format:@"MyCacheMissResponseHandler: value['%@'] and errors['%@'] are both nil.", key, key];
            }
        }

        [mshrLock lock];
        MyCacheMSHR *mshr = [mshrDictionary objectForKey:key];
        if (mshr) {
            [mshr performHandlersWithValue:value error:error];
            [mshrDictionary removeObjectForKey:key];
        }
        [mshrLock unlock];
    }
}


- (void)cancelLookupWithKey:(NSString *)key owner:(id)owner
{
    if (!key) {
        return;
    }
    
    [mshrLock lock];
    MyCacheMSHR *mshr = [mshrDictionary objectForKey:key];
    if (mshr) {
        if ([mshr cancelHandlerWithOwner:owner] == 0) {
            [mshrDictionary removeObjectForKey:key];
        }
    }
    [mshrLock unlock];
}
@end
