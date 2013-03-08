//
//  WTRequest.m
//  WeTongjiSDK
//
//  Created by 王 紫川 on 13-3-8.
//  Copyright (c) 2013年 WeTongji. All rights reserved.
//

#import "WTRequest.h"
#import "NSString+URLEncoding.h"
#import "NSString+WTSDKAddition.h"
#import "JSON.h"
#import "NSError+WTSDKClientErrorGenerator.h"

@interface WTRequest()

@property (nonatomic, copy)     WTSuccessCompletionBlock successCompletionBlock;
@property (nonatomic, copy)     WTFailureCompletionBlock failureCompletionBlock;
@property (nonatomic, copy)     WTSuccessCompletionBlock preSuccessCompletionBlock;
@property (nonatomic, copy)     NSString *HTTPMethod;

@property (nonatomic, strong)   NSMutableDictionary *params;
@property (nonatomic, strong)   NSMutableDictionary *postValue;
@property (nonatomic, strong)   UIImage *avatarImage;

@property (nonatomic, assign)   BOOL valid;
@property (nonatomic, strong)   NSError *error;

@end

@implementation WTRequest

#pragma mark - Constructors

+ (WTRequest *)requestWithSuccessBlock:(WTSuccessCompletionBlock)success
                          failureBlock:(WTFailureCompletionBlock)failure {
    WTRequest *result = [[WTRequest alloc] init];
    result.successCompletionBlock = success;
    result.failureCompletionBlock = failure;
    result.HTTPMethod = HttpMethodGET;
    return result;
}

- (id)init {
    self = [super init];
    if (self) {
        self.valid = true;
    }
    return self;
}

#pragma mark - Properties

- (NSMutableDictionary *)postValue
{
    if (!_postValue) {
        _postValue = [[NSMutableDictionary alloc] init];
    }
    return _postValue;
}

- (NSMutableDictionary *)params
{
    if (!_params) {
        _params = [[NSMutableDictionary alloc] init];
        _params[@"D"] = [NSBundle mainBundle].bundleIdentifier;
        NSString *version = [NSBundle mainBundle].infoDictionary[@"CFBundleShortVersionString"];
        _params[@"V"] = version;
    }
    return _params;
}

- (NSString *)queryString {
    NSArray *names = [self.params allKeys];
    NSArray *sortedNames = [names sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSString *str1 = (NSString *)obj1;
        NSString *str2 = (NSString *)obj2;
        return [str1 compare:str2];
    }];
    
    NSMutableString *result = [NSMutableString stringWithCapacity:10];
    for (int i = 0; i < [sortedNames count]; i++) {
        if (i > 0)
            [result appendString:@"&"];
        NSString *name = sortedNames[i];
        NSString *parameter = self.params[name];
        [result appendString:[NSString stringWithFormat:@"%@=%@", [name URLEncodedString],
                              [parameter URLEncodedString]]];
    }
    
    return result;
}

#pragma mark - Logic methods

- (void)addHashParam {
    NSArray *names = [self.params allKeys];
    NSArray *sortedNames = [names sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSString *str1 = (NSString *)obj1;
        NSString *str2 = (NSString *)obj2;
        return [str1 compare:str2];
    }];
    
    NSMutableString *result = [NSMutableString stringWithCapacity:10];
    for (int i = 0; i < [sortedNames count]; i++) {
        if (i > 0)
            [result appendString:@"&"];
        NSString *name = sortedNames[i];
        NSString *parameter = self.params[name];
        [result appendString:[NSString stringWithFormat:@"%@=%@", [name URLEncodedString],
                              [parameter URLEncodedString]]];
    }
    NSString *md5 = [result md5HexDigest];
    self.params[@"H"] = md5;
}

- (void)addUserIDAndSessionParams {
    if ([NSUserDefaults getCurrentUserID] && [NSUserDefaults getCurrentUserSession]) {
        (self.params)[@"U"] = [NSUserDefaults getCurrentUserID];
        (self.params)[@"S"] = [NSUserDefaults getCurrentUserSession];
    } else {
        self.valid = false;
        NSError *error = [NSError createErrorWithErrorCode:ErrorCodeNeedUserLogin];
        self.error = error;
    }
}

#pragma mark - Configure API parameters
#pragma mark User API

