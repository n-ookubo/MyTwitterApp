//
//  MyTweetJoint.m
//  twitterSample
//
//  Created by 大久保直昭 on 2015/07/26.
//  Copyright (c) 2015年 大久保直昭. All rights reserved.
//

#import "MyTweetJoint.h"

@implementation MyTweetJoint
+ (BOOL)isSuitableForJoint:(NSDictionary *)dic
{
    return (dic && [[dic objectForKey:@"id_str"] isEqualToString:@"joint"]);
}

- (instancetype)initFrom:(NSString *)from to:(NSString *)to
{
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] initWithDictionary:@{@"id_str" : @"joint"}];
    if (from) {
        [dic setObject:from forKey:@"from"];
    }
    if (to) {
        [dic setObject:to forKey:@"to"];
    }
    return [self initWithDictionary:dic];
}

- (instancetype)initWithDictionary:(NSDictionary *)dic
{
    self = [super initWithDictionary:dic];
    if (self) {
        if (!dic) {
            return nil;
        }
        self.from = [dic objectForKey:@"from"];
        self.to = [dic objectForKey:@"to"];
    }
    return self;
}

- (NSString *)description
{
    NSMutableString *desc = [[NSMutableString alloc] initWithString:@"[old] "];
    if (self.from) {
        [desc appendString:self.from];
        [desc appendString:@" < "];
    }
    [desc appendString:@"(tweet)"];
    if (self.to) {
        [desc appendString:@" <= "];
        [desc appendString:self.to];
    }
    [desc appendString:@" [new]"];
    return desc;
}
@end
