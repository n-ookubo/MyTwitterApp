//
//  UIImageView+MyImageCache.h
//  twitterSample
//
//  Created by 大久保直昭 on 2015/07/26.
//  Copyright (c) 2015年 大久保直昭. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MyImageCache.h"

typedef void (^UIImageViewSetContentHandler) (UIImageView *view);
typedef void (^UIImageViewSetContentWithImageHandler) (UIImageView *view, UIImage *image);

@interface UIImageView (MyImageCache)
- (void)setImageCache:(MyImageCache *)cache;

- (void)useActivityIndicator:(BOOL)useIndicator;
- (void)setActivityIndicatorStyle:(UIActivityIndicatorViewStyle)style;

- (void)setPlaceholderHandler:(UIImageViewSetContentHandler)handler;
- (void)setLoadingFailedHandler:(UIImageViewSetContentHandler)handler;
- (void)setImageLoadingCompletionHandler:(UIImageViewSetContentWithImageHandler)handler;

- (void)setViewImageWithURLString:(NSString *)urlString;
- (void)showPlaceHolder;
- (void)reloadImageIfLoadingFailed;
@end
