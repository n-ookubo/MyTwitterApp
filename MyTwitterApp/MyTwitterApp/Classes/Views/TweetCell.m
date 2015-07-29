//
//  TweetCell.m
//  MyTwitterApp
//
//  Created by 大久保直昭 on 2015/07/27.
//  Copyright (c) 2015年 大久保直昭. All rights reserved.
//

#import "TweetCell.h"
#import "AppDelegate.h"

@interface TweetCell ()
@property (weak, nonatomic) MyImageCache *profileImageCache;
@property (weak, nonatomic) MyImageCache *tweetImageCache;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tweetImageAspectRatioConstraint;
@property (weak, nonatomic) IBOutlet UIView *retweetView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *retweetViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *retweetLabelTopMarginContstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *largeTimeTopMarginConstraint;

@end

@implementation TweetCell
static const CGFloat kTweetCellContentFontSize = 14.0;
static const CGFloat kTweetLargeCellContentFontSize = 16.0;

+ (CGFloat)heightForCellWithTweet:(MyTweet *)tweet withCellWidth:(CGFloat)width
{
    const CGFloat profileImageSize = 48;
    const CGFloat margin = 8;
    const CGFloat nameHeight = 15;
    
    const CGFloat contentXMargin = margin + profileImageSize + margin + margin;
    const CGFloat contentYMargin = margin + nameHeight + margin + margin;
    return [TweetCell heightForCellWithTweet:tweet withCellWidth:width contentFontSize:kTweetCellContentFontSize nameHeight:nameHeight xMargin:contentXMargin yMargin:contentYMargin];
}

+ (CGFloat)heightForLargeCellWithTweet:(MyTweet *)tweet withCellWidth:(CGFloat)width
{
    const CGFloat profileImageSize = 48;
    const CGFloat margin = 8;
    const CGFloat nameHeight = 17;
    
    const CGFloat contentXMargin = margin + profileImageSize + margin + margin;
    const CGFloat contentYMargin = margin + nameHeight + margin/2 + nameHeight + margin/2 + margin + nameHeight + margin;
    return [TweetCell heightForCellWithTweet:tweet withCellWidth:width contentFontSize:kTweetLargeCellContentFontSize nameHeight:nameHeight xMargin:contentXMargin yMargin:contentYMargin];
}

+ (CGFloat)heightForCellWithTweet:(MyTweet *)tweet withCellWidth:(CGFloat)width contentFontSize:(CGFloat)contentFontSize nameHeight:(CGFloat)nameHeight xMargin:(CGFloat)contentXMargin yMargin:(CGFloat)contentYMargin
{
    if (!tweet || width == 0) {
        return UITableViewAutomaticDimension;
    }
    
    MyTweet *tw = tweet;
    if (tweet.retweet) {
        tw = tweet.retweet;
    }
    
    const CGFloat profileImageSize = 48;
    const CGFloat margin = 8;
    const CGFloat profileHeight = margin + profileImageSize + margin;
    NSString *content = tw.text;
    
    UIFont *systemFont = [UIFont systemFontOfSize:contentFontSize + 1];
    CGSize contentBox = CGSizeMake(width - contentXMargin, CGFLOAT_MAX);
    CGSize sizeWithFont = [content boundingRectWithSize:contentBox options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingTruncatesLastVisibleLine attributes:[NSDictionary dictionaryWithObject:systemFont forKey:NSFontAttributeName] context:nil].size;
    
    CGFloat height = sizeWithFont.height + contentYMargin;
    
    if (tweet.retweet) {
        height += nameHeight + margin;
    }
    
    if (tw.mediaUrl) {
        height += ((width - contentXMargin) * [tw.mediaHeight doubleValue] / [tw.mediaWidth doubleValue]) + margin ;
    }
    
    return MAX(ceil(height), profileHeight);

}

+ (NSString *)getStringWithTime:(NSDate *)time
{
    NSDate *now = [NSDate date];
    NSTimeInterval seconds = [now timeIntervalSinceDate:time];
    if (seconds < 60.0) {
        return [NSString stringWithFormat:@"%ld秒前", (long)seconds];
    }
    
    NSTimeInterval minutes = seconds / 60.0;
    if (minutes < 60.0) {
        return [NSString stringWithFormat:@"%ld分前", (long)minutes];
    }
    
    NSTimeInterval hours = minutes / 60.0;
    if (hours < 24.0) {
        return [NSString stringWithFormat:@"%ld時間前", (long)hours];
    }
    
    NSTimeInterval days = hours / 24.0;
    return [NSString stringWithFormat:@"%ld日前", (long)days];
}

