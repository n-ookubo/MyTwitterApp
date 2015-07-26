//
//  NSString+MD5.m
//  twitterSample
//
//  Created by 大久保直昭 on 2015/07/26.
//  Copyright (c) 2015年 大久保直昭. All rights reserved.
//

#import "NSString+MD5.h"
#import <CommonCrypto/CommonCrypto.h>

@implementation NSString (MD5)
- (NSString *)md5Hash
{
    if (self.length == 0) {
        return nil;
    }
    
    const char *data = [self UTF8String];
    CC_LONG len = (CC_LONG)strlen(data);
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(data, len, result);
    
    NSMutableString *hash = [[NSMutableString alloc] init];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [hash appendFormat:@"%02X", result[i]];
    }
    return [[NSString alloc] initWithString:hash];
}

@end
