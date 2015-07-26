//
//  MyCacheContent.h
//  twitterSample
//
//  Created by 大久保直昭 on 2015/07/24.
//  Copyright (c) 2015年 大久保直昭. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MyCacheContent <NSDiscardableContent>
// NSObjectがMyCacheによってキャッシュされている場合に
// MyCacheがキャッシュ内容として返す値を生成する
- (id)cachedValue;
@end