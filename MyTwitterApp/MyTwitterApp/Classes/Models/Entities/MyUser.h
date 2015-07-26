//
//  MyUser.h
//  twitterSample
//
//  Created by 大久保直昭 on 2015/07/23.
//  Copyright (c) 2015年 大久保直昭. All rights reserved.
//

#import "MyTwitterObj.h"
#import "MyCacheContent.h"

@interface MyUser : MyTwitterObj<MyCacheContent>
@property (weak, nonatomic) NSString *userId;
@property (weak, nonatomic) NSString *name;
@property (weak, nonatomic) NSString *screenName;
@property (weak, nonatomic) NSString *profileImageUrl;
@end
