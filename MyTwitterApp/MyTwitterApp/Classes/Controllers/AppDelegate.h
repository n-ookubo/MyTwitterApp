//
//  AppDelegate.h
//  MyTwitterApp
//
//  Created by 大久保直昭 on 2015/07/27.
//  Copyright (c) 2015年 大久保直昭. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TwitterService.h"
#import "MyImageCache.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) TwitterService *twitterService;
@property (strong, nonatomic) MyImageCache *userProfileImageCache;
@property (strong, nonatomic) MyImageCache *tweetImageCache;

@end

