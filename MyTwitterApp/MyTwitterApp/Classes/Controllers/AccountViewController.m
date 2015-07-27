//
//  AccountViewController.m
//  MyTwitterApp
//
//  Created by 大久保直昭 on 2015/07/27.
//  Copyright (c) 2015年 大久保直昭. All rights reserved.
//

#import "AccountViewController.h"
#import "AppDelegate.h"
#import "AccountService.h"

@interface AccountViewController ()
@property (strong, nonatomic) NSDictionary *accounts;

@end

@implementation AccountViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.title = @"アカウント選択";
    
    UIBarButtonItem *refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(updateAccounts)];
    self.navigationItem.rightBarButtonItem = refreshButton;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateAccounts) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated
{
    [self updateAccounts];
}

- (void)updateAccounts
{
    BOOL rejected;
    NSError *error = nil;
    self.accounts = [[AccountService sharedService] getAccountInformationsWithReturningStatus:&rejected error:&error];
    
    [self showErrorMessage:self.accounts rejected:rejected error:error];
    [self.tableView reloadData];
}

- (void)showErrorMessage:(NSDictionary *)accounts rejected:(BOOL)rejected error:(NSError *)error
{
    NSString *message = nil;
    if (rejected) {
        message = @"アカウントの取得に失敗しました。環境設定からTwitterアカウントへのアクセスを許可してください。";
    } else if (error) {
        message = [NSString stringWithFormat:@"アカウントの取得に失敗しました。（%@）", [error localizedDescription]];
    } else if (accounts && accounts.count == 0) {
        message = @"利用可能なTwitterアカウントが登録されていません。";
    }
    
    if (message) {
        UIAlertController *controller = [UIAlertController alertControllerWithTitle:@"アカウント取得失敗" message:message preferredStyle:UIAlertControllerStyleAlert];
        [controller addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self.view.window.rootViewController presentViewController:controller animated:YES completion:nil];
    }

}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.accounts) {
        NSString *key = self.accounts.allKeys[indexPath.row];
        NSString *identifier = [self.accounts objectForKey:key];
        
        BOOL rejected;
        NSError *error = nil;
        ACAccount *account = [[AccountService sharedService] setDefaultAccountWithIdentifier:identifier rejected:&rejected error:&error];
        [self showErrorMessage:nil rejected:rejected error:error];
        
        if (account) {
            TwitterService *twitterService = [[TwitterService alloc] initWithAccount:account];
            
            AppDelegate *delegate = [[UIApplication sharedApplication] delegate];
            delegate.twitterService = twitterService;
            
            [self.navigationController performSegueWithIdentifier:@"FinishChoosingAccount" sender:self];
        }
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return self.accounts ? 1 : 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return self.accounts ? self.accounts.count : 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"accountCell" forIndexPath:indexPath];
    
    // Configure the cell...
    if (self.accounts) {
        cell.textLabel.text = self.accounts.allKeys[indexPath.row];
    }
    
    return cell;
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
