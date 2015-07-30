//
//  TimelineViewController.m
//  MyTwitterApp
//
//  Created by 大久保直昭 on 2015/07/27.
//  Copyright (c) 2015年 大久保直昭. All rights reserved.
//

#import "TimelineViewController.h"
#import "AppDelegate.h"
#import "TweetCell.h"
#import "TweetJointCell.h"
#import "TweetDetailViewController.h"
#import "TweetEditViewController.h"

@interface TimelineViewController ()
{
    MyTweet *tweetForSegue;
}
@property (weak, nonatomic) TwitterService *twitterService;
@property (weak, nonatomic) MyCache *userCache;
@property (assign, atomic) BOOL waitingResponse;

@end

@implementation TimelineViewController
const NSString *kTweetCellNibName = @"TweetCellSmall";
//const NSString *kTweetCellNibName = @"TweetCellLarge";
const NSString *kTweetJointNibName = @"TweetJoint";
const NSString *kTweetCellReuseIdentifier = @"tweetCell";
const NSString *kTweetJointReuseIdentifier = @"tweetJoint";
const CGFloat kTweetJointCellHeight = 40;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    AppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    TwitterService *twitterService = delegate.twitterService;
    if (twitterService) {
        if (!self.timelineService) {
            self.timelineService = twitterService.homeTimeline;
        }
        self.twitterService = twitterService;
        self.userCache = twitterService.apiService.userCache;
    }
    
    if (!self.timelineService) {
        return;
    }
    
    NSString *userId = self.timelineService.timelineUserId;
    if (userId) {
        [self.userCache lookupWithKey:userId owner:self handler:^(NSString *key, id value, NSError *error) {
            if (!error) {
                MyUser *user = value;
                if (user) {
                    self.title = [NSString stringWithFormat:@"@%@", user.screenName];
                }
            }
        }];
    } else {
        self.title = @"ホーム";
    }
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"戻る" style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(startEditNewTweet)];
    self.navigationController.toolbarHidden = YES;
    
    UINib *tweetCellNib = [UINib nibWithNibName:(NSString *)kTweetCellNibName bundle:nil];
    [self.tableView registerNib:tweetCellNib forCellReuseIdentifier:(NSString *)kTweetCellReuseIdentifier];
    UINib *tweetJointNib = [UINib nibWithNibName:(NSString *)kTweetJointNibName bundle:nil];
    [self.tableView registerNib:tweetJointNib forCellReuseIdentifier:(NSString *)kTweetJointReuseIdentifier];
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(startRefresh) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
    
    self.waitingResponse = NO;
    [self startRefreshingTimelineManually];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.navigationController.toolbarHidden = YES;
}

- (void)startRefreshingTimelineManually
{
    [self.refreshControl beginRefreshing];
    [self.tableView setContentOffset:CGPointMake(0, -self.refreshControl.frame.size.height) animated:YES];
    [self startRefresh];
}

- (void)startRefresh
{
    if (!self.timelineService || self.waitingResponse) {
        [self.refreshControl endRefreshing];
        return;
    }
    
    __block TimelineViewController *weakSelf = self;
    self.waitingResponse = [self.timelineService loadRecentTweetWithHandler:^(NSUInteger startIndex, NSUInteger length, NSError *error) {
        weakSelf.waitingResponse = NO;
        //dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                NSLog(@"%@", error);
                [weakSelf.refreshControl endRefreshing];
                return;
            }
            CGPoint srcPt = [weakSelf.tableView contentOffset];
            [self.tableView reloadData];
            
            if (length > 0) {
                NSIndexPath *oldTopIndex = [NSIndexPath indexPathForRow:length inSection:0];
                UITableViewCell * cell = [weakSelf.tableView cellForRowAtIndexPath:oldTopIndex];
                CGRect cellRect = cell.frame;
                CGPoint destPt = CGPointMake(cellRect.origin.x, cellRect.origin.y + srcPt.y);
                [weakSelf.tableView setContentOffset:destPt animated:NO];
            }
            
            [weakSelf.refreshControl endRefreshing];
        //});
    }];
    
    if (!self.waitingResponse) {
        [weakSelf.refreshControl endRefreshing];
    }
}

