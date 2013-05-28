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
#define HttpMethodUpLoadImage   @"UPLOAD_IMAGE"

@interface WTRequest : NSObject

@property (nonatomic, copy,     readonly) WTSuccessCompletionBlock successCompletionBlock;
@property (nonatomic, copy,     readonly) WTFailureCompletionBlock failureCompletionBlock;
@property (nonatomic, copy,     readonly) WTSuccessCompletionBlock preSuccessCompletionBlock;
@property (nonatomic, copy,     readonly) NSString *HTTPMethod;
@property (nonatomic, strong,   readonly) NSMutableDictionary *params;
@property (nonatomic, strong,   readonly) NSMutableDictionary *postValue;
@property (nonatomic, strong,   readonly) UIImage *uploadImage;
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

#pragma mark - Activity API

+ (BOOL)shouldActivityOrderByDesc:(NSUInteger)orderMethod
                       smartOrder:(BOOL)smartOrder
                       showExpire:(BOOL)showExpire;

- (void)getActivitiesInTypes:(NSArray *)showTypesArray
                 orderMethod:(NSUInteger)orderMethod
                  smartOrder:(BOOL)smartOrder
                  showExpire:(BOOL)showExpire
                        page:(NSUInteger)page;

- (void)setActivitiyLiked:(BOOL)liked
               activityID:(NSString *)activityID;

- (void)setActivityFavored:(BOOL)favored
                activityID:(NSString *)activityID;

- (void)setActivityScheduled:(BOOL)scheduled
                  activityID:(NSString *)activityID;

#pragma mark - Favorite API

- (void)getFavoritesInPage:(NSInteger)page;

#pragma - Information API

+ (BOOL)shouldInformationOrderByDesc:(NSUInteger)orderMethod
                          smartOrder:(BOOL)smartOrder;

- (void)getInformationInTypes:(NSArray *)showTypesArray
                  orderMethod:(NSUInteger)orderMethod
                   smartOrder:(BOOL)smartOrder
                         page:(NSUInteger)page;

- (void)setInformationLiked:(BOOL)liked
              informationID:(NSString *)informationID;

- (void)setInformationFavored:(BOOL)liked
                informationID:(NSString *)informationID;

#pragma mark - Vision API

- (void)getNewVersion;

#pragma - Star API

- (void)getLatestStar;

- (void)getStarsInPage:(NSInteger)page;

- (void)setStarLiked:(BOOL)liked
              starID:(NSString *)starID;


#pragma - Search API

- (void)getSearchResultInCategory:(NSInteger)category
                          keyword:(NSString *)keyword;

#pragma - Friend API

- (void)inviteFriend:(NSString *)userID;

- (void)removeFriend:(NSString *)userID;

- (void)getFriendsList;

- (void)acceptFriendInvitation:(NSString *)invitationID;

- (void)ignoreFriendInvitation:(NSString *)invitationID;

#pragma - Notification API

- (void)getNotificationInPage:(NSInteger)page;

#pragma - Billboard API

- (void)getBillboardPostsInPage:(NSUInteger)page;

- (void)addBillboardPostWithTitle:(NSString *)title
                          content:(NSString *)content
                            image:(UIImage *)image;

typedef enum {
    WTSDKBillboard,
    WTSDKActivity,
    WTSDKInformation,
    WTSDKStar,
} WTSDKModelType;

#pragma - Like API

#pragma - Comment API

- (void)getCommentsForModel:(WTSDKModelType)modelType
                    modelID:(NSString *)modelID
                       page:(NSInteger)page;

- (void)commentModel:(WTSDKModelType)modelType
             modelID:(NSString *)modelID
         commentBody:(NSString *)commentBody;

#pragma - Home API

- (void)getHomeRecommendation;

@end