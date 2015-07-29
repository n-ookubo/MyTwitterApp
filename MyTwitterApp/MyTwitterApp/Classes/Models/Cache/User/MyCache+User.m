//
//  MyCache+User.m
//  MyTwitterApp
//
//  Created by 大久保直昭 on 2015/07/28.
//  Copyright (c) 2015年 大久保直昭. All rights reserved.
//

#import "MyCache+User.h"
#import "FileCacheService.h"
#import "MyUser.h"
//#import "TimelineService.h"

extern const NSString *kTimelineCacheGroupName;

@interface MyCache ()
- (NSCache *)cache;
@end

@implementation MyCache (User)
- (instancetype)resumeFromCache:(ACAccount *)account
{
    if (!account) {
        return nil;
    }
    
    NSString *identifier = account.identifier;
    NSString *userFileName = [NSString stringWithFormat:@"%@.users", identifier];
    NSString *usersURLString = [FileCacheService urlStringWithName:userFileName group:(NSString *)kTimelineCacheGroupName];
    NSArray *array = [[FileCacheService sharedService] readCacheFileFromURLString:usersURLString];
    if (array) {
        NSCache *cache = [self cache];
        for (NSDictionary *dic in array) {
            MyUser *user = [[MyUser alloc] initWithDictionary:dic];
            [cache setObject:user forKey:user.userId];
        }
    }
    return self;
}
@end
