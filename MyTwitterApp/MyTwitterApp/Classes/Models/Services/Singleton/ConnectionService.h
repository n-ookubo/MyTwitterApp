//
//  ConnectionService.h
//  twitterSample
//
//  Created by 大久保直昭 on 2015/07/25.
//  Copyright (c) 2015年 大久保直昭. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ConnectionService : NSObject
- (instancetype) __unavailable init;
+ (ConnectionService *)sharedService;
+ (void)setConnectionLimit:(long)limit;
+ (void)setTimeoutInterval:(NSTimeInterval)interval;

+ (NSError *)createErrorWithHttpStatus:(NSInteger)status;

- (NSString *)addDataTaskWithURL:(NSURL *)url completionHandler:(void (^)(NSData *data, NSHTTPURLResponse *response, NSError *error))completionHandler;
- (NSString *)addDataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *data, NSHTTPURLResponse *response, NSError *error))completionHandler;
- (void)cancelDataTaskWithIdentifier:(NSString *)identifier;
- (void)cancelAllDataTask;
@end
