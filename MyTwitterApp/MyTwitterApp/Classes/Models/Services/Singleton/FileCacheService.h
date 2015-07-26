//
//  FileCacheService.h
//  twitterSample
//
//  Created by 大久保直昭 on 2015/07/26.
//  Copyright (c) 2015年 大久保直昭. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FileCacheService : NSObject
- (instancetype) __unavailable init;
+ (FileCacheService *)sharedService;
+ (void)setExpiresInHours:(NSTimeInterval)hours;
+ (NSString *)urlStringWithName:(NSString *)name group:(NSString *)groupName;

- (NSTimeInterval)expiresInHours;

- (NSDictionary *)loadStoredImageDictionaryWithGroupName:(NSString *)groupName;

- (NSString *)setData:(NSData *)data forGroup:(NSString *)groupName asUrlString:(NSString *)urlString;
- (void)removeFileWithName:(NSString *)name group:(NSString *)groupName;
@end
