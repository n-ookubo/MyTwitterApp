//
//  FileCacheService.m
//  twitterSample
//
//  Created by 大久保直昭 on 2015/07/26.
//  Copyright (c) 2015年 大久保直昭. All rights reserved.
//

#import "FileCacheService.h"
#import "NSString+MD5.h"
#import "ImageWrapper.h"

@interface FileCacheService ()
{
    NSTimeInterval intervalExpiresIn;
    NSMutableDictionary *rootDictionary;
    NSLock *rootDictionaryLock;
}
@end

@implementation FileCacheService
static FileCacheService *sharedService = nil;
static NSTimeInterval serviceIntervalExpiresIn = 72.0;
static const NSString *serviceStoredDictionaryFileName = @"index";
static NSString *serviceBundleIdentifier = nil;
static NSString *serviceCachesDirectoryUrlString = nil;

- (instancetype)init
{
    [NSException raise:NSGenericException format:@"init is not available. use [%@  %@] instead.", NSStringFromClass(self.class), NSStringFromSelector(@selector(sharedService))];
    return nil;
}

+ (FileCacheService *)sharedService
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedService = [[FileCacheService alloc] initWithExpiresInHours:serviceIntervalExpiresIn];
    });
    return sharedService;
}

+ (void)setExpiresInHours:(NSTimeInterval)hours
{
    if (hours > 0.0) {
        serviceIntervalExpiresIn = hours;
    }
}

+ (NSString *)urlStringWithName:(NSString *)name group:(NSString *)groupName;
{
    if (!serviceBundleIdentifier) {
        serviceBundleIdentifier = [NSBundle mainBundle].bundleIdentifier;
    }
    
    if (!serviceCachesDirectoryUrlString) {
        NSFileManager *manager = [NSFileManager defaultManager];
        NSArray *urls = [manager URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask];
        if (urls.count == 0) {
            return nil;
        }
        
        NSURL *url = [urls objectAtIndex:0];
        serviceCachesDirectoryUrlString = [url absoluteString];
    }
    
    NSString *urlString = [NSString stringWithFormat:@"%@/%@/CacheService", serviceCachesDirectoryUrlString, serviceBundleIdentifier];
    if (groupName) {
        if (name) {
            return [NSString stringWithFormat:@"%@/%@/%@", urlString, groupName, name];
        } else {
            return [NSString stringWithFormat:@"%@/%@/", urlString, groupName];
        }
    } else {
        if (name) {
            return [NSString stringWithFormat:@"%@/%@", urlString, name];
        } else {
            return [NSString stringWithFormat:@"%@/", urlString];
        }
    }
}

- (instancetype)initWithExpiresInHours:(NSTimeInterval)hours
{
    self = [super init];
    if (self) {
        intervalExpiresIn = hours;
        rootDictionary = [[NSMutableDictionary alloc] init];
        rootDictionaryLock = [[NSLock alloc] init];
    }
    return self;
}

- (NSTimeInterval)expiresInHours
{
    return intervalExpiresIn;
}

- (NSMutableDictionary *)dictionaryWithGroupName:(NSString *)groupName
{
    NSMutableDictionary *dic = [rootDictionary objectForKey:groupName];
    if (!dic) {
        dic = [[NSMutableDictionary alloc] init];
        [rootDictionary setObject:dic forKey:groupName];
    }
    
    return dic;
}

- (void)writeDictionaryWithGroupName:(NSString *)groupName
{
    NSString *storageUrlString = [self.class urlStringWithName:(NSString *)serviceStoredDictionaryFileName group:groupName];
    [[self dictionaryWithGroupName:groupName] writeToURL:[NSURL URLWithString:storageUrlString] atomically:YES];
}

