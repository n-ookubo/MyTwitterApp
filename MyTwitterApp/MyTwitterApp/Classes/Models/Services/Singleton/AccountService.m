//
//  AccountService.m
//  twitterSample
//
//  Created by 大久保直昭 on 2015/07/23.
//  Copyright (c) 2015年 大久保直昭. All rights reserved.
//

#import "AccountService.h"

@interface AccountService ()
@property (strong, nonatomic) ACAccountStore *store;
@end

@implementation AccountService
static NSString *identifierKey = @"accountIdentifier";
static AccountService *sharedService = nil;

- (instancetype)init
{
    [NSException raise:NSGenericException format:@"init is not available. use [%@  %@] instead.", NSStringFromClass(self.class), NSStringFromSelector(@selector(sharedService))];
    return nil;
}

+ (AccountService *)sharedService
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedService = [[AccountService alloc] initInternal];
    });
    return sharedService;
}

- (instancetype)initInternal
{
    self = [super init];
    if (self) {
        // ACAccountStoreの作成
        self.store = [[ACAccountStore alloc] init];
    }
    return self;
}

- (NSArray *)accessToStore:(BOOL *)accessGranted error:(NSError **)accessError
{
    ACAccountType *type = [self.store accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    
    __block BOOL _block_granted = NO;
    __block NSError *_block_error = nil;
    __block NSArray *_block_accounts = nil;
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    // アカウントに対するアクセス許可を求める
    [self.store requestAccessToAccountsWithType:type options:nil completion:^(BOOL granted, NSError *error) {
        _block_granted = granted;
        _block_error = error;
        if (error == nil && granted) {
            _block_accounts = [self.store accountsWithAccountType:type];
        }
        dispatch_semaphore_signal(semaphore);
    }];
    
    // 非同期処理の終了を待機する
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    if (accessGranted) {
        *accessGranted = _block_granted;
    }
    if (accessError) {
        *accessError = _block_error;
    }
    return _block_accounts;
}

- (NSDictionary *)getAccountInformationsWithReturningStatus:(BOOL *)rejected error:(NSError **)error;
{
    // アカウント配列の取得
    BOOL accessGranted;
    NSError *accessError = nil;
    NSArray *array = [self accessToStore:&accessGranted error:&accessError];
    
    if (error) {
        *error = accessError;
    }
    if (rejected) {
        *rejected = !accessGranted;
    }

    if (!array) {
        return nil;
    }
    
    // ユーザー名とアカウント識別子のペアを格納
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    for (ACAccount *account in array) {
        [dic setObject:account.identifier forKey:account.username];
    }
    return [[NSDictionary alloc] initWithDictionary:dic];
}

- (ACAccount *)defaultAccount
{
    // NSUserDefaultsから識別子を取得
    NSString *identifier = [[NSUserDefaults standardUserDefaults] objectForKey:identifierKey];
    if (!identifier) {
        return nil;
    }
    
    // アカウント配列の取得
    NSArray *array = [self accessToStore:nil error:nil];
    if (!array) {
        return nil;
    }

    // 識別子に対応するアカウントを返す
    for (ACAccount *account in array) {
        if ([account.identifier isEqualToString:identifier]) {
            return account;
        }
    }
    
    return nil;
}

- (ACAccount *)setDefaultAccountWithIdentifier:(NSString *)identifier rejected:(BOOL *)rejected error:(NSError **)error;
{
    // アカウント配列の取得
    BOOL accessGranted;
    NSError *accessError = nil;
    NSArray *array = [self accessToStore:&accessGranted error:&accessError];
    
    if (error) {
        *error = accessError;
    }
    if (rejected) {
        *rejected = !accessGranted;
    }

    if (!array) {
        return nil;
    }
    
    // 識別子に対応するアカウントを返す
    for (ACAccount *account in array) {
        if ([account.identifier isEqualToString:identifier]) {
            // 対応するアカウントが存在する時のみNSUserDefaultsに格納
            [[NSUserDefaults standardUserDefaults] setObject:identifier forKey:identifierKey];
            return account;
        }
    }
    
    return nil;
}
@end
