//
//  AccountService.h
//  twitterSample
//
//  Created by 大久保直昭 on 2015/07/23.
//  Copyright (c) 2015年 大久保直昭. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Accounts/Accounts.h>

/**
 iOSが管理するTwitterアカウントの取得を行うクラス
 */
@interface AccountService : NSObject
- (instancetype) __unavailable init;
+ (AccountService *)sharedService;
/**
 ユーザー名とアカウント識別子のペアを格納したNSDictionaryを返す
 
 @param rejected アカウントへのアクセスがユーザーに拒否された場合はYES
 @param error アカウントアクセス時にエラーが発生した場合はNSErrorインスタンスが返る
 @return NSDictionaryインスタンス。取得に失敗した場合はnil
 */
- (NSDictionary *)getAccountInformationsWithReturningStatus:(BOOL *)rejected error:(NSError **)error;

/**
 NSUserDefaultsに格納された識別子を利用してアカウントの取得を試みる
 
 @return ACAccountインスタンス。取得に失敗した場合はnil
 */
- (ACAccount *)defaultAccount;

/**
 指定した識別子をNSUserDefaultsに書き込み、
 識別子に対応するアカウントを取得する
 
 @param rejected アカウントへのアクセスがユーザーに拒否された場合はYES
 @param error アカウントアクセス時にエラーが発生した場合はNSErrorインスタンスが返る
 @return ACAccountインスタンス。取得に失敗した場合はnil
 */
- (ACAccount *)setDefaultAccountWithIdentifier:(NSString *)identifier rejected:(BOOL *)rejected error:(NSError **)error;
@end
