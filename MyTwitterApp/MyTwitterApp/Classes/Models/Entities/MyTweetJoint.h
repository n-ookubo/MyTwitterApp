//
//  MyTweetJoint.h
//  twitterSample
//
//  Created by 大久保直昭 on 2015/07/26.
//  Copyright (c) 2015年 大久保直昭. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MyTwitterObj.h"

@interface MyTweetJoint : MyTwitterObj
@property (copy) NSString *from;
@property (copy) NSString *to;

+ (BOOL)isSuitableForJoint:(NSDictionary *)dic;

- (instancetype)initFrom:(NSString *)from to:(NSString *)to;
@end
