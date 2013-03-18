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
#import <Security/Security.h>
#import "Base64.h"

#define DEVICE_IDENTIFIER   @"iOS"
#define API_VERSION         @"2.0"

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
        _params[@"D"] = DEVICE_IDENTIFIER;
        //NSString *version = [NSBundle mainBundle].infoDictionary[@"CFBundleShortVersionString"];
        _params[@"V"] = API_VERSION;
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

- (SecKeyRef)getPublicKeyRef {
    NSString *keyPath = [[NSBundle mainBundle] pathForResource:@"public_key" ofType:@"der"];
    NSData *keyData = [[NSData alloc] initWithContentsOfFile:keyPath];
    SecCertificateRef myCertificate = SecCertificateCreateWithData(kCFAllocatorDefault, (__bridge CFDataRef)keyData);
    SecPolicyRef myPolicy = SecPolicyCreateBasicX509();
    SecTrustRef myTrust;
    OSStatus status = SecTrustCreateWithCertificates(myCertificate, myPolicy, &myTrust);
    SecTrustResultType trustResult;
    if (status == noErr) {
        status = SecTrustEvaluate(myTrust, &trustResult);
    }
    SecKeyRef result = SecTrustCopyPublicKey(myTrust);
    
    CFRelease(myPolicy);
    CFRelease(myTrust);
    
    return result;
}

- (NSString *)RSAEncryptText:(NSString *)plainText {
    
    SecKeyRef key = [self getPublicKeyRef];
    
    size_t cipherBufferSize = SecKeyGetBlockSize(key);
    uint8_t *cipherBuffer = malloc(cipherBufferSize * sizeof(uint8_t));
    memset((void *)cipherBuffer, 0 * 0, cipherBufferSize);
    
    NSData *plainTextBytes = [plainText dataUsingEncoding:NSUTF8StringEncoding];
    size_t blockSize = cipherBufferSize;
    size_t blockCount = (size_t)ceil([plainTextBytes length] / (double)blockSize);
    NSMutableData *encryptedData = [NSMutableData dataWithCapacity:0];
    
    for (int i = 0; i < blockCount; i++) {
        
        int bufferSize = MIN(blockSize, [plainTextBytes length] - i * blockSize);
        NSData *buffer = [plainTextBytes subdataWithRange:NSMakeRange(i * blockSize, bufferSize)];
        
        OSStatus status = SecKeyEncrypt(key,
                                        kSecPaddingPKCS1,
                                        (const uint8_t *)[buffer bytes],
                                        [buffer length],
                                        cipherBuffer,
                                        &cipherBufferSize);
        
        if (status == noErr) {
            NSData *encryptedBytes = [NSData dataWithBytes:(const void *)cipherBuffer length:cipherBufferSize];
            [encryptedData appendData:encryptedBytes];
            
        } else {
            
            if (cipherBuffer) {
                free(cipherBuffer);
            }
            return nil;
        }
    }
    if (cipherBuffer)
        free(cipherBuffer);
        
    NSString *encryptResult = [NSString stringWithFormat:@"%@", [encryptedData base64EncodedString]];
    
    CFRelease(key);
    
    return encryptResult;
}

#pragma mark - Configure API parameters
#pragma mark User API