- (void)login:(NSString *)num password:(NSString *)password {
    self.params[@"M"] = @"User.LogOn";
    self.params[@"NO"] = num;
    self.params[@"Password"] = password;
    [self setPreSuccessCompletionBlock: ^(id responseData) {
        [NSUserDefaults setCurrentUserID:responseData[@"User"][@"UID"] session:responseData[@"Session"]];
    }];
    [self addHashParam];
}

- (void)logout {
    self.params[@"M"] = @"User.LogOff";
    [self addHashParam];
}

- (void)activateUserWithNo:(NSString *)studentNumber
                  password:(NSString *)password
                      name:(NSString *)name {
    self.params[@"M"] = @"User.Active";
    self.params[@"NO"] = studentNumber;
    self.params[@"Password"] = password;
    self.params[@"Name"] = name;
    [self addHashParam];
}

- (void)updateUserDisplayName:(NSString *)displayName
                        email:(NSString *)email
                    weiboName:(NSString *)weibo
                     phoneNum:(NSString *)phone
                    qqAccount:(NSString *)qq {
    (self.params)[@"M"] = @"User.Update";
    [self addUserIDAndSessionParams];
    
    NSMutableDictionary *itemDict = [[NSMutableDictionary alloc] init];
    if (displayName != nil) itemDict[@"DisplayName"] = displayName;
    if (email != nil) itemDict[@"Email"] = email;
    if (weibo != nil) itemDict[@"SinaWeibo"] = weibo;
    if (phone != nil) itemDict[@"Phone"] = phone;
    if (qq != nil) itemDict[@"QQ"] = qq;
    NSDictionary *userDict = @{@"User": itemDict};
    NSString *userJSONStr = [userDict JSONRepresentation];
    
    [self addHashParam];
    (self.postValue)[@"User"] = userJSONStr;
    self.HTTPMethod = HttpMethodPOST;
}

- (void)updatePassword:(NSString *)new oldPassword:(NSString *)old {
    (self.params)[@"M"] = @"User.Update.Password";
    [self addUserIDAndSessionParams];
    (self.params)[@"New"] = new;
    (self.params)[@"Old"] = old;
    [self addHashParam];
}

- (void)updateUserAvatar:(UIImage *)image {
    (self.params)[@"M"] = @"User.Update.Avatar";
    [self addUserIDAndSessionParams];
    self.avatarImage = image;
    self.HTTPMethod = HttpMethodUpLoadAvatar;
    [self addHashParam];
}

- (void)getUserInformation {
    (self.params)[@"M"] = @"User.Get";
    [self addUserIDAndSessionParams];
    [self addHashParam];
}

- (void)resetPasswordWithNO:(NSString *)studentNumber
                       Name:(NSString*)name {
    (self.params)[@"M"] = @"User.Reset.Password";
    (self.params)[@"NO"] = studentNumber;
    (self.params)[@"Name"] = name;
    [self addHashParam];
}

#pragma mark Schedule API

- (void)getScheduleWithBeginDate:(NSDate *)begin endDate:(NSDate *)end {
    (self.params)[@"M"] = @"Schedule.Get";
    [self addUserIDAndSessionParams];
    (self.params)[@"Begin"] = [NSString standardDateStringCovertFromDate:begin];
    (self.params)[@"End"] = [NSString standardDateStringCovertFromDate:end];
    [self addHashParam];
}

#pragma mark Channel API

- (void)setChannelFavored:(NSString *)channelID {
    [self addUserIDAndSessionParams];
    (self.params)[@"M"] = @"Channel.Favorite";
    (self.params)[@"Id"] = channelID;
    [self addHashParam];
}

- (void)cancelChannelFavored:(NSString *)channelID {
    [self addUserIDAndSessionParams];
    (self.params)[@"M"] = @"Channel.UnFavorite";
    (self.params)[@"Id"] = channelID;
    [self addHashParam];
}

- (void)getChannels {
    (self.params)[@"M"] = @"Channels.Get";
    [self addHashParam];
}

#pragma mark Activity API

- (void)getActivitiesInChannel:(NSString *)channelID
                        inSort:(NSString *)sort
                       Expired:(BOOL)isExpired
                      nextPage:(int)nextPage {
    (self.params)[@"M"] = @"Activities.Get";
    if (channelID) (self.params)[@"Channel_Ids"] = channelID;
    if (sort) (self.params)[@"Sort"] = sort;
    if (isExpired) (self.params)[@"Expire"] = [NSString stringWithFormat:@"%d", isExpired];
    (self.params)[@"P"] = [NSString stringWithFormat:@"%d",nextPage];
    [self addHashParam];
}

