//
//  TweetJointCell.m
//  MyTwitterApp
//
//  Created by 大久保直昭 on 2015/07/27.
//  Copyright (c) 2015年 大久保直昭. All rights reserved.
//

#import "TweetJointCell.h"

@implementation TweetJointCell

- (void)awakeFromNib {
    // Initialization code
    self.activityIndicator.hidden = YES;
    self.titleLabel.hidden = NO;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)startAnimating
{
    if (self.activityIndicator.hidden == NO) {
        return;
    }
    self.titleLabel.hidden = YES;
    self.activityIndicator.hidden = NO;
    [self.activityIndicator startAnimating];
}

- (void)endAnimating
{
    if (self.activityIndicator.hidden == NO) {
        [self.activityIndicator stopAnimating];
    }
    self.activityIndicator.hidden = YES;
    self.titleLabel.hidden = NO;
}

- (BOOL)isAnimating
{
    return self.activityIndicator.isAnimating;
}
@end
