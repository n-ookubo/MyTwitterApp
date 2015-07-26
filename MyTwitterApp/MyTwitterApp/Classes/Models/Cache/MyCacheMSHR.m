//
//  MyCacheMSHR.m
//  twitterSample
//
//  Created by 大久保直昭 on 2015/07/24.
//  Copyright (c) 2015年 大久保直昭. All rights reserved.
//

#import "MyCacheMSHR.h"

@interface MyCacheMSHR ()
{
    NSLock *lock;
    NSString *entryKey;
    NSMutableDictionary *dictionaryHandlers;
    MyCacheMissCancelHandler cancelHandler;
    dispatch_queue_t myCacheQueue;
}

@end

@implementation MyCacheMSHR
- (instancetype)init
{
    [NSException raise:NSGenericException format:@"init is not available. use [[%@ alloc] %@] instead.", NSStringFromClass(self.class), NSStringFromSelector(@selector(initWithKey:cancelHandler:queue:))];
    return nil;
}

- (instancetype)initWithKey:(NSString *)key cancelHandler:(MyCacheMissCancelHandler)handler queue:(dispatch_queue_t)queue;
{
    self = [super init];
    if (self) {
        if (!key || !queue) {
            return nil;
        }
        
        lock = [[NSLock alloc] init];
        entryKey = key;
        dictionaryHandlers = [[NSMutableDictionary alloc] init];
        cancelHandler = handler;
    }
    return self;
}

- (void)addHandler:(MyCacheDataHandler)handler owner:(id)owner
{
    if (!handler) {
        return;
    }
    
    NSString *ownerIdentifier = [NSString stringWithFormat:@"%p", owner];
    [lock lock];
    [dictionaryHandlers setObject:[handler copy] forKey:ownerIdentifier];
    [lock unlock];
}
- (NSUInteger)cancelHandlerWithOwner:(id)owner
{
    NSString *ownerIdentifier = [NSString stringWithFormat:@"%p", owner];
    [lock lock];
    if ([dictionaryHandlers objectForKey:ownerIdentifier]) {
        [dictionaryHandlers removeObjectForKey:ownerIdentifier];
        if (dictionaryHandlers.count == 0 && cancelHandler) {
            NSString *key = entryKey;
            dispatch_async(myCacheQueue, ^{
                cancelHandler(key);
            });
        }
    }
    NSUInteger handlerCount = dictionaryHandlers.count;
    [lock unlock];
    
    return handlerCount;
}

- (void)performHandlersWithValue:(id<MyCacheContent>)value error:(NSError *)error
{
    if (!value && !error) {
        return;
    }
    
    [lock lock];
    NSArray *handlers = [[NSArray alloc] initWithArray:[dictionaryHandlers allValues]];
    [dictionaryHandlers removeAllObjects];
    [lock unlock];
    
    if (handlers.count > 0){
        NSString *key = entryKey;
        id cachedValue = [value cachedValue];
        dispatch_async(dispatch_get_main_queue(), ^{
            for (MyCacheDataHandler handler in handlers) {
                handler(key, cachedValue, error);
            }
        });
    }
}

@end
