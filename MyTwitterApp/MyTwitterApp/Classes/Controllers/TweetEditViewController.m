//
//  TweetEditViewController.m
//  MyTwitterApp
//
//  Created by 大久保直昭 on 2015/07/29.
//  Copyright (c) 2015年 大久保直昭. All rights reserved.
//

#import "TweetEditViewController.h"
#import "AppDelegate.h"

@interface TweetEditViewController ()
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UILabel *lengthLabel;
@property (weak, nonatomic) UIBarButtonItem *doneButton;

@end

@implementation TweetEditViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(sendTweet)];
    self.navigationItem.rightBarButtonItem = button;
    self.doneButton = button;
    self.navigationController.toolbarHidden = YES;
    self.title = self.replyTweet ? @"ツイートに返信" : @"新規ツイート";
    
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    [center addObserver:self selector:@selector(keyboardDidChangeFrame:) name:UIKeyboardDidChangeFrameNotification object:nil];
    [center addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
    
    self.textView.text = @"";
    if (self.replyTweet) {
        __block TweetEditViewController *weakSelf = self;
        AppDelegate *delegate = [[UIApplication sharedApplication] delegate];
        [[delegate.twitterService apiService].userCache lookupWithKey:self.replyTweet.userId owner:self handler:^(NSString *key, id value, NSError *error) {
            if (error) {
                weakSelf.textView.text = @"";
            } else {
                MyUser *user = value;
                weakSelf.textView.text = [NSString stringWithFormat:@"@%@ %@", user.screenName, [weakSelf.replyTweet mentionsForReplyTo:user.screenName self:[delegate.twitterService account].username]];
                [self updateLengthLabel:[TwitterService countTweetLength:[self textView].text]];
                [self.doneButton setEnabled:[TwitterService isNotEmptyStringAsTweet:[self textView].text]];
            }
        }];
    }
    [self updateLengthLabel:[TwitterService countTweetLength:[self textView].text]];
    [self.doneButton setEnabled:[TwitterService isNotEmptyStringAsTweet:[self textView].text]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.navigationController.toolbarHidden = YES;
    [self.textView becomeFirstResponder];
}

- (void)sendTweet
{
    [self.textView resignFirstResponder];
    UIAlertController *controller = [UIAlertController alertControllerWithTitle:@"送信中" message:nil preferredStyle:UIAlertControllerStyleAlert];
    UIViewController *alertCC = [[UIViewController alloc] init];
    alertCC.view.backgroundColor = [UIColor clearColor];
    
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    indicator.frame = CGRectMake(indicator.frame.origin.x, indicator.frame.origin.y, indicator.frame.size.width, indicator.frame.size.height * 3);
    [alertCC.view addSubview:indicator];
    [alertCC.view addConstraint:[NSLayoutConstraint constraintWithItem:indicator attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:alertCC.view attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    [alertCC.view addConstraint:[NSLayoutConstraint constraintWithItem:indicator attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:alertCC.view attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
    [controller setValue:alertCC forKey:@"contentViewController"];
    
    [indicator startAnimating];
    [self.navigationController presentViewController:controller animated:YES completion:nil];
    
    __block TweetEditViewController *weakSelf = self;
    AppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    [[delegate twitterService].apiService sendTweet:self.textView.text replyTo:[self.replyTweet tweetId] completion:^(NSArray *result, NSError *error) {
        [indicator stopAnimating];
        
        if (error) {
        NSString *message = nil;
            if ([error.domain isEqualToString:NSURLErrorDomain]) {
                switch (error.code) {
                    case NSURLErrorNotConnectedToInternet:
                        message = @"インターネットに接続されていません。"; break;
                    case NSURLErrorTimedOut:
                        message = @"タイムアウトしました。"; break;
                    case NSURLErrorCancelled:
                        return; // メッセージを出さない
                    default:
                        message = error.localizedDescription;
                        break;
                }
            }
            [controller dismissViewControllerAnimated:YES completion:^{
                UIAlertController *resultController = [UIAlertController alertControllerWithTitle:@"エラー" message:message preferredStyle:UIAlertControllerStyleAlert];
                [resultController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
                [weakSelf presentViewController:resultController animated:YES completion:nil];
            }];
        } else {
            [controller dismissViewControllerAnimated:YES completion:^{
                [weakSelf.parentTimeline didNewTweetComplete];
            }];
        }
        
    }];
    
}


- (void)resizeTextView:(CGRect)keyboardRect
{
    CGRect frame = self.view.frame;
    frame.size.height = keyboardRect.origin.y - frame.origin.y;
    [self.view setFrame:frame];
}

- (void)updateLengthLabel:(NSUInteger)length
{
    long limit = 140;
    self.lengthLabel.text = [NSString stringWithFormat:@"%ld", limit - (long)length];
    [self.view layoutIfNeeded];
}

#pragma mark - UITextViewDelegate
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    NSMutableString *str = [textView.text mutableCopy];
    [str replaceCharactersInRange:range withString:text];
    
    [self.doneButton setEnabled:[TwitterService isNotEmptyStringAsTweet:str]];
    
    NSUInteger length = [TwitterService countTweetLength:str];
    long limit = 140;
    if (length > limit) {
        return NO;
    }
    
    [self updateLengthLabel:length];
    return YES;
}

#pragma mark - keyboardNotification
- (void)keyboardDidShow:(NSNotification *)notification
{
    [self resizeTextView:[[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue]];
}

- (void)keyboardDidChangeFrame:(NSNotification *)notification
{
    [self resizeTextView:[[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue]];
}

- (void)keyboardDidHide:(NSNotification *)notification
{
    [self resizeTextView:[[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue]];
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