- (void)setLikeActivitiy:(NSString *)activityID {
    [self addUserIDAndSessionParams];
    (self.params)[@"M"] = @"Activity.Like";
    (self.params)[@"Id"] = activityID;
    [self addHashParam];
}

- (void)cancelLikeActivity:(NSString *)activityID {
    [self addUserIDAndSessionParams];
    (self.params)[@"M"] = @"Activity.UnLike";
    (self.params)[@"Id"] = activityID;
    [self addHashParam];
}

- (void)setActivityFavored:(NSString *)activityID {
    [self addUserIDAndSessionParams];
    (self.params)[@"M"] = @"Activity.Favorite";
    (self.params)[@"Id"] = activityID;
    [self addHashParam];
}

- (void)cancelActivityFavored:(NSString *)activityID {
    [self addUserIDAndSessionParams];
    (self.params)[@"M"] = @"Activity.UnFavorite";
    (self.params)[@"Id"] = activityID;
    [self addHashParam];
}

- (void)setActivityScheduled:(NSString *)activityID
{
    [self addUserIDAndSessionParams];
    (self.params)[@"M"] = @"Activity.Schedule";
    (self.params)[@"Id"] = activityID;
    [self addHashParam];
}

- (void)cancelActivityScheduled:(NSString *)activityID
{
    [self addUserIDAndSessionParams];
    (self.params)[@"M"] = @"Activity.UnSchedule";
    (self.params)[@"Id"] = activityID;
    [self addHashParam];
}

#pragma Favorite API

- (void)getFavoritesWithNextPage:(int)nextPage {
    [self addUserIDAndSessionParams];
    (self.params)[@"M"] = @"Favorite.Get";
    (self.params)[@"P"] = [NSString stringWithFormat:@"%d",nextPage];
    [self addHashParam];
}

#pragma News API

- (void)getNewsInTypes:(NSArray *)type
            sortMethod:(NSString *)sort
                  page:(unsigned int)page {
    self.params[@"M"] = @"SchoolNews.GetList";
    if (sort)
        self.params[@"Sort"] = sort;
    self.params[@"P"] = [NSString stringWithFormat:@"%d", page];
    [self addHashParam];
}

#pragma Information API

// TODO: Remove the following information methods

- (void)getAllInformationInType:(NSString *)type sort:(NSString *)sort
                       nextPage:(int)nextPage {
    NSString * resultM;
    if ( [type isEqualToString:GetInformationTypeClubNews] || [type isEqualToString:GetInformationTypeSchoolNews] ){
        resultM = [type stringByAppendingString:@".GetList"];
    }
    if ( [type isEqualToString:GetInformationTypeAround] || [type isEqualToString:GetInformationTypeForStaff] ) {
        resultM = [type stringByAppendingString:@"s.Get"];
    }
    (self.params)[@"M"] = resultM;
    if (sort) (self.params)[@"Sort"] = sort;
    (self.params)[@"P"] = [NSString stringWithFormat:@"%d", nextPage];
    [self addHashParam];
}

- (void)getDetailOfInformaion:(NSString *)informationID inType:(NSString *)type {
    (self.params)[@"M"] = [type stringByAppendingString:@".Get"];
    (self.params)[@"Id"] = informationID;
    [self addHashParam];
}

- (void)readInformaion:(NSString *)informationID inType:(NSString *) type {
    (self.params)[@"M"] = [type stringByAppendingString:@".Read"];
    (self.params)[@"Id"] = informationID;
    [self addHashParam];
}

- (void)setInformationFavored:(NSString *)informationID inType:(NSString *) type{
    [self addUserIDAndSessionParams];
    (self.params)[@"M"] = [type stringByAppendingString:@".Favorite"];
    (self.params)[@"Id"] = informationID;
    [self addHashParam];
}

- (void)setInformationUnFavored:(NSString *)informationID inType:(NSString *) type{
    [self addUserIDAndSessionParams];
    (self.params)[@"M"] = [type stringByAppendingString:@".UnFavorite"];
    (self.params)[@"Id"] = informationID;
    [self addHashParam];
}

