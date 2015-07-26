//
//  NSString+NSLog.m
//  twitterSample
//
//  Created by 大久保直昭 on 2015/07/23.
//  Copyright (c) 2015年 大久保直昭. All rights reserved.
//

#import "NSString+NSLog.h"

@implementation NSString (NSLog)
- (NSString *)stringForNSLog
{
    const char *cstr = [self cStringUsingEncoding:NSASCIIStringEncoding];
    NSString *str = [NSString stringWithCString:cstr encoding:NSNonLossyASCIIStringEncoding];
    return str ? str : self;
}

@end