//
//  TweetDetailViewController.m
//  MyTwitterApp
//
//  Created by 大久保直昭 on 2015/07/28.
//  Copyright (c) 2015年 大久保直昭. All rights reserved.
//

#import "TweetDetailViewController.h"
#import "AppDelegate.h"
#import "TweetCell.h"
#import "TweetEditViewController.h"

@interface TweetDetailViewController ()
@property (weak, nonatomic) TwitterService *twitterService;
@property (weak, nonatomic) MyCache *userCache;
@end

@implementation TweetDetailViewController
const NSString *kTweetLargeCellNibName = @"TweetCellLarge";
const NSString *kTweetLargeCellReuseIdentifier = @"tweetCellLarge";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    AppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    TwitterService *twitterService = delegate.twitterService;
    if (twitterService) {
        self.twitterService = twitterService;
        self.userCache = twitterService.apiService.userCache;
    }
    
    self.title = @"ツイート";
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"戻る" style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(startEditNewTweet)];
    UIBarButtonItem *replyButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemReply target:self action:@selector(startEditReplyTweet)];
    UIBarButtonItem *space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    self.toolbarItems = @[replyButton, space];
    self.navigationController.toolbarHidden = NO;
    
    UINib *tweetCellNib = [UINib nibWithNibName:(NSString *)kTweetLargeCellNibName bundle:nil];
    [self.tableView registerNib:tweetCellNib forCellReuseIdentifier:(NSString *)kTweetLargeCellReuseIdentifier];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.navigationController.toolbarHidden = NO;
}

- (void)startEditNewTweet
{
    [self performSegueWithIdentifier:@"ShowTweetEditFromTweetDetail" sender:self];
}

-(void)startEditReplyTweet
{
    [self performSegueWithIdentifier:@"ShowTweetEditFromTweetDetailAsReply" sender:self];
}

- (void)showActionSheetWithURLString:(NSString *)urlString
{
    UIAlertController *controller = [UIAlertController alertControllerWithTitle:urlString message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [controller addAction:[UIAlertAction actionWithTitle:@"Safariで開く" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
    }]];
    [controller addAction:[UIAlertAction actionWithTitle:@"キャンセル" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:controller animated:YES completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return self.selfTweet ? 1 : 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return self.selfTweet ? 1 : 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TweetCell *tweetCell = [tableView dequeueReusableCellWithIdentifier:(NSString *)kTweetLargeCellReuseIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    [tweetCell setTweet:self.selfTweet userCache:self.userCache];
    [tweetCell setDelegate:self];
    
    return tweetCell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!self.selfTweet) {
        return UITableViewAutomaticDimension;
    }
    return [TweetCell heightForLargeCellWithTweet:self.selfTweet withCellWidth:tableView.frame.size.width];
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - TTTAtributedLabelDelegate
- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url {
    NSString *urlString = [TweetCell parseLabelLinkURL:url];
    if (urlString) {
        [self showActionSheetWithURLString:urlString];
    }
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([segue.identifier isEqualToString:@"ShowTweetEditFromTweetDetail"]) {
        TweetEditViewController *controller = [segue destinationViewController];
        controller.parentTimeline = self.parentTimeline;
    } else if ([segue.identifier isEqualToString:@"ShowTweetEditFromTweetDetailAsReply"]) {
        TweetEditViewController *controller = [segue destinationViewController];
        controller.parentTimeline = self.parentTimeline;
        controller.replyTweet = self.selfTweet;
    }
}


@end