- (void)login:(NSString *)num password:(NSString *)password {
    self.params[@"M"] = @"User.LogOn";
    self.params[@"NO"] = num;
    if ([API_VERSION isEqualToString:@"1.0"])
        self.params[@"Password"] = password;
    else if ([API_VERSION isEqualToString:@"2.0"]) {
        self.params[@"Password"] = [self RSAEncryptText:password];
    }
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

+ (NSString *)generateActivityShowTypesParam:(NSArray *)showTypesArray {
    if (!showTypesArray)
        return [NSString stringWithFormat:@"1,2,3,4"];
    
    NSMutableString *showTypesString = [NSMutableString string];
    for (int i = 0; i < showTypesArray.count; i++) {
        NSNumber *showTypeNumber = showTypesArray[i];
        if (showTypeNumber.boolValue) {
            [showTypesString appendFormat:@"%@%d", (i == 0 ? @"" : @","), i + 1];
        }
    }
    return showTypesString;
}

#define GetActivitySortMethodLikeAsc        @"`like`"
#define GetActivitySortMethodBeginAsc       @"`begin`"
#define GetActivitySortMethodPublishAsc     @"`created_at`"
#define GetActivitySortMethodLikeDesc       @"`like` DESC"
#define GetActivitySortMethodBeginDesc      @"`begin` DESC"
#define GetActivitySortMethodPublishDesc    @"`created_at` DESC"

typedef enum {
    ActivityOrderByPublishDate  = 1 << 0,
    ActivityOrderByPopularity   = 1 << 1,
    ActivityOrderByStartDate    = 1 << 2,
} ActivityOrderMethod;

+ (BOOL)shouldActivityOrderByDesc:(NSUInteger)orderMethod
                     smartOrder:(BOOL)smartOrder
                     showExpire:(BOOL)showExpire {
    BOOL result = NO;
    switch (orderMethod) {
        case ActivityOrderByPublishDate:
        {
            result = smartOrder;
        }
            break;
        case ActivityOrderByPopularity:
        {
            result = smartOrder;
        }
            break;
        case ActivityOrderByStartDate:
        {
            result = (showExpire && smartOrder) || (!showExpire && !smartOrder);
        }
            break;
        default:
            break;
    }
    return result;
}

+ (NSString *)generateActivityOrderMethodParam:(NSUInteger)orderMethod
                                    smartOrder:(BOOL)smartOrder
                                    showExpire:(BOOL)showExpire {
    NSString *result = nil;
    BOOL shouldOrderByDesc = [WTRequest shouldActivityOrderByDesc:orderMethod
                                                       smartOrder:smartOrder
                                                       showExpire:showExpire];
    switch (orderMethod) {
        case ActivityOrderByPublishDate:
        {
            result = shouldOrderByDesc ? GetActivitySortMethodPublishDesc : GetActivitySortMethodPublishAsc;
        }
            break;
        case ActivityOrderByPopularity:
        {
            result = shouldOrderByDesc ? GetActivitySortMethodLikeDesc : GetActivitySortMethodLikeAsc;
        }
            break;
        case ActivityOrderByStartDate:
        {
            result = shouldOrderByDesc ? GetActivitySortMethodBeginDesc : GetActivitySortMethodBeginAsc;
        }
            break;
        default:
            break;
    }
    return result;
}

- (void)getActivitiesInTypes:(NSArray *)showTypesArray
                 orderMethod:(NSUInteger)orderMethod
                  smartOrder:(BOOL)smartOrder
                  showExpire:(BOOL)showExpire
                        page:(NSUInteger)page {
    
    if([NSUserDefaults getCurrentUserID] && [NSUserDefaults getCurrentUserSession]) {
        [self addUserIDAndSessionParams];
    }
    
    (self.params)[@"M"] = @"Activities.Get";

    self.params[@"Channel_Ids"] = [WTRequest generateActivityShowTypesParam:showTypesArray];
    
    self.params[@"Sort"] = [WTRequest generateActivityOrderMethodParam:orderMethod
                                                           smartOrder:smartOrder
                                                           showExpire:showExpire];
    
    self.params[@"Expire"] = [NSString stringWithFormat:@"%d", showExpire];
    
    self.params[@"P"] = [NSString stringWithFormat:@"%d", page];
    
    [self addHashParam];
}

- (void)setActivitiyLiked:(BOOL)liked activityID:(NSString *)activityID {
    [self addUserIDAndSessionParams];
    (self.params)[@"M"] = liked ? @"Activity.Like" : @"Activity.UnLike";
    (self.params)[@"Id"] = activityID;
    [self addHashParam];
}

- (void)setActivityFavored:(BOOL)favored activityID:(NSString *)activityID {
    [self addUserIDAndSessionParams];
    (self.params)[@"M"] = favored ? @"Activity.Favorite" : @"Activity.UnFavorite";
    (self.params)[@"Id"] = activityID;
    [self addHashParam];
}

- (void)setActivityScheduled:(BOOL)scheduled activityID:(NSString *)activityID {
    [self addUserIDAndSessionParams];
    (self.params)[@"M"] = scheduled ? @"Activity.Schedule" : @"Activity.UnSchedule";
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

- (void)getNewsInTypes:(NSArray *)showTypesArray
            sortMethod:(NSString *)sortMethod
                  page:(NSUInteger)page {
    self.params[@"M"] = @"SchoolNews.GetList";
    if (sortMethod)
        self.params[@"Sort"] = sortMethod;
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
        (self.params)[@"UID"] = userID;
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
