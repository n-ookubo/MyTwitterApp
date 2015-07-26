//
//  ConnectionService.m
//  twitterSample
//
//  Created by 大久保直昭 on 2015/07/25.
//  Copyright (c) 2015年 大久保直昭. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ConnectionService.h"

@interface ConnectionService ()
{
    NSUInteger connectionLimit;
    NSTimeInterval timeoutInterval;
    
    dispatch_semaphore_t connectionLimitSemaphore;
    dispatch_queue_t connectionQueue;
    
    NSMutableSet *queuedSet;
    NSLock *queuedSetLock;
    
    NSMutableDictionary *taskDictionary;
    NSLock *taskDictionaryLock;
}

@end

@implementation ConnectionService
static ConnectionService *sharedService = nil;
static long serviceInitialConnectionLimit = 2;
static NSTimeInterval serviceInitialTimeoutInterval = 60.0;

- (instancetype)init
{
    [NSException raise:NSGenericException format:@"init is not available. use [%@  %@] instead.", NSStringFromClass(self.class), NSStringFromSelector(@selector(sharedService))];
    return nil;
}

+ (ConnectionService *)sharedService
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedService = [[ConnectionService alloc] initWithConnectionLimit:serviceInitialConnectionLimit timeout:serviceInitialTimeoutInterval];
    });
    return sharedService;
}

+ (void)setConnectionLimit:(long)limit
{
    if (limit > 0) {
        serviceInitialConnectionLimit = limit;
    }
}

+ (void)setTimeoutInterval:(NSTimeInterval)interval
{
    if (interval > 0.0) {
        serviceInitialTimeoutInterval = interval;
    }
}

+ (NSError *)createErrorWithHttpStatus:(NSInteger)status
{
    NSString *reason = [NSString stringWithFormat:@"HTTP Status %ld", (long)status];
    NSDictionary *userInfo = @{NSLocalizedDescriptionKey : reason};
    return [NSError errorWithDomain:@"jp.co.kenshu.httpstatus" code:status userInfo:userInfo];
}

- (instancetype)initWithConnectionLimit:(long)limit timeout:(NSTimeInterval)timeout
{
    self = [super init];
    if (self) {
        connectionLimit = limit;
        timeoutInterval = timeout;
        
        connectionQueue = dispatch_queue_create(NULL, DISPATCH_QUEUE_CONCURRENT);
        dispatch_set_target_queue(connectionQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
        connectionLimitSemaphore = dispatch_semaphore_create(limit);
        
        queuedSet = [[NSMutableSet alloc] init];
        queuedSetLock = [[NSLock alloc] init];
        
        taskDictionary = [[NSMutableDictionary alloc] init];
        taskDictionaryLock = [[NSLock alloc] init];
    }
    return self;
}

- (NSString *)addDataTaskWithURL:(NSURL *)url completionHandler:(void (^)(NSData *data, NSHTTPURLResponse *response, NSError *error))completionHandler
{
    return [self setUpDataTaskWithURL:url orWithRequest:nil completionHandler:completionHandler];
}
- (NSString *)addDataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *data, NSHTTPURLResponse *response, NSError *error))completionHandler
{
    return [self setUpDataTaskWithURL:nil orWithRequest:request completionHandler:completionHandler];
}

- (NSString *)setUpDataTaskWithURL:(NSURL *)url orWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *data, NSHTTPURLResponse *response, NSError *error))completionHandler
{
    if (!completionHandler || (!url && !request)) {
        return nil;
    }
    
    NSString *taskKey = [[NSUUID UUID] UUIDString];
    [queuedSetLock lock];
    if (queuedSet.count == 0) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    }
    [queuedSet addObject:taskKey];
    [queuedSetLock unlock];
    
    dispatch_async(connectionQueue, ^{
        dispatch_semaphore_wait(connectionLimitSemaphore, DISPATCH_TIME_FOREVER);
        
        [queuedSetLock lock];
        BOOL cancelled = ![queuedSet containsObject:taskKey];
        [queuedSetLock unlock];
        
        if (cancelled) {
            NSURL *causeUrl = url ? url :request.URL;
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey : @"cancelled",  NSURLErrorFailingURLErrorKey : causeUrl};
            NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:userInfo];
            
            completionHandler(nil, nil, error);
            
            dispatch_semaphore_signal(connectionLimitSemaphore);
            return;
        }
        
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        config.timeoutIntervalForRequest = timeoutInterval;
        config.timeoutIntervalForResource = timeoutInterval;
        NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
        
        dispatch_semaphore_t completionSemaphore = dispatch_semaphore_create(0);
        void (^dataTaskCompletionBlock) (NSData *data, NSURLResponse *response, NSError *error) = ^(NSData *data, NSURLResponse *response, NSError *error) {
            [queuedSetLock lock];
            [queuedSet removeObject:taskKey];
            if (queuedSet.count == 0) {
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            }
            [queuedSetLock unlock];
            
            [taskDictionaryLock lock];
            [taskDictionary removeObjectForKey:taskKey];
            [taskDictionaryLock unlock];
            
            completionHandler(data, (NSHTTPURLResponse *)response, error);
            [session invalidateAndCancel];
            
            dispatch_semaphore_signal(completionSemaphore);
        };
        
        NSURLSessionDataTask *task;
        if (url) {
            task = [session dataTaskWithURL:url completionHandler:dataTaskCompletionBlock];
        } else {
            task = [session dataTaskWithRequest:request completionHandler:dataTaskCompletionBlock];
        }
        
        [taskDictionaryLock lock];
        [taskDictionary setObject:task forKey:taskKey];
        [taskDictionaryLock unlock];
        
        NSLog(@"task start:%p", task);
        [task resume];
        dispatch_semaphore_wait(completionSemaphore, DISPATCH_TIME_FOREVER);
        NSLog(@"task finish:%p", task);
        dispatch_semaphore_signal(connectionLimitSemaphore);
    });
    
    return taskKey;
}

- (void)cancelDataTaskWithIdentifier:(NSString *)identifier
{
    if (!identifier) {
        return;
    }
    
    [queuedSetLock lock];
    [queuedSet removeObject:identifier];
    if (queuedSet.count == 0) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    }
    [queuedSetLock unlock];
    
    [taskDictionaryLock lock];
    NSURLSessionDataTask *task = [taskDictionary objectForKey:identifier];
    if (task) {
        [taskDictionary removeObjectForKey:identifier];
        [task cancel];
    }
    [taskDictionaryLock unlock];
}

- (void)cancelAllDataTask
{
    [queuedSetLock lock];
    [queuedSet removeAllObjects];
    [queuedSetLock unlock];
    
    [taskDictionaryLock lock];
    NSArray *array = [[NSArray alloc] initWithArray:[taskDictionary allValues]];
    [taskDictionary removeAllObjects];
    for (NSURLSessionDataTask *task in array) {
        [task cancel];
    }
    [taskDictionaryLock unlock];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}
@end
