//
//  MyTweetJoint.m
//  twitterSample
//
//  Created by 大久保直昭 on 2015/07/26.
//  Copyright (c) 2015年 大久保直昭. All rights reserved.
//

#import "MyTweetJoint.h"

@implementation MyTweetJoint

- (instancetype)initFrom:(NSString *)from to:(NSString *)to
{
    self = [super init];
    if (self) {
        self.from = from;
        self.to = to;
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