+ (NSString *)parseLabelLinkURL:(NSURL *)url
{    
    NSString *ret = nil;
    if ((ret = [self parseLabelLinkURL:url prefix:@"hashtag:" format:@"https://twitter.com/hashtag/%@"]) != nil) {
        return ret;
    }
    if ((ret = [self parseLabelLinkURL:url prefix:@"url:" format:@"%@"]) != nil) {
        return ret;
    }
    if ((ret = [self parseLabelLinkURL:url prefix:@"user:" format:@"https://twitter.com/%@"]) != nil) {
        return ret;
    }
    if ((ret = [self parseLabelLinkURL:url prefix:@"media:" format:@"%@"]) != nil) {
        return ret;
    }
    return nil;
}

+ (NSString *)parseLabelLinkURL:(NSURL *)url prefix:(NSString *)prefix format:(NSString *)format
{
    NSString *str = [url absoluteString];
    if ([str hasPrefix:prefix]) {
        NSString *value = [str substringFromIndex:[prefix length]];
        return [NSString stringWithFormat:format, value];
    }
    return nil;
}

- (void)awakeFromNib {
    // Initialization code
    [self.profileImageView useActivityIndicator:YES];
    [self.profileImageView setPlaceholderHandler:^(UIImageView *view) {
        view.backgroundColor = [UIColor lightGrayColor];
    }];
    
    [self.tweetImageView useActivityIndicator:YES];
    [self.tweetImageView setPlaceholderHandler:^(UIImageView *view) {
        view.backgroundColor = [UIColor lightGrayColor];
    }];
    
    AppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    self.profileImageCache = delegate.userProfileImageCache;
    self.tweetImageCache = delegate.tweetImageCache;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setDelegate:(id<TTTAttributedLabelDelegate>)delegate
{
    self.contentLabel.delegate = delegate;
}

- (void)setTweet:(MyTweet *)tweet userCache:(MyCache *)userCache
{
    if (!tweet || !userCache)
    {
        [self setEmptyTweet];
        return;
    }
    
    __block MyTweet *tw = tweet;
    if (tweet.retweet) {
        tw = tweet.retweet;
    }
    
    __block TweetCell *weakSelf = self;
    [userCache lookupWithKey:tw.userId owner:self handler:^(NSString *key, id value, NSError *error) {
        if (!weakSelf) {
            return;
        }
        
        if (error || ![key isEqualToString:tw.userId]) {
            [weakSelf setEmptyTweet];
            return;
        }
        
        MyUser *user = value;
        //NSLog(@"%@(%@)", user.name, user.profileImageUrl);
        
        weakSelf.selfTweet = tweet; // even if retweeted
        
        [weakSelf.profileImageView setImageCache: weakSelf.profileImageCache];
        [weakSelf.profileImageView setViewImageWithURLString:user.profileImageUrl];
        
        weakSelf.nameLabel.text = user.name;
        weakSelf.screenNameLabel.text = [NSString stringWithFormat:@"@%@", user.screenName];
        if (weakSelf.timeLabel) {
            weakSelf.timeLabel.text = [TweetCell getStringWithTime:[tw createdDate]];
        }
        if (weakSelf.largeTimeLabel) {
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.dateStyle = kCFDateFormatterLongStyle;
            formatter.timeStyle = kCFDateFormatterLongStyle;

            weakSelf.largeTimeLabel.text = [formatter stringFromDate:[tw createdDate]];
            [weakSelf removeConstraint:weakSelf.largeTimeTopMarginConstraint];
            weakSelf.largeTimeTopMarginConstraint = [NSLayoutConstraint constraintWithItem:weakSelf.largeTimeLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:weakSelf.tweetImageView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:tw.mediaUrl ? 8 : 0];
            [weakSelf addConstraint:weakSelf.largeTimeTopMarginConstraint];
        }
        
        if (tweet.retweet) {
            weakSelf.retweetView.hidden = NO;
            [userCache lookupWithKey:tweet.userId owner:weakSelf handler:^(NSString *key, id value, NSError *error) {
                if (error) {
                    weakSelf.retweetLabel.text = @"";
                } else {
                    MyUser *parentUser = value;
                    weakSelf.retweetLabel.text = [NSString stringWithFormat:@"%@さんがリツイート", parentUser.name];
                }
            }];
            if (weakSelf.retweetViewHeightConstraint) {
                [weakSelf.retweetView removeConstraint:weakSelf.retweetViewHeightConstraint];
                weakSelf.retweetViewHeightConstraint = nil;
            }
            if (!weakSelf.retweetLabelTopMarginContstraint) {
                weakSelf.retweetLabelTopMarginContstraint = [NSLayoutConstraint constraintWithItem:weakSelf.retweetLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:weakSelf.retweetView attribute:NSLayoutAttributeTop multiplier:1.0 constant:8.0];
                [weakSelf.retweetView addConstraint:weakSelf.retweetLabelTopMarginContstraint];
            }
        } else {
            weakSelf.retweetView.hidden = YES;
            weakSelf.retweetLabel.text = @"";
            if (!weakSelf.retweetViewHeightConstraint) {
                weakSelf.retweetViewHeightConstraint = [NSLayoutConstraint constraintWithItem:self.retweetView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:0];
                [weakSelf.retweetView addConstraint:weakSelf.retweetViewHeightConstraint];
            }
            if (weakSelf.retweetLabelTopMarginContstraint) {
                [weakSelf.retweetView removeConstraint:weakSelf.retweetLabelTopMarginContstraint];
                weakSelf.retweetLabelTopMarginContstraint = nil;
            }
        }
        
        UIImageView *img = weakSelf.tweetImageView;
        if (tw.mediaUrl) {
            NSLayoutConstraint *newConstraint = [NSLayoutConstraint constraintWithItem:img attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:img attribute:NSLayoutAttributeHeight multiplier:([tw.mediaWidth doubleValue] / [tw.mediaHeight doubleValue]) constant:0];
            [img removeConstraint:weakSelf.tweetImageAspectRatioConstraint];
            [img addConstraint:newConstraint];
            weakSelf.tweetImageAspectRatioConstraint = newConstraint;
            
            [img setImageCache:weakSelf.tweetImageCache];
            [img setViewImageWithURLString:tw.mediaUrl];
            img.hidden = NO;
        } else {
            [img setImageCache:nil];
            [img setViewImageWithURLString:nil];
            img.hidden = YES;
        }
        
        [weakSelf setContent:tw];
    }];
}

- (void)setContent:(MyTweet *)tweet
{
    self.contentLabel.text = tweet.text;
    
    NSArray *hashtags = [tweet.entities objectForKey:@"hashtags"];
    [self parseEntitiesAndAddLink:hashtags name:@"hashtag" valueKey:@"text" encodeValue:YES];
    
    NSArray *urls = [tweet.entities objectForKey:@"urls"];
    [self parseEntitiesAndAddLink:urls name:@"url" valueKey:@"expanded_url" encodeValue:NO];

    NSArray *userMentions = [tweet.entities objectForKey:@"user_mentions"];
    //[self parseEntitiesAndAddLink:userMentions name:@"user" valueKey:@"id_str" encodeValue:NO];
    // use screen_name for openurl
    [self parseEntitiesAndAddLink:userMentions name:@"user" valueKey:@"screen_name" encodeValue:NO];
    
    // replace?
    NSArray *medias = [tweet.entities objectForKey:@"media"];
    [self parseEntitiesAndAddLink:medias name:@"media" valueKey:@"media_url" encodeValue:NO];
    //NSArray *symbols = [tweet.entities objectForKey:@"symbols"];
}

- (void)parseEntitiesAndAddLink:(NSArray *)entities name:(NSString *)entityName valueKey:(NSString *)key encodeValue:(BOOL)encode
{
    if (entities.count == 0) {
        return;
    }
    
    for (NSDictionary *entity in entities) {
        NSArray *rangeArray = [entity objectForKey:@"indices"];
        if (rangeArray.count != 2) {
            continue;
        }
        NSUInteger loc = [[rangeArray firstObject] unsignedIntegerValue];
        NSUInteger len = [[rangeArray lastObject] unsignedIntegerValue] - loc;
        NSRange range = NSMakeRange(loc, len);

        NSString *value = [entity objectForKey:key];
        if (encode) {
            value = (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)value, NULL, (CFStringRef)@"!*'();:@&=+$,/?%#[]", kCFStringEncodingUTF8);
        }
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@:%@", entityName, value]];
        //NSLog(@"%@ (%lu, %lu)", url, loc, len);
        [self.contentLabel addLinkToURL:url withRange:range];
    }
}

- (void)setEmptyTweet
{
    self.retweetView.hidden = YES;
    self.retweetLabel.text = @"";
    if (!self.retweetViewHeightConstraint) {
        self.retweetViewHeightConstraint = [NSLayoutConstraint constraintWithItem:self.retweetView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:0];
        [self.retweetView addConstraint:self.retweetViewHeightConstraint];
    }
    if (self.retweetLabelTopMarginContstraint) {
        [self.retweetView removeConstraint:self.retweetLabelTopMarginContstraint];
        self.retweetLabelTopMarginContstraint = nil;
    }
    
    [self.profileImageView setImageCache:nil];
    [self.profileImageView setViewImageWithURLString:nil];
    [self.tweetImageView setImageCache:nil];
    [self.tweetImageView setViewImageWithURLString:nil];
    self.tweetImageView.hidden = YES;
    
    self.nameLabel.text = @"";
    self.screenNameLabel.text = @"";
    if (self.timeLabel) {
        self.timeLabel.text = @"";
    }
    if (self.largeTimeLabel) {
        self.largeTimeLabel.text = @"";
    }
    self.contentLabel.text = @"";
}

@end
