//
//  WTClient.h
//  WeTongjiSDK
//
//  Created by tang zhixiong on 12-11-7.
//  Copyright (c) 2012年 WeTongji. All rights reserved.
//

#import <SystemConfiguration/SystemConfiguration.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <UIKit/UIKit.h>
#import "WTCommon.h"
#import "AFHTTPClient.h"
#import "AFHTTPRequestOperation.h"
#import "NSUserDefaults+Addition.h"

#define GetActivitySortMethodLikeDesc   @"`like` DESC"
#define GetActivitySortMethodBeginDesc  @"`begin` DESC"
#define GetActivitySortMethodCreateDesc @"`created_at` DESC"

#define GetInformationTypeSchoolNews @"SchoolNews"
#define GetInformationTypeClubNews @"ClubNews"
#define GetInformationTypeAround @"Around"
#define GetInformationTypeForStaff @"ForStaff"

@class WTRequest;

@interface WTRequest : NSObject

@property (nonatomic, readonly, strong) NSMutableDictionary *params;
@property (nonatomic, readonly, strong) NSMutableDictionary *postValue;
@property (nonatomic, readonly, strong) UIImage *avatarImage;
@property (nonatomic, readonly) NSString *queryString;

+ (WTRequest *)requestWithSuccessBlock:(WTSuccessCompletionBlock)success
                          failureBlock:(WTFailureCompletionBlock)failure;

#pragma mark - User API

- (void)login:(NSString *)num password:(NSString *)password;

- (void)logoff;

- (void)activeUserWithNo:(NSString *)studentNumber
                password:(NSString *)password
                    name:(NSString *)name;

- (void)updateUserDisplayName:(NSString *)displayName
                        email:(NSString *)email
                    weiboName:(NSString *)weibo
                     phoneNum:(NSString *)phone
                    qqAccount:(NSString *)qq;

- (void)updatePassword:(NSString *)new oldPassword:(NSString *)old;

- (void)updateUserAvatar:(UIImage *)image;

- (void)getUserInformation;

- (void)resetPasswordWithNO:(NSString *)studentNumber
                       Name:(NSString*)name;

#pragma mark - Course API

- (void)getCourses;

#pragma mark - calender API

- (void)getScheduleWithBeginDate:(NSDate *)begin endDate:(NSDate *)end;

#pragma mark - Channel API

- (void)setChannelFavored:(NSString *)channelID;
 
- (void)cancelChannelFavored:(NSString *)channelID;

- (void)getChannels;

#pragma mark - Activity API

- (void)getActivitiesInChannel:(NSString *)channelID
                        inSort:(NSString *)sort
                       Expired:(BOOL)isExpired
                      nextPage:(int)nextPage;

- (void)setLikeActivitiy:(NSString *)activityID;

- (void)cancelLikeActivity:(NSString *)activityID;

- (void)setActivityFavored:(NSString *)activityID;

- (void)cancelActivityFavored:(NSString *)activityID;

- (void)setActivityScheduled:(NSString *)activityID;

- (void)cancelActivityScheduled:(NSString *)activityID;

#pragma - Favorite API

- (void)getFavoritesWithNextPage:(int)nextPage;

#pragma - Information API

- (void)getAllInformationInType:(NSString *) type
                           sort:(NSString *)sort
                       nextPage:(int)nextPage;

- (void)getDetailOfInformaion:(NSString *)informationID
                       inType:(NSString *)type;

- (void)readInformaion:(NSString *)informationID
                inType:(NSString *) type;

- (void)setInformationFavored:(NSString *)informationID
                       inType:(NSString *) type;

- (void)setInformationUnFavored:(NSString *)informationID
                         inType:(NSString *) type;

- (void)setInformationLike:(NSString *)informationID
                    inType:(NSString *) type;

- (void)setInformationUnLike:(NSString *)informationID
                      inType:(NSString *) type;

#pragma - Vision API

- (void)getNewVersion;

#pragma - Star API

- (void)getLatestStar;

- (void)getAllStarsWithNextPage:(int)nextPage;

- (void)readStar:(NSString *)starID;

- (void)setStarFavored:(NSString *)starID;

- (void)cancelStarFaved:(NSString *)starID;

- (void)likeStar:(NSString *)starID;

- (void)unlikeStar:(NSString *)starID;

@end

@interface WTClient : AFHTTPClient

+ (WTClient *)sharedClient;

- (void)enqueueRequest:(WTRequest *)request;

@end
