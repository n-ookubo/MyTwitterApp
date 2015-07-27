//
//  MyImageCache.m
//  twitterSample
//
//  Created by 大久保直昭 on 2015/07/25.
//  Copyright (c) 2015年 大久保直昭. All rights reserved.
//

#import "MyImageCache.h"
#import "ConnectionService.h"
#import "FileCacheService.h"
#import "ImageWrapper.h"

@interface MyCache ()
- (NSCache *)cache;
@end

@interface MyImageCache ()
{
    NSString *cacheName;
    BOOL saveToFile;
    
    NSMutableDictionary *inFlightConnectionDictionary;
    NSLock *inFlightConnectionDictionaryLock;
}
@end

@implementation MyImageCache
- (instancetype) initWithHandler:(MyCacheMissRequestHandler)handler cancelHandler:(MyCacheMissCancelHandler)cancelHandler countLimit:(NSNumber *)countLimit totalCostLimit:(NSNumber *)totalCostLimit
{
    [NSException raise:NSGenericException format:@"initWithHandler:cancelHandler:countLimit:totalCostLimit: is not available. use [[%@ alloc] %@] instead.", NSStringFromClass(self.class), NSStringFromSelector(@selector(initWithCacheName:useStorage:countLimit:totalCostLimit:))];
    return nil;
}

- (instancetype)initWithCacheName:(NSString *)name useStorage:(BOOL)useStorage countLimit:(NSNumber *)countLimit totalCostLimit:(NSNumber *)totalCostLimit {
    
    __block NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    __block NSLock *dictionaryLock = [[NSLock alloc] init];
    self = [super initWithHandler:^(NSArray *keys, MyCacheMissResponseHandler handler) {
        NSMutableArray *remainingKeys = [[NSMutableArray alloc] initWithArray:keys];
        NSMutableDictionary *values = [[NSMutableDictionary alloc] init];
        NSMutableDictionary *costs = [[NSMutableDictionary alloc] init];
        NSMutableDictionary *errors = [[NSMutableDictionary alloc] init];
        NSLock *lock = [[NSLock alloc] init];
        
        dispatch_semaphore_t completionSemaphore = dispatch_semaphore_create(0);
        ConnectionService *service = [ConnectionService sharedService];
        //NSLog(@"request: %@", keys);
        for (NSString *key in keys) {
            NSString *identifier = [service addDataTaskWithURL:[NSURL URLWithString: key] completionHandler:^(NSData *data, NSHTTPURLResponse *response, NSError *error) {
                [lock lock];
                if (error) {
                    [errors setObject:error forKey:key];
                } else if (response.statusCode < 200 || response.statusCode >= 300 ) {
                    [errors setObject:[ConnectionService createErrorWithHttpStatus:response.statusCode] forKey:key];
                } else {
                    //NSLog(@"create ImageWrapper: %@", key);
                    ImageWrapper *image = [[ImageWrapper alloc] initWithData:data cacheGroupName:(useStorage ? name : nil) url:key timestamp:nil];
                    NSNumber *cost = [NSNumber numberWithUnsignedInteger:[data length]];
                    [values setObject:image forKey:key];
                    [costs setObject:cost forKey:key];
                }
                [remainingKeys removeObject:key];
                BOOL finished = (remainingKeys.count == 0);
                
                [dictionaryLock lock];
                [dictionary removeObjectForKey:key];
                [dictionaryLock unlock];
                
                [lock unlock];
                
                if (finished) {
                    dispatch_semaphore_signal(completionSemaphore);
                }
            }];
            
            [dictionaryLock lock];
            [dictionary setObject:identifier forKey:key];
            [dictionaryLock unlock];
        }
        dispatch_semaphore_wait(completionSemaphore, DISPATCH_TIME_FOREVER);
        
        [lock lock];
        handler(values, costs, errors);
        [lock unlock];
    } cancelHandler:^(NSString *key) {
        [dictionaryLock lock];
        NSString *identifier = [dictionary objectForKey:key];
        if (identifier) {
            [dictionary removeObjectForKey:key];
            
            [[ConnectionService sharedService] cancelDataTaskWithIdentifier:identifier];
        }
        [dictionaryLock unlock];
    } countLimit:countLimit totalCostLimit:totalCostLimit];
    if (self) {
        if (useStorage && !name) {
            [NSException raise:NSInvalidArgumentException format:@"name must not be nil if use storage."];
            return nil;
        }
        cacheName = name;
        saveToFile = useStorage;
        inFlightConnectionDictionary = dictionary;
        inFlightConnectionDictionaryLock = dictionaryLock;
    }
    return self;
}

- (instancetype)resumeCacheFromStorage
{
    if (!saveToFile) {
        return self;
    }
    
    NSDictionary *dic = [[FileCacheService sharedService] loadStoredImageDictionaryWithGroupName:cacheName];
    if (!dic) {
        return self;
    }
    NSDictionary *imageDictionary = [dic objectForKey:@"image"];
    NSDictionary *costDictionary = [dic objectForKey:@"cost"];
    
    NSCache *cache = [super cache];
    [imageDictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSString *url = key;
        ImageWrapper *wrapper = obj;
        NSNumber *cost = [costDictionary objectForKey:url];
        
        if (cache.totalCostLimit > 0 && cost) {
            [cache setObject:wrapper forKey:url cost:[cost unsignedIntegerValue]];
        } else {
            [cache setObject:wrapper forKey:url];
        }
        NSLog(@"resume %@ as %@", key, wrapper);
    }];
    return self;
}
@end
