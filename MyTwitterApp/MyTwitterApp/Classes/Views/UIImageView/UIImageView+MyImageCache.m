//
//  UIImageView+MyImageCache.m
//  twitterSample
//
//  Created by 大久保直昭 on 2015/07/26.
//  Copyright (c) 2015年 大久保直昭. All rights reserved.
//

#import "UIImageView+MyImageCache.h"
#import <objc/runtime.h>

#define UIIMAGEVIEW_MYIMAGECACHE_CACHE      "UIIMAGEVIEW_MYIMAGECACHE_CACHE"
#define UIIMAGEVIEW_MYIMAGECACHE_URLSTRING  "UIIMAGEVIEW_MYIMAGECACHE_URLSTRING"
#define UIIMAGEVIEW_MYIMAGECACHE_INDICATOR  "UIIMAGEVIEW_MYIMAGECACHE_INDICATOR"
#define UIIMAGEVIEW_MYIMAGECACHE_INDICATORSHOW  "UIIMAGEVIEW_MYIMAGECACHE_INDICATORSHOW"
#define UIIMAGEVIEW_MYIMAGECACHE_INDICATORSTYLE "UIIMAGEVIEW_MYIMAGECACHE_INDICATORSTYLE"
#define UIIMAGEVIEW_MYIMAGECACHE_LOADING_GRAYVIEW   "UIIMAGEVIEW_MYIMAGECACHE_LOADING_GRAYVIEW"
#define UIIMAGEVIEW_MYIMAGECACHE_LOADING_COMPLETION "UIIMAGEVIEW_MYIMAGECACHE_LOADING_COMPLETION"
#define UIIMAGEVIEW_MYIMAGECACHE_PLACEHOLDER_HANDLER    "UIIMAGEVIEW_MYIMAGECACHE_PLACEHOLDER_HANDLER"
#define UIIMAGEVIEW_MYIMAGECACHE_LOADINGFAILED_HANDLER  "UIIMAGEVIEW_MYIMAGECACHE_LOADINGFAILED_HANDLER"
#define UIIMAGEVIEW_MYIMAGECACHE_LOADINGCOMPLETION_HANDLER  "UIIMAGEVIEW_MYIMAGECACHE_LOADINGCOMPLETION_HANDLER"

@implementation UIImageView (MyImageCache)

- (void)setImageCache:(MyImageCache *)cache
{
    objc_setAssociatedObject(self, UIIMAGEVIEW_MYIMAGECACHE_CACHE, cache, OBJC_ASSOCIATION_ASSIGN);
}

- (MyImageCache *)getImageCache
{
    return objc_getAssociatedObject(self, UIIMAGEVIEW_MYIMAGECACHE_CACHE);
}

- (void)setImageURLString:(NSString *)urlString
{
    objc_setAssociatedObject(self, UIIMAGEVIEW_MYIMAGECACHE_URLSTRING, urlString, OBJC_ASSOCIATION_COPY);
}

- (NSString *)getImageURLString
{
    return objc_getAssociatedObject(self, UIIMAGEVIEW_MYIMAGECACHE_URLSTRING);
}

- (void)setImageLoadingCompletion:(BOOL)completion
{
    objc_setAssociatedObject(self, UIIMAGEVIEW_MYIMAGECACHE_LOADING_COMPLETION, [NSNumber numberWithBool:completion], OBJC_ASSOCIATION_COPY);
}

- (BOOL)getImageLoadingCompletion
{
    return [objc_getAssociatedObject(self, UIIMAGEVIEW_MYIMAGECACHE_LOADING_COMPLETION) boolValue];
}

