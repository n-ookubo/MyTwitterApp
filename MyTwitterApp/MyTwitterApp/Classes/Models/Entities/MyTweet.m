//
//  MyTweet.m
//  twitterSample
//
//  Created by 大久保直昭 on 2015/07/23.
//  Copyright (c) 2015年 大久保直昭. All rights reserved.
//

#import "MyTweet.h"

@implementation MyTweet
- (instancetype)initWithDictionary:(NSDictionary *)dic
{
    self = [super initWithDictionary:dic];
    if (self) {
        self.tweetId = [dic objectForKey:@"id_str"];
        
        NSDictionary *user = [dic objectForKey:@"user"];
        self.userId = [user objectForKey:@"id_str"];
        
        self.text = [dic objectForKey:@"text"];
        self.entities = [dic objectForKey:@"entities"];
        
        self.createdDateString = [dic objectForKey:@"created_at"];
    }
    return self;
}

- (NSDate *)createdDate
{
    if (!_createdDateString) {
        return nil;
    }
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    formatter.dateFormat = @"eee MMM dd HH:mm:ss ZZZZ yyyy";
    return [formatter dateFromString:_createdDateString];
}

- (NSString *)description
{
    NSDictionary *dic = @{@"tweetId" : _tweetId, @"userId" : _userId, @"createdDate" : [self createdDate], @"text" : _text};
    return [[dic description] stringForNSLog];
}
@end
