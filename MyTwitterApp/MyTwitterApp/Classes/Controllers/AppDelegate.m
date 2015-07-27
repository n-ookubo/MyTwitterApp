//
//  AppDelegate.m
//  MyTwitterApp
//
//  Created by 大久保直昭 on 2015/07/27.
//  Copyright (c) 2015年 大久保直昭. All rights reserved.
//

#import "AppDelegate.h"
#import "AccountService.h"
#import "TwitterService.h"

@interface AppDelegate ()

@end

@implementation AppDelegate
const NSString *kUserProfileImageCacheName = @"user_image";
const NSString *kTweetImageCacheName = @"image";
const int kUserProfileImageCacheCountLimit = 100;
const int kTweetImageCacheTotalCostLimit = 1024 * 1024 * 16;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    [ConnectionService setConnectionLimit:2];
    [ConnectionService setTimeoutInterval:60];
    
    self.userProfileImageCache = [[[MyImageCache alloc] initWithCacheName:(NSString *)kUserProfileImageCacheName useStorage:YES countLimit:/*[NSNumber numberWithInt:kUserProfileImageCacheCountLimit]*/nil totalCostLimit:nil] resumeCacheFromStorage];
    self.tweetImageCache = [[[MyImageCache alloc] initWithCacheName:(NSString *)kTweetImageCacheName useStorage:YES countLimit:nil totalCostLimit:[NSNumber numberWithInt:kTweetImageCacheTotalCostLimit]] resumeCacheFromStorage];
    
    UIViewController *initalController = nil;
    ACAccount *account = [[AccountService sharedService] defaultAccount];
    if (account) {
        // accountを用いてTwitterServiceを作成
        TwitterService *twitterService = [[TwitterService alloc] initWithAccount:account];
        self.twitterService = twitterService;
        
        initalController = [storyboard instantiateInitialViewController];
    } else {
        initalController = [storyboard instantiateViewControllerWithIdentifier:@"AccountSelect"];
    }
    self.window.rootViewController = initalController;
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