- (void)useActivityIndicator:(BOOL)useIndicator
{
    UIActivityIndicatorView *view = [self getActivityIndicator];
    if (useIndicator) {
        if (!view) {
            dispatch_async(dispatch_get_main_queue(), ^{
                UIActivityIndicatorView *acView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:[self getActivityIndicatorStyle]];
                [acView setTranslatesAutoresizingMaskIntoConstraints:NO];
                [self setActivityIndicator:acView];
                
                UIView *grayView = [[UIView alloc] init];
                [grayView setTranslatesAutoresizingMaskIntoConstraints:NO];
                grayView.backgroundColor = [UIColor blackColor];
                grayView.alpha = 0.5;
                [self setGrayView:grayView];
            });
        }
    } else {
        if (view) {
            [self setActivityIndicator:nil];
            [self setGrayView:nil];
        }
    }
}

- (void)setGrayView:(UIView *)view
{
    objc_setAssociatedObject(self, UIIMAGEVIEW_MYIMAGECACHE_LOADING_GRAYVIEW, view, OBJC_ASSOCIATION_RETAIN);
}

- (UIView *)getGrayView
{
    return objc_getAssociatedObject(self, UIIMAGEVIEW_MYIMAGECACHE_LOADING_GRAYVIEW);
}

- (void)setActivityIndicator:(UIActivityIndicatorView *)view
{
    objc_setAssociatedObject(self, UIIMAGEVIEW_MYIMAGECACHE_INDICATOR, view, OBJC_ASSOCIATION_RETAIN);
}

- (UIActivityIndicatorView *)getActivityIndicator
{
    return objc_getAssociatedObject(self, UIIMAGEVIEW_MYIMAGECACHE_INDICATOR);
}

- (void)setActivityIndicatorStyle:(UIActivityIndicatorViewStyle)style
{
    objc_setAssociatedObject(self, UIIMAGEVIEW_MYIMAGECACHE_INDICATORSTYLE, [NSNumber numberWithInt:style], OBJC_ASSOCIATION_COPY);
}

- (UIActivityIndicatorViewStyle)getActivityIndicatorStyle
{
    return [objc_getAssociatedObject(self, UIIMAGEVIEW_MYIMAGECACHE_INDICATORSTYLE) intValue];
}

- (void)setActivityIndicatorShow:(BOOL)show
{
    objc_setAssociatedObject(self, UIIMAGEVIEW_MYIMAGECACHE_INDICATORSHOW, [NSNumber numberWithBool:show], OBJC_ASSOCIATION_COPY);
}

- (BOOL)getActivityIndicatorShow
{
    return [objc_getAssociatedObject(self, UIIMAGEVIEW_MYIMAGECACHE_INDICATORSHOW) boolValue];
}

- (void)showActivityIndicator
{
    UIActivityIndicatorView *view = [self getActivityIndicator];
    BOOL show = [self getActivityIndicatorShow];
    if (!view || show) {
        return;
    }
    [self setActivityIndicatorShow:YES];
    
    UIView *grayView = [self getGrayView];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (grayView) {
            [self addSubview:grayView];
            [grayView.superview addConstraint:[NSLayoutConstraint constraintWithItem:grayView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:grayView.superview attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0.0]];
            [grayView.superview addConstraint:[NSLayoutConstraint constraintWithItem:grayView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:grayView.superview attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0.0]];
            [grayView.superview addConstraint:[NSLayoutConstraint constraintWithItem:grayView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:grayView.superview attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0]];
            [grayView.superview addConstraint:[NSLayoutConstraint constraintWithItem:grayView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:grayView.superview attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0.0]];
            [grayView setHidden:NO];
        }
        
        [self addSubview:view];
        [view.superview addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:view.superview attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0]];
        [view.superview addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:view.superview attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]];
        [view setHidden:NO];
        [view startAnimating];
    });
}

- (void)hideActivityIndicator
{
    UIActivityIndicatorView *view = [self getActivityIndicator];
    BOOL show = [self getActivityIndicatorShow];
    if (!view || !show) {
        return;
    }
    [self setActivityIndicatorShow:NO];
    
    UIView *grayView = [self getGrayView];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (grayView) {
            [grayView setHidden:YES];
            [grayView removeFromSuperview];
        }
        [view stopAnimating];
        [view setHidden:YES];
        [view removeFromSuperview];
    });
}


