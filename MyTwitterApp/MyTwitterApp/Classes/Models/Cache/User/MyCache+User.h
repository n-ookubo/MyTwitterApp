//
//  MyCache+User.h
//  MyTwitterApp
//
//  Created by 大久保直昭 on 2015/07/28.
//  Copyright (c) 2015年 大久保直昭. All rights reserved.
//

#import <Accounts/Accounts.h>
#import "MyCache.h"

@interface MyCache (User)
- (instancetype)resumeFromCache:(ACAccount *)account;

@end
