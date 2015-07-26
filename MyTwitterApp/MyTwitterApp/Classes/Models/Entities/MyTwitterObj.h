//
//  MyObj.h
//  twitterSample
//
//  Created by 大久保直昭 on 2015/07/23.
//  Copyright (c) 2015年 大久保直昭. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSString+NSLog.h"

/**
 Twitterのオブジェクトを表す基底クラス
 */
@interface MyTwitterObj : NSObject
/// JSONデータを変換したNSDictionary
@property (strong, readonly) NSDictionary *dictionary;

/// initは使わない
- (instancetype) __unavailable init;

/**
 JSONデータを変換したNSDictionaryを利用してクラスを初期化する
 */
- (instancetype)initWithDictionary:(NSDictionary *)dic;
@end