- (NSDictionary *)loadStoredImageDictionaryWithGroupName:(NSString *)groupName
{
    if (!groupName) {
        return nil;
    }
    
    NSURL *dictionaryURL = [NSURL URLWithString:[self.class urlStringWithName:(NSString *)serviceStoredDictionaryFileName group:groupName]];
    NSFileManager *manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:dictionaryURL.path]) {
        return nil;
    }
    NSDictionary *storedDictionary = [NSDictionary dictionaryWithContentsOfURL:dictionaryURL];
    
    NSString *directoryPath = [NSURL URLWithString:[self.class urlStringWithName:nil group:groupName]].path;
    NSError *error = nil;
    NSArray *fileNames = [manager contentsOfDirectoryAtPath:directoryPath error:&error];
    if (error) {
        [rootDictionaryLock unlock];
        return nil;
    }
    
    [rootDictionaryLock lock];
    NSMutableDictionary *newDictionary = [self dictionaryWithGroupName:groupName];
    NSMutableDictionary *imageDictionary = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *costDictionary = [[NSMutableDictionary alloc] init];
    
    NSDate *now = [NSDate date];
    for (NSString *fileName in fileNames) {
        NSString *filePath = [directoryPath stringByAppendingFormat:@"/%@", fileName];
        
        if ([fileName isEqualToString:(NSString *)serviceStoredDictionaryFileName]) {
            continue;
        }
        
        NSString *urlString = [storedDictionary objectForKey:fileName];
        if (!urlString) {
            [manager removeItemAtPath:filePath error:&error];
            continue;
        }
        
        NSDictionary *attributes = [manager attributesOfItemAtPath:filePath error:&error];
        if (error) {
            [manager removeItemAtPath:filePath error:&error];
            continue;
        }
        
        NSDate *timestamp = attributes.fileModificationDate;
        NSTimeInterval interval = [now timeIntervalSinceDate:timestamp];
        NSTimeInterval elapsedHours = interval / 3600;
        if (elapsedHours > intervalExpiresIn) {
            [manager removeItemAtPath:filePath error:&error];
            continue;
        }
        
        [newDictionary setObject:urlString forKey:fileName];
        
        ImageWrapper *wrapper = [[ImageWrapper alloc] initWithCachedName:fileName cacheGroupName:groupName url:urlString timestamp:timestamp];
        [imageDictionary setObject:wrapper forKey:urlString];
        [costDictionary setObject:[NSNumber numberWithUnsignedLongLong:attributes.fileSize] forKey:urlString];
    }
    [rootDictionaryLock unlock];
    
    return @{@"image" : imageDictionary, @"cost" : costDictionary};
}

- (NSString *)setData:(NSData *)data forGroup:(NSString *)groupName asUrlString:(NSString *)urlString
{
    if (!data || !groupName || !urlString) {
        return nil;
    }
    
    NSString *name = [urlString md5Hash];
    
    [rootDictionaryLock lock];
    [[self dictionaryWithGroupName:groupName] setObject:urlString forKey:name];
    [self writeDictionaryWithGroupName:groupName];
    [rootDictionaryLock unlock];
    
    NSURL *directoryURL = [NSURL URLWithString:[self.class urlStringWithName:nil group:groupName]];
    NSError *error = nil;
    [[NSFileManager defaultManager] createDirectoryAtURL:directoryURL withIntermediateDirectories:YES attributes:nil error:&error];
    
    if (!error) {
        NSURL *fileURL = [NSURL URLWithString:[self.class urlStringWithName:name group:groupName]];
        [data writeToURL:fileURL atomically:YES];
        NSLog(@"add: %@/%@", groupName, name);
        return name;
    }
    
    return nil;
}

- (void)removeFileWithName:(NSString *)name group:(NSString *)groupName
{
    if (!name || !groupName) {
        return;
    }
    
    NSURL *fileURL = [NSURL URLWithString:[self.class urlStringWithName:name group:groupName]];
    
    [rootDictionaryLock lock];
    NSMutableDictionary *dic = [self dictionaryWithGroupName:groupName];
    if ([dic objectForKey:name]) {
        [dic removeObjectForKey:name];
        [self writeDictionaryWithGroupName:groupName];
        
        NSFileManager *manager = [NSFileManager defaultManager];
        if ([manager fileExistsAtPath:fileURL.path]) {
            NSError *error = nil;
            [manager removeItemAtURL:fileURL error:&error];
            NSLog(@"remove: %@/%@", groupName, name);
        }
    }
    [rootDictionaryLock unlock];
}

@end
