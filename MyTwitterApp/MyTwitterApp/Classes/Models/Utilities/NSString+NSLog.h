//
//  NSString+NSLog.h
//  twitterSample
//
//  Created by 大久保直昭 on 2015/07/23.
//  Copyright (c) 2015年 大久保直昭. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (NSLog)
/**
 NSLogでマルチバイト文字を出力させるため、文字列を変換する
 
 @return 変換済み文字列
 */
- (NSString *)stringForNSLog;
@end