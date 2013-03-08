//
//  NSUserDefaults+WTSDKAddition.m
//  WeTongji
//
//  Created by 紫川 王 on 12-4-28.
//  Copyright (c) 2012年 Tongji Apple Club. All rights reserved.
//

#import "NSUserDefaults+WTSDKAddition.h"

#define kCurrentUserID              @"kCurrentUserID"
#define kCurrentUserSession         @"kCurrentUserSession"

@implementation NSUserDefaults (WTSDKAddition)

+ (NSString *)getStringForKey:(NSString *)key {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults objectForKey:key];
}

+ (void)setCurrentUserID:(NSString *)userID session:(NSString *)session {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:userID forKey:kCurrentUserID];
    [userDefaults setObject:session forKey:kCurrentUserSession];
    [userDefaults synchronize];
}

+ (NSString *)getCurrentUserID {
    return [NSUserDefaults getStringForKey:kCurrentUserID];
}

+ (NSString *)getCurrentUserSession {
    return [NSUserDefaults getStringForKey:kCurrentUserSession];
}

@end