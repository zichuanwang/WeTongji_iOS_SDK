//
//  WTRequest.h
//  WeTongjiSDK
//
//  Created by 王 紫川 on 13-3-8.
//  Copyright (c) 2013年 WeTongji. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "WTCommon.h"
#import "AFHTTPRequestOperation.h"
#import "NSUserDefaults+WTSDKAddition.h"

#define GetActivitySortMethodLikeDesc   @"`like` DESC"
#define GetActivitySortMethodBeginDesc  @"`begin` DESC"
#define GetActivitySortMethodCreateDesc @"`created_at` DESC"

#define GetInformationTypeSchoolNews    @"SchoolNews"
#define GetInformationTypeClubNews      @"ClubNews"
#define GetInformationTypeAround        @"Around"
#define GetInformationTypeForStaff      @"ForStaff"

#define HttpMethodGET           @"GET"
#define HttpMethodPOST          @"POST"
#define HttpMethodUpLoadAvatar  @"UPLOAD_AVATAR"

@interface WTRequest : NSObject

@property (nonatomic, copy,     readonly) WTSuccessCompletionBlock successCompletionBlock;
@property (nonatomic, copy,     readonly) WTFailureCompletionBlock failureCompletionBlock;
@property (nonatomic, copy,     readonly) WTSuccessCompletionBlock preSuccessCompletionBlock;
@property (nonatomic, copy,     readonly) NSString *HTTPMethod;
@property (nonatomic, strong,   readonly) NSMutableDictionary *params;
@property (nonatomic, strong,   readonly) NSMutableDictionary *postValue;
@property (nonatomic, strong,   readonly) UIImage *avatarImage;
@property (nonatomic, copy,     readonly) NSString *queryString;
@property (nonatomic, assign,   readonly, getter = isValid) BOOL valid;
@property (nonatomic, strong,   readonly) NSError *error;

+ (WTRequest *)requestWithSuccessBlock:(WTSuccessCompletionBlock)success
                          failureBlock:(WTFailureCompletionBlock)failure;

#pragma mark - User API

- (void)login:(NSString *)num password:(NSString *)password;

- (void)activateUserWithNo:(NSString *)studentNumber
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

#pragma mark - Schedule API

- (void)getScheduleWithBeginDate:(NSDate *)begin endDate:(NSDate *)end;

#pragma mark - Channel API

- (void)setChannelFavored:(NSString *)channelID;

- (void)cancelChannelFavored:(NSString *)channelID;

- (void)getChannels;

#pragma mark - Activity API

+ (BOOL)shouldActivityOrderByDesc:(NSUInteger)orderMethod
                       smartOrder:(BOOL)smartOrder
                       showExpire:(BOOL)showExpire;

- (void)getActivitiesInTypes:(NSArray *)showTypesArray
                 orderMethod:(NSUInteger)orderMethod
                  smartOrder:(BOOL)smartOrder
                  showExpire:(BOOL)showExpire
                        page:(NSUInteger)page;

- (void)setActivitiyLiked:(BOOL)liked activityID:(NSString *)activityID;

- (void)setActivityFavored:(BOOL)favored activityID:(NSString *)activityID;

- (void)setActivityScheduled:(BOOL)scheduled activityID:(NSString *)activityID;

#pragma mark - Favorite API

- (void)getFavoritesWithNextPage:(int)nextPage;

#pragma - News API

- (void)getNewsInTypes:(NSArray *)showTypesArray
            sortMethod:(NSString *)sortMethod
                  page:(NSUInteger)page;

- (void)setNewsLiked:(BOOL)liked newsID:(NSString *)newsID;

#pragma - Information API

- (void)getAllInformationInType:(NSString *)type
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

#pragma mark - Vision API

- (void)getNewVersion;

#pragma - Star API

- (void)getLatestStar;

- (void)getAllStarsWithNextPage:(int)nextPage;

- (void)readStar:(NSString *)starID;

- (void)setStarFavored:(NSString *)starID;

- (void)cancelStarFaved:(NSString *)starID;

- (void)likeStar:(NSString *)starID;

- (void)unlikeStar:(NSString *)starID;

#pragma - Search API

- (void)search:(NSString *)command;

#pragma - Friend API

- (void)inviteFriend:(NSString *)userID;

- (void)removeFriend:(NSString *)userID;

- (void)getFriendsList;

- (void)acceptFriendInvitation:(NSString *)invitationID;

- (void)ignoreFriendInvitation:(NSString *)invitationID;

#pragma - Notification API

- (void)getNotificationList;

@end