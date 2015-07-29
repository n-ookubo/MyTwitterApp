//
//  ImageWrapper.m
//  twitterSample
//
//  Created by 大久保直昭 on 2015/07/25.
//  Copyright (c) 2015年 大久保直昭. All rights reserved.
//

#import "ImageWrapper.h"
#import "FileCacheService.h"

@interface ImageWrapper ()
{
    BOOL isValid;
    BOOL storedInFile;
    NSString *urlString;
    
    NSDate *loadedAt;
    
    NSData *imageData;
    
    NSString *groupName;
    NSString *fileName;
}

@end

@implementation ImageWrapper

- (instancetype)init
{
    [NSException raise:NSGenericException format:@"init is not available. use [[%@ alloc] %@] instead.", NSStringFromClass(self.class), NSStringFromSelector(@selector(initWithData:cacheGroupName:url:timestamp:))];
    return nil;
}

- (instancetype)initWithData:(NSData *)data cacheGroupName:(NSString *)cacheGroupName url:(NSString *)url timestamp:(NSDate *)timestamp
{
    self = [super init];
    if (self) {
        if (!url || !data) {
            return nil;
        }
        urlString = url;
        loadedAt = timestamp ? timestamp : [NSDate date];
        if (cacheGroupName) {
            storedInFile = YES;
            groupName = cacheGroupName;
            fileName = [[FileCacheService sharedService] setImageCacheData:data forGroup:cacheGroupName asUrlString:url];
            if (!fileName) {
                return nil;
            }
            imageData = nil;
        } else {
            storedInFile = NO;
            imageData = data;
        }
        
        isValid = YES;
    }
    return self;
}

- (instancetype)initWithCachedName:(NSString *)cachedName cacheGroupName:(NSString *)cacheGroupName url:(NSString *)url timestamp:(NSDate *)timestamp
{
    self = [super init];
    if (self) {
        if (!cachedName || !cacheGroupName || !url) {
            return nil;
        }
        
        urlString = url;
        loadedAt = timestamp ? timestamp : [NSDate date];
        storedInFile = YES;
        groupName = cacheGroupName;
        fileName = cachedName;
        imageData = nil;
        
        isValid = YES;
    }
    return self;
}

- (void)checkExpiration
{
    NSDate *now = [NSDate date];
    NSTimeInterval interval = [now timeIntervalSinceDate:loadedAt];
    NSTimeInterval elapsedHours = interval / 3600;
    
    NSTimeInterval expiresIn = [[FileCacheService sharedService] imageCacheExpiresInHours];
    if (elapsedHours > expiresIn) {
        // expired
        [self discard];
    }
}

- (void) discard
{
    if (storedInFile) {
        [[FileCacheService sharedService] removeImageCacheFileWithName:fileName group:groupName];
    } else {
        imageData = nil;
    }
    isValid = NO;
}

#pragma mark NSObject

- (NSString *)description
{
    if (!isValid) {
        return @"(invalid)";
    }
    
    if (storedInFile) {
        return [@{@"name" : fileName, @"group" : groupName, @"loadedAt" : loadedAt} description];
    } else {
        return [NSString stringWithFormat:@"(NSData loadedAt: %@)", loadedAt];
    }
}


#pragma mark NSDiscardableContent

- (BOOL)beginContentAccess
{
    return isValid;
}

- (void)endContentAccess
{
    
}

- (void)discardContentIfPossible
{
    // キャッシュからの消去時にコールされる
    // 可能ならオブジェクトを破棄する
    NSLog(@"discardContentIfPossible: %@", fileName);
    [self discard];
}

- (BOOL)isContentDiscarded
{
    // キャッシュアクセス時にコールされる
    // YESを返すと、キャッシュはオブジェクトの再取得を試みる
    NSLog(@"isContentDiscarded: %@", fileName);
    [self checkExpiration];
    return !isValid;
}

#pragma mark MyCacheContent

- (id)cachedValue
{
    if (!isValid) {
        return nil;
    }
    
    NSLog(@"cachedValue: %@", fileName);
    
    if (storedInFile) {
        NSString *path = [NSURL URLWithString:[FileCacheService urlStringWithName:fileName group:groupName]].path;
        return [[UIImage alloc] initWithContentsOfFile:path];
    } else {
        return [[UIImage alloc] initWithData:imageData];
    }
}
@end