- (void)setPlaceholderHandler:(UIImageViewSetContentHandler)handler
{
    objc_setAssociatedObject(self, UIIMAGEVIEW_MYIMAGECACHE_PLACEHOLDER_HANDLER, handler, OBJC_ASSOCIATION_COPY);
}

- (UIImageViewSetContentHandler)getPlaceholderHandler
{
    return objc_getAssociatedObject(self, UIIMAGEVIEW_MYIMAGECACHE_PLACEHOLDER_HANDLER);
}

- (void)setLoadingFailedHandler:(UIImageViewSetContentHandler)handler
{
    objc_setAssociatedObject(self, UIIMAGEVIEW_MYIMAGECACHE_LOADINGFAILED_HANDLER, handler, OBJC_ASSOCIATION_COPY);
}

- (UIImageViewSetContentHandler)getLoadingFailedHandler
{
    return objc_getAssociatedObject(self, UIIMAGEVIEW_MYIMAGECACHE_LOADINGFAILED_HANDLER);
}

- (void)setImageLoadingCompletionHandler:(UIImageViewSetContentWithImageHandler)handler
{
    objc_setAssociatedObject(self, UIIMAGEVIEW_MYIMAGECACHE_LOADINGCOMPLETION_HANDLER, handler, OBJC_ASSOCIATION_COPY);
}

- (UIImageViewSetContentWithImageHandler)getImageLoadingCompletionHandler
{
    return objc_getAssociatedObject(self, UIIMAGEVIEW_MYIMAGECACHE_LOADINGCOMPLETION_HANDLER);
}

- (void)setViewImageWithURLString:(NSString *)urlString
{
    MyImageCache *cache = [self getImageCache];
    if (!cache) {
        return;
    }
    
    NSString *beforeUrlString = [self getImageURLString];
    if (beforeUrlString) {
        if ([self getActivityIndicatorShow]) {
            [cache cancelLookupWithKey:beforeUrlString owner:self];
        }
    }
    
    [self showPlaceHolder];
    
    if (!urlString) {
        [self setImageLoadingCompletion:YES];
        return;
    }
    
    [self setImageURLString:urlString];
    [self setImageLoadingCompletion:NO];
    [self showActivityIndicator];
    
    __block UIImageView *weakSelf = self;
    [cache lookupWithKey:urlString owner:self handler:^(NSString *key, id value, NSError *error) {
        UIImage *img = value;
        
        if (!weakSelf) {
            return;
        }
        
        if ([weakSelf getImageURLString] != key) {
            return;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf hideActivityIndicator];
        });
        
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                UIImageViewSetContentHandler handler = [weakSelf getLoadingFailedHandler];
                if (handler) {
                    handler(weakSelf);
                } else {
                    [weakSelf showPlaceHolderWithoutDispatch];
                }
            });
            [weakSelf setImageLoadingCompletion:NO];
            return;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            UIImageViewSetContentWithImageHandler handler = [weakSelf getImageLoadingCompletionHandler];
            if (handler) {
                handler(weakSelf, img);
            } else {
                weakSelf.image = img;
            }
        });
        [weakSelf setImageLoadingCompletion:YES];
    }];
}

- (void)showPlaceHolder
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showPlaceHolderWithoutDispatch];
    });
}

- (void)showPlaceHolderWithoutDispatch
{
    UIImageViewSetContentHandler handler = [self getPlaceholderHandler];
    if (handler) {
        handler(self);
    } else {
        self.image = nil;
    }
}

- (void)reloadImageIfLoadingFailed
{
    NSString *urlString = [self getImageURLString];
    BOOL loadingCompletion = [self getImageLoadingCompletion];
    BOOL activityIndicatorShow = [self getActivityIndicatorShow];
    if (urlString && !loadingCompletion && !activityIndicatorShow) {
        [self setViewImageWithURLString:urlString];
    }
}
@end
