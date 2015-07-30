//
//  MyTweet.m
//  twitterSample
//
//  Created by 大久保直昭 on 2015/07/23.
//  Copyright (c) 2015年 大久保直昭. All rights reserved.
//

#import "MyTweet.h"

@implementation MyTweet
const NSString *kMediaLoadingSize = @"medium";

- (instancetype)initWithDictionary:(NSDictionary *)dic
{
    return [self initWithDictionary:dic extractRetweet:YES];
}

- (instancetype)initWithDictionary:(NSDictionary *)dic extractRetweet:(BOOL)extractRT
{
    self = [super initWithDictionary:dic];
    if (self) {
        self.tweetId = [dic objectForKey:@"id_str"];
        
        NSDictionary *user = [dic objectForKey:@"user"];
        self.userId = [user objectForKey:@"id_str"];
        
        self.text = [dic objectForKey:@"text"];
        self.entities = [dic objectForKey:@"entities"];
        
        self.createdDateString = [dic objectForKey:@"created_at"];
        
        NSArray *medias = [self.entities objectForKey:@"media"];
        if (medias.count > 0) {
            NSDictionary *media = [medias firstObject];
            if ([[media objectForKey:@"type"] isEqualToString:@"photo"]) {
                NSDictionary *mediaSizes = [media objectForKey:@"sizes"];
                NSDictionary *loadingSize = [mediaSizes objectForKey:kMediaLoadingSize];
                if (loadingSize) {
                    self.mediaUrl = [NSString stringWithFormat:@"%@:%@", [media objectForKey:@"media_url"], kMediaLoadingSize];
                    self.mediaWidth = [loadingSize objectForKey:@"w"];
                    self.mediaHeight = [loadingSize objectForKey:@"h"];
                }
            }
        }
        
        if (extractRT) {
            NSDictionary * retweeted = [dic objectForKey:@"retweeted_status"];
            if (retweeted) {
                self.retweet = [[MyTweet alloc] initWithDictionary:retweeted extractRetweet:NO];
            }
        }
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

- (NSString *)mentionsForReplyTo:(NSString *)screenName self:(NSString *)selfScreenName
{
    NSMutableString *str = [[NSMutableString alloc] init];
    
    NSArray *userMentions = [self.entities objectForKey:@"user_mentions"];
    if (userMentions.count > 0) {
        for (NSDictionary *entity in userMentions) {
            NSString *scrName = [entity objectForKey:@"screen_name"];
            if (!screenName || ![scrName isEqualToString:screenName]) {
                if (!selfScreenName || ![scrName isEqualToString:selfScreenName]) {
                    [str appendString:[NSString stringWithFormat:@"@%@ ", scrName]];
                }
            }
        }
    }
    
    return str;
}

- (NSString *)description
{
    NSDictionary *dic = @{@"tweetId" : _tweetId, @"userId" : _userId, @"createdDate" : [self createdDate], @"text" : _text};
    return [[dic description] stringForNSLog];
}
@end
