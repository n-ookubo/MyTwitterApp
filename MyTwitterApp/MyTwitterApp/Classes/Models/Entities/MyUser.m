//
//  MyUser.m
//  twitterSample
//
//  Created by 大久保直昭 on 2015/07/23.
//  Copyright (c) 2015年 大久保直昭. All rights reserved.
//

#import "MyUser.h"

@implementation MyUser
- (instancetype)initWithDictionary:(NSDictionary *)dic
{
    self = [super initWithDictionary:dic];
    if (self) {
        self.userId = [dic objectForKey:@"id_str"];
        self.name = [dic objectForKey:@"name"];
        self.screenName = [dic objectForKey:@"screen_name"];
        self.profileImageUrl = [dic objectForKey:@"profile_image_url"];
    }
    return self;
}

- (NSString *)description
{
    NSDictionary *dic = @{@"userId" : _userId, @"name": _name, @"screenName" : _screenName, @"profileImageUrl" : _profileImageUrl};
    return [[dic description] stringForNSLog];
}

#pragma mark NSDiscardableContent
- (BOOL)beginContentAccess
{
    return YES;
}

- (void)endContentAccess
{
    
}

- (void)discardContentIfPossible
{
    // キャッシュからの消去時にコールされる
    // 可能ならオブジェクトを破棄する
}

- (BOOL)isContentDiscarded
{
    // キャッシュアクセス時にコールされる
    // YESを返すと、キャッシュはオブジェクトの再取得を試みる
    return NO;
}

#pragma mark MyCacheContent

- (id)cachedValue
{
    return self;
}
@end