- (void)setInformationLike:(NSString *)informationID inType:(NSString *) type{
    [self addUserIDAndSessionParams];
    (self.params)[@"M"] = [type stringByAppendingString:@".Like"];
    (self.params)[@"Id"] = informationID;
    [self addHashParam];
}

- (void)setInformationUnLike:(NSString *)informationID inType:(NSString *) type{
    [self addUserIDAndSessionParams];
    (self.params)[@"M"] = [type stringByAppendingString:@".UnLike"];
    (self.params)[@"Id"] = informationID;
    [self addHashParam];
}

#pragma Vision API

- (void)getNewVersion {
    (self.params)[@"M"] = @"System.Version";
    [self addHashParam];
}

#pragma Star API

- (void)getLatestStar {
    (self.params)[@"M"] = @"Person.GetLatest";
    [self addHashParam];
}

- (void)getAllStarsWithNextPage:(int)nextPage {
    (self.params)[@"M"] = @"People.Get";
    (self.params)[@"P"] = [NSString stringWithFormat:@"%d",nextPage];
    [self addHashParam];
}

- (void)readStar:(NSString *)starID {
    (self.params)[@"M"] = @"Person.Read";
    (self.params)[@"Id"] = [NSString stringWithFormat:@"%@",starID];
    [self addHashParam];
}

- (void)setStarFavored:(NSString *)starID {
    [self addUserIDAndSessionParams];
    (self.params)[@"M"] = @"Person.Favorite";
    (self.params)[@"Id"] = [NSString stringWithFormat:@"%@",starID];
    [self addHashParam];
}

- (void)cancelStarFaved:(NSString *)starID {
    [self addUserIDAndSessionParams];
    (self.params)[@"M"] = @"Person.UnFavorite";
    (self.params)[@"Id"] = [NSString stringWithFormat:@"%@",starID];
    [self addHashParam];
}

- (void)likeStar:(NSString *)starID {
    [self addUserIDAndSessionParams];
    (self.params)[@"M"] = @"Person.Like";
    (self.params)[@"Id"] = [NSString stringWithFormat:@"%@",starID];
    [self addHashParam];
}

- (void)unlikeStar:(NSString *)starID {
    [self addUserIDAndSessionParams];
    (self.params)[@"M"] = @"Person.UnLike";
    (self.params)[@"Id"] = [NSString stringWithFormat:@"%@",starID];
    [self addHashParam];
}

#pragma Search API

- (void)search:(NSString *)command {
    [self addUserIDAndSessionParams];
    (self.params)[@"M"] = @"User.Find";
    // TODO: 现在只支持根据学号和姓名检索
    NSArray *parseredArray = [command componentsSeparatedByString:@" "];
    if (parseredArray.count >= 2) {
        (self.params)[@"NO"] = parseredArray[0];
        (self.params)[@"Name"] = parseredArray[1];
    }
    
    [self addHashParam];
}

#pragma Friend API 

- (void)inviteFriend:(NSString *)userID {
    [self addUserIDAndSessionParams];
    (self.params)[@"M"] = @"Friend.Invite";
    if (userID)
        (self.params)[@"Id"] = userID;
    [self addHashParam];
}

- (void)removeFriend:(NSString *)userID {
    [self addUserIDAndSessionParams];
    (self.params)[@"M"] = @"Friend.Remove";
    if (userID)
        (self.params)[@"Id"] = userID;
    [self addHashParam];
}

- (void)getFriendsList {
    [self addUserIDAndSessionParams];
    (self.params)[@"M"] = @"Friends.Get";
    [self addHashParam];
}

- (void)acceptFriendInvitation:(NSString *)invitationID {
    [self addUserIDAndSessionParams];
    (self.params)[@"M"] = @"Friend.Invite.Accept";
    if (invitationID)
        (self.params)[@"Id"] = invitationID;
    [self addHashParam];
}

- (void)ignoreFriendInvitation:(NSString *)invitationID {
    [self addUserIDAndSessionParams];
    (self.params)[@"M"] = @"Friend.Invite.Reject";
    if (invitationID)
        (self.params)[@"Id"] = invitationID;
    [self addHashParam];
}

#pragma Notification API

- (void)getNotificationList {
    [self addUserIDAndSessionParams];
    // TODO:
    (self.params)[@"M"] = @"Friend.Invites.Get";
    [self addHashParam];
}

@end
