//
//  ImageScrollViewController.h
//  MyTwitterApp
//
//  Created by 大久保直昭 on 2015/07/31.
//  Copyright (c) 2015年 大久保直昭. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ImageScrollViewController : UIViewController<UIScrollViewDelegate>
@property (copy, nonatomic) NSString *imageUrl;
@property CGFloat imageWidth;
@property CGFloat imageHeight;
@end
