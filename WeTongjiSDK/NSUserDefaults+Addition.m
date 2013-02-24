//
//  NSUserDefaults+Addition.m
//  WeTongji
//
//  Created by 紫川 王 on 12-4-28.
//  Copyright (c) 2012年 Tongji Apple Club. All rights reserved.
//

#import "NSUserDefaults+Addition.h"

typedef enum {
    ChannelLecture = 0,
    ChannelEntertainment = 1,
    ChannelMatch = 2,
    ChannelEnterprise = 3,
} ChannelName;

#define kCurrentUserID              @"kCurrentUserID"
#define kCurrentUserSession         @"kCurrentUserSession"
#define kCurrentUIStyle             @"kCurrentUIStyle"
#define kCurrentSemesterBeginTime   @"kCurrentSemesterBeginTime"
#define kCurrentSemesterEndTime     @"kCurrentSemesterEndTime"
#define kShowExpireActivities       @"kShowExpireActivities"

@implementation NSUserDefaults (Addition)

+ (void)setChannelFollowStatus:(NSArray *)channelsStatus {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    for(int i = 0; i < channelsStatus.count; i++) {
        NSNumber *channelStatus = channelsStatus[i];
        NSString *channelKey = [NSString stringWithFormat:@"follow_channel_%d", i];
        [userDefaults setBool:channelStatus.boolValue forKey:channelKey];
    }
    [userDefaults synchronize];
}

+ (NSArray *)getChannelFollowStatusArray {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:4];
    for(int i = 0; i < 4; i++) {
        NSString *channelKey = [NSString stringWithFormat:@"follow_channel_%d", i];
        [result addObject:@([userDefaults boolForKey:channelKey])];
    }
    return result;
}

+ (NSArray *)getFollowedChannelArray {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:4];
    for(int i = 0; i < 4; i++) {
        NSString *channelKey = [NSString stringWithFormat:@"follow_channel_%d", i];
        if ([userDefaults boolForKey:channelKey])
            [result addObject:@(i)];
    }
    return result;
}

+ (NSString *)getChannelFollowStatusString {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSMutableString *result = nil;
    for(int i = 0; i < 4; i++) {
        NSString *channelKey = [NSString stringWithFormat:@"follow_channel_%d", i];
        if ([userDefaults boolForKey:channelKey]) {
            if (result)
                [result appendFormat:@",%d", i + 1];
            else 
                result = [NSMutableString stringWithFormat:@"%d", i + 1];
        }
    }
    NSLog(@"channel follow str:%@", result);
    return result;
}

+ (void)setShowExpireActivitiesParam:(BOOL)ignore {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:ignore forKey:kShowExpireActivities];
    [userDefaults synchronize];
}

+ (BOOL)getShowExpireActivitiesParam {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults boolForKey:kShowExpireActivities];
}

+ (void)setChannelSortMethodArray:(NSArray *)sortMethods {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    for(int i = 0; i < sortMethods.count; i++) {
        NSNumber *channelStatus = sortMethods[i];
        NSString *channelKey = [NSString stringWithFormat:@"sort_channel_%d", i];
        [userDefaults setBool:channelStatus.boolValue forKey:channelKey];
    }
    [userDefaults synchronize];
}

+ (NSArray *)getChannelSortMethodArray {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:2];
    for(int i = 0; i < ChannelSortMethodCount; i++) {
        NSString *channelSortKey = [NSString stringWithFormat:@"sort_channel_%d", i];
        [result addObject:@([userDefaults boolForKey:channelSortKey])];
    }
    return result;
}

+ (ChannelSortMethod)getChannelSortMethod {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    for(int i = 0; i < ChannelSortMethodCount; i++) {
        NSString *channelSortKey = [NSString stringWithFormat:@"sort_channel_%d", i];
        if ([userDefaults boolForKey:channelSortKey])
            return i;
    }
    return 0;
}

+ (NSArray *)getChannelNameArray {
    return @[@"学术讲座", @"赛事信息", @"文娱活动", @"企业招聘"];
}

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

+ (UIStyle)getCurrentUIStyle {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    UIStyle style = [userDefaults integerForKey:kCurrentUIStyle];
    return style;
}

+ (void)setCurrentUIStyle:(UIStyle)style {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setInteger:style forKey:kCurrentUIStyle];
    [userDefaults synchronize];
}

+ (void)setCurrentSemesterBeginTime:(NSDate *)begin endTime:(NSDate *)end {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:begin forKey:kCurrentSemesterBeginTime];
    [userDefaults setObject:end forKey:kCurrentSemesterEndTime];
    [userDefaults synchronize];
}

+ (NSDate *)getCurrentSemesterBeginDate {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults objectForKey:kCurrentSemesterBeginTime];
}

+ (NSDate *)getCurrentSemesterEndDate {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults objectForKey:kCurrentSemesterEndTime];
}

@end
