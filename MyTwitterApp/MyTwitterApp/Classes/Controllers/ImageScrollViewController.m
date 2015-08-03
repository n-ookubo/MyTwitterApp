//
//  ImageScrollViewController.m
//  MyTwitterApp
//
//  Created by 大久保直昭 on 2015/07/31.
//  Copyright (c) 2015年 大久保直昭. All rights reserved.
//

#import "ImageScrollViewController.h"
#import "UIImageView+MyImageCache.h"
#import "AppDelegate.h"

@interface ImageScrollViewController ()
{
    BOOL didZoomScaleInitialize;
}
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) UIImageView *imageView;
@property (weak, nonatomic) MyImageCache *imageCache;

@end

@implementation ImageScrollViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.imageWidth, self.imageHeight)];
    [self.scrollView addSubview:imageView];
    self.imageView = imageView;
    [self.imageView useActivityIndicator:YES];
    [self.imageView setPlaceholderHandler:^(UIImageView *view) {
        view.backgroundColor = [UIColor lightGrayColor];
    }];
    
    AppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    [self.imageView setImageCache:delegate.tweetImageCache];
    
    [self setContentImage];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    [self setZoomScale];
    [self centeringImage];
}

- (void)setContentImage
{
    if (!self.imageUrl) {
        [self.imageView setViewImageWithURLString:self.imageUrl];
        [self.scrollView setContentSize:CGSizeZero];
        return;
    }
    
    CGFloat imgWidth = self.imageWidth;
    CGFloat imgHeight = self.imageHeight;
    [self.imageView setViewImageWithURLString:self.imageUrl];
    [self.imageView setFrame:CGRectMake(0, 0, imgWidth, imgHeight)];
    
    CGSize imgSize = CGSizeMake(imgWidth, imgHeight);
    [self.scrollView setContentSize:imgSize];
}

- (void)setZoomScale
{
    // UIScrollViewとスクロール対象サイズから、拡大倍率の最大値と最小値を求める
    CGSize clientSize = [self.scrollView bounds].size;
    CGFloat barHeight = [self.navigationController navigationBar].frame.size.height
    + [UIApplication sharedApplication].statusBarFrame.size.height;
    
    CGFloat imgWidth = self.imageWidth;
    CGFloat imgHeight = self.imageHeight;
    CGFloat rateX = clientSize.width / imgWidth;
    CGFloat rateY = (clientSize.height - barHeight) / imgHeight;
    [self scrollView ].maximumZoomScale = 3.0;
    [self scrollView ].minimumZoomScale = MIN(MIN(rateX, rateY), 1.0);
    
    // 現在の拡大倍率が最小倍率未満なら修正
    // また初期化時は最小倍率にして表示する
    if ([self scrollView].zoomScale < [self scrollView].minimumZoomScale || !didZoomScaleInitialize) {
        [self scrollView].zoomScale = [self scrollView].minimumZoomScale;
        didZoomScaleInitialize = YES;
    }
}

- (void)centeringImage
{
    CGRect rect = [self imageView].frame;
    CGRect bounds = [self scrollView].bounds;
    CGFloat barHeight = [self navigationController].navigationBar.frame.size.height + [UIApplication sharedApplication].statusBarFrame.size.height;
    
    rect.origin = CGPointZero;
    // widthがUIScrollViewの横幅より小さければセンタリングする
    if (CGRectGetWidth(rect) <= CGRectGetWidth(bounds))
    {
        rect.origin.x = floor((CGRectGetWidth(bounds) - CGRectGetWidth(rect)) * 0.5);
    }
    
    // heightがUIScrollViewの縦幅より小さければセンタリングする
    CGFloat clientHeight = CGRectGetHeight(bounds) - barHeight;
    if (CGRectGetHeight(rect) < clientHeight)
    {
        rect.origin.y = floor((clientHeight - CGRectGetHeight(rect)) * 0.5);
    }
    [self imageView].frame = rect;
}

#pragma mark -　UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    [self centeringImage];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