- (void)startEditNewTweet
{
    [self performSegueWithIdentifier:@"ShowTweetEditFromTImeline" sender:self];
}

- (void)didNewTweetComplete
{
    [self.navigationController popToViewController:self animated:YES];
    
    UIAlertController *controller = [UIAlertController alertControllerWithTitle:@"送信完了" message:@"ツイートの投稿が完了しました。" preferredStyle:UIAlertControllerStyleAlert];
    [controller addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:controller animated:YES completion:nil];
    [self startRefreshingTimelineManually];
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
    return self.timelineService ? 1 : 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [self.timelineService count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    
    // Configure the cell...
    if (self.timelineService && [self.timelineService getObjectTypeAtIndex:indexPath.row] == kTimelineObjectTweet) {
        TweetCell *tweetCell = [tableView dequeueReusableCellWithIdentifier:(NSString *)kTweetCellReuseIdentifier forIndexPath:indexPath];
        MyTweet *tweet = [self.timelineService getTweetAtIndex:indexPath.row];
        [tweetCell setTweet:tweet userCache:self.userCache];
        [tweetCell setDelegate:self];
        
        cell = tweetCell;
    } else {
        TweetJointCell *jointCell = [tableView dequeueReusableCellWithIdentifier:(NSString *)kTweetJointReuseIdentifier forIndexPath:indexPath];
        [jointCell endAnimating];
        cell = jointCell;
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!self.timelineService) {
        return UITableViewAutomaticDimension;
    }
    
    kTimelineObjectType type = [self.timelineService getObjectTypeAtIndex:indexPath.row];
    if (type == kTimelineObjectTweet) {
        MyTweet *tweet = [self.timelineService getTweetAtIndex:indexPath.row];
        return [TweetCell heightForCellWithTweet:tweet withCellWidth:tableView.frame.size.width];
        //return [TweetCell heightForLargeCellWithTweet:tweet withCellWidth:tableView.frame.size.width];
    } else if (type == kTimelineObjectJoint){
        return kTweetJointCellHeight;
    }
    
    return UITableViewAutomaticDimension;
}

/*
- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewAutomaticDimension;
}
*/

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
    
    if (!self.timelineService) {
        return;
    }
    
    kTimelineObjectType type = [self.timelineService getObjectTypeAtIndex:indexPath.row];
    if (type == kTimelineObjectTweet) {
        tweetForSegue = [self.timelineService getTweetAtIndex:indexPath.row];
        [self performSegueWithIdentifier:@"ShowTweetDetail" sender:self];
        NSLog(@"%@", [self.timelineService getTweetAtIndex:indexPath.row].dictionary);
    } else if (type == kTimelineObjectJoint){
        TweetJointCell *cell = (TweetJointCell *)[tableView cellForRowAtIndexPath:indexPath];
        if (![cell isAnimating] && !self.waitingResponse) {
            // 他の読み込みの時は排他しなければならない！
            [cell startAnimating];
            self.waitingResponse = [self.timelineService loadJointAtIndex:indexPath.row completion:^(NSUInteger startIndex, NSUInteger length, NSError *error) {
                self.waitingResponse = NO;
                //dispatch_async(dispatch_get_main_queue(), ^{
                    [cell endAnimating];
                    [self.tableView reloadData];
                //});
            }];
            if (!self.waitingResponse) {
                [cell endAnimating];
            }
        }
    }

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
    
    if ([segue.identifier isEqualToString:@"ShowTweetDetail"]) {
        TweetDetailViewController *controller = [segue destinationViewController];
        controller.parentTimeline = self;
        controller.selfTweet = tweetForSegue;
    } else if ([segue.identifier isEqualToString:@"ShowTweetEditFromTImeline"]) {
        TweetEditViewController *controller = [segue destinationViewController];
        controller.parentTimeline = self;
    }
}

@end
