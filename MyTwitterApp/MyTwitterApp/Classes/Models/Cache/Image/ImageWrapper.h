//
//  ImageWrapper.h
//  twitterSample
//
//  Created by 大久保直昭 on 2015/07/25.
//  Copyright (c) 2015年 大久保直昭. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "MyCacheContent.h"

@interface ImageWrapper : NSObject<MyCacheContent>
- (instancetype) __unavailable init;
- (instancetype)initWithData:(NSData *)data cacheGroupName:(NSString *)cacheGroupName url:(NSString *)url timestamp:(NSDate *)timestamp;
- (instancetype)initWithCachedName:(NSString *)cachedName cacheGroupName:(NSString *)cacheGroupName url:(NSString *)url timestamp:(NSDate *)timestamp;
@end
