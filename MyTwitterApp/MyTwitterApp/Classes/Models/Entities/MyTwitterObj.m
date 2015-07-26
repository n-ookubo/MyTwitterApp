//
//  MyTwitterObj.m
//  twitterSample
//
//  Created by 大久保直昭 on 2015/07/23.
//  Copyright (c) 2015年 大久保直昭. All rights reserved.
//

#import "MyTwitterObj.h"

@interface MyTwitterObj ()
@property (strong, readwrite) NSDictionary *dictionary;

@end

@implementation MyTwitterObj
- (instancetype)init
{
    [NSException raise:NSGenericException format:@"init is not available. use [[%@ alloc] %@] instead.", NSStringFromClass(self.class), NSStringFromSelector(@selector(initWithDictionary:))];
    return nil;
}

- (instancetype)initWithDictionary:(NSDictionary *)dic
{
    self = [super init];
    if (self) {
        if (!dic) {
            return nil;
        }
        
        self.dictionary = dic;
    }
    return self;
}

@end