//
//  WTClient.m
//  WeTongjiSDK
//
//  Created by tang zhixiong on 12-11-7.
//  Copyright (c) 2012年 WeTongji. All rights reserved.
//

#import "WTClient.h"
#import "AFJSONRequestOperation.h"
#import "NSString+URLEncoding.h"
#import "NSString+Addition.h"
#import "JSON.h"

#define HttpMethodGET           @"GET"
#define HttpMethodPOST          @"POST"
#define HttpMethodUpLoadAvatar  @"UPLOAD_AVATAR"

@interface WTRequest()

@property (nonatomic, copy) WTSuccessCompletionBlock successCompletionBlock;
@property (nonatomic, copy) WTFailureCompletionBlock failureCompletionBlock;
@property (nonatomic, copy) NSString *HTTPMethod;

@property (nonatomic, strong) NSMutableDictionary *params;
@property (nonatomic, strong) NSMutableDictionary *postValue;
@property (nonatomic, strong) UIImage *avatarImage;

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
        NSString *name = [sortedNames objectAtIndex:i];
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
        NSString *name = [sortedNames objectAtIndex:i];
        NSString *parameter = self.params[name];
        [result appendString:[NSString stringWithFormat:@"%@=%@", [name URLEncodedString],
                              [parameter URLEncodedString]]];
    }
    NSString *md5 = [result md5HexDigest];
    self.params[@"H"] = md5;
}

#pragma mark - Configure API parameters

#pragma mark User API

- (void)login:(NSString *)num password:(NSString *)password {
    self.params[@"M"] = @"User.LogOn";
    self.params[@"NO"] = num;
    self.params[@"Password"] = password;
    [self addHashParam];
}

- (void)logoff {
    self.params[@"M"] = @"User.LogOff";
    [self addHashParam];
}

- (void)activeUserWithNo:(NSString *)studentNumber
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
    [self.params setObject:@"User.Update" forKey:@"M"];
    [self.params setObject:[NSUserDefaults getCurrentUserID] forKey:@"U"];
    [self.params setObject:[NSUserDefaults getCurrentUserSession] forKey:@"S"];
    
    NSMutableDictionary *itemDict = [[NSMutableDictionary alloc] init];
    if (displayName != nil) [itemDict setObject:displayName forKey:@"DisplayName"];
    if (email != nil) [itemDict setObject:email forKey:@"Email"];
    if (weibo != nil) [itemDict setObject:weibo forKey:@"SinaWeibo"];
    if (phone != nil) [itemDict setObject:phone forKey:@"Phone"];
    if (qq != nil) [itemDict setObject:qq forKey:@"QQ"];
    NSDictionary *userDict = [NSDictionary dictionaryWithObject:itemDict forKey:@"User"];
    NSString *userJSONStr = [userDict JSONRepresentation];
    
    [self addHashParam];
    [self.postValue setObject:userJSONStr forKey:@"User"];
    self.HTTPMethod = HttpMethodPOST;
}

- (void)updatePassword:(NSString *)new oldPassword:(NSString *)old {
    [self.params setObject:@"User.Update.Password" forKey:@"M"];
    [self.params setObject:[NSUserDefaults getCurrentUserID] forKey:@"U"];
    [self.params setObject:[NSUserDefaults getCurrentUserSession] forKey:@"S"];
    [self.params setObject:new forKey:@"New"];
    [self.params setObject:old forKey:@"Old"];
    [self addHashParam];
}

- (void)updateUserAvatar:(UIImage *)image {
    [self.params setObject:@"User.Update.Avatar" forKey:@"M"];
    [self.params setObject:[NSUserDefaults getCurrentUserID] forKey:@"U"];
    [self.params setObject:[NSUserDefaults getCurrentUserSession] forKey:@"S"];
    self.avatarImage = image;
    self.HTTPMethod = HttpMethodUpLoadAvatar;
    [self addHashParam];
}

- (void)getUserInformation {
    [self.params setObject:@"User.Get" forKey:@"M"];
    [self.params setObject:[NSUserDefaults getCurrentUserID] forKey:@"U"];
    [self.params setObject:[NSUserDefaults getCurrentUserSession] forKey:@"S"];
    [self addHashParam];
}

- (void)resetPasswordWithNO:(NSString *)studentNumber
                       Name:(NSString*)name {
    [self.params setObject:@"User.Reset.Password" forKey:@"M"];
    [self.params setObject:studentNumber forKey:@"NO"];
    [self.params setObject:name forKey:@"Name"];
    [self addHashParam];
}

#pragma mark Course API

- (void)getCourses {
    [self.params setObject:@"TimeTable.Get" forKey:@"M"];
    [self.params setObject:[NSUserDefaults getCurrentUserID] forKey:@"U"];
    [self.params setObject:[NSUserDefaults getCurrentUserSession] forKey:@"S"];
    [self addHashParam];
}

#pragma mark Calender API

- (void)getScheduleWithBeginDate:(NSDate *)begin endDate:(NSDate *)end {
    [self.params setObject:@"Schedule.Get" forKey:@"M"];
    [self.params setObject:[NSUserDefaults getCurrentUserID] forKey:@"U"];
    [self.params setObject:[NSUserDefaults getCurrentUserSession] forKey:@"S"];
    [self.params setObject:[NSString standardDateStringCovertFromDate:begin] forKey:@"Begin"];
    [self.params setObject:[NSString standardDateStringCovertFromDate:end] forKey:@"End"];
    [self addHashParam];
}

#pragma mark Channel API

- (void)setChannelFavored:(NSString *)channelID {
    [self.params setObject:[NSUserDefaults getCurrentUserID] forKey:@"U"];
    [self.params setObject:[NSUserDefaults getCurrentUserSession] forKey:@"S"];
    [self.params setObject:@"Channel.Favorite" forKey:@"M"];
    [self.params setObject:channelID forKey:@"Id"];
    [self addHashParam];
}

- (void)cancelChannelFavored:(NSString *)channelID {
    [self.params setObject:[NSUserDefaults getCurrentUserID] forKey:@"U"];
    [self.params setObject:[NSUserDefaults getCurrentUserSession] forKey:@"S"];
    [self.params setObject:@"Channel.UnFavorite" forKey:@"M"];
    [self.params setObject:channelID forKey:@"Id"];
    [self addHashParam];
}

- (void)getChannels {
    [self.params setObject:@"Channels.Get" forKey:@"M"];
    [self addHashParam];
}

#pragma mark Activity API

- (void)getActivitiesInChannel:(NSString *)channelID
                        inSort:(NSString *)sort
                       Expired:(BOOL)isExpired
                      nextPage:(int)nextPage {
    [self.params setObject:@"Activities.Get" forKey:@"M"];
    if (channelID) [self.params setObject:channelID forKey:@"Channel_Ids"];
    if (sort) [self.params setObject:sort forKey:@"Sort"];
    if (isExpired) [self.params setObject:[NSString stringWithFormat:@"%d", isExpired] forKey:@"Expire"];
    [self.params setObject:[NSString stringWithFormat:@"%d",nextPage] forKey:@"P"];
    [self addHashParam];
}

- (void)setLikeActivitiy:(NSString *)activityID {
    [self.params setObject:[NSUserDefaults getCurrentUserID] forKey:@"U"];
    [self.params setObject:[NSUserDefaults getCurrentUserSession] forKey:@"S"];
    [self.params setObject:@"Activity.Like" forKey:@"M"];
    [self.params setObject:activityID forKey:@"Id"];
    [self addHashParam];
}

- (void)cancelLikeActivity:(NSString *)activityID {
    [self.params setObject:[NSUserDefaults getCurrentUserID] forKey:@"U"];
    [self.params setObject:[NSUserDefaults getCurrentUserSession] forKey:@"S"];
    [self.params setObject:@"Activity.UnLike" forKey:@"M"];
    [self.params setObject:activityID forKey:@"Id"];
    [self addHashParam];
}

- (void)setActivityFavored:(NSString *)activityID {
    [self.params setObject:[NSUserDefaults getCurrentUserID] forKey:@"U"];
    [self.params setObject:[NSUserDefaults getCurrentUserSession] forKey:@"S"];
    [self.params setObject:@"Activity.Favorite" forKey:@"M"];
    [self.params setObject:activityID forKey:@"Id"];
    [self addHashParam];
}

- (void)cancelActivityFavored:(NSString *)activityID {
    [self.params setObject:[NSUserDefaults getCurrentUserID] forKey:@"U"];
    [self.params setObject:[NSUserDefaults getCurrentUserSession] forKey:@"S"];
    [self.params setObject:@"Activity.UnFavorite" forKey:@"M"];
    [self.params setObject:activityID forKey:@"Id"];
    [self addHashParam];
}

- (void)setActivityScheduled:(NSString *)activityID
{
    [self.params setObject:[NSUserDefaults getCurrentUserID] forKey:@"U"];
    [self.params setObject:[NSUserDefaults getCurrentUserSession] forKey:@"S"];
    [self.params setObject:@"Activity.Schedule" forKey:@"M"];
    [self.params setObject:activityID forKey:@"Id"];
    [self addHashParam];
}

- (void)cancelActivityScheduled:(NSString *)activityID
{
    [self.params setObject:[NSUserDefaults getCurrentUserID] forKey:@"U"];
    [self.params setObject:[NSUserDefaults getCurrentUserSession] forKey:@"S"];
    [self.params setObject:@"Activity.UnSchedule" forKey:@"M"];
    [self.params setObject:activityID forKey:@"Id"];
    [self addHashParam];
}

#pragma Favorite API

- (void)getFavoritesWithNextPage:(int)nextPage {
    [self.params setObject:[NSUserDefaults getCurrentUserID] forKey:@"U"];
    [self.params setObject:[NSUserDefaults getCurrentUserSession] forKey:@"S"];
    [self.params setObject:@"Favorite.Get" forKey:@"M"];
    [self.params setObject:[NSString stringWithFormat:@"%d",nextPage] forKey:@"P"];
    [self addHashParam];
}

#pragma Information API

- (void)getAllInformationInType:(NSString *) type sort:(NSString *)sort
                       nextPage:(int)nextPage {
    NSString * resultM;
    if ( [type isEqualToString:GetInformationTypeClubNews] || [type isEqualToString:GetInformationTypeSchoolNews] ){
        resultM = [type stringByAppendingString:@".GetList"];
    }
    if ( [type isEqualToString:GetInformationTypeAround] || [type isEqualToString:GetInformationTypeForStaff] ) {
        resultM = [type stringByAppendingString:@"s.Get"];
    }
    [self.params setObject:resultM forKey:@"M"];
    if (sort) [self.params setObject:sort forKey:@"Sort"];
    [self.params setObject:[NSString stringWithFormat:@"%d",nextPage] forKey:@"P"];
    [self addHashParam];
}

- (void)getDetailOfInformaion:(NSString *)informationID inType:(NSString *)type {
    [self.params setObject:[type stringByAppendingString:@".Get"] forKey:@"M"];
    [self.params setObject:informationID forKey:@"Id"];
    [self addHashParam];
}

- (void)readInformaion:(NSString *)informationID inType:(NSString *) type {
    [self.params setObject:[type stringByAppendingString:@".Read"]  forKey:@"M"];
    [self.params setObject:informationID forKey:@"Id"];
    [self addHashParam];
}

- (void)setInformationFavored:(NSString *)informationID inType:(NSString *) type{
    [self.params setObject:[NSUserDefaults getCurrentUserID] forKey:@"U"];
    [self.params setObject:[NSUserDefaults getCurrentUserSession] forKey:@"S"];
    [self.params setObject:[type stringByAppendingString:@".Favorite"]  forKey:@"M"];
    [self.params setObject:informationID forKey:@"Id"];
    [self addHashParam];
}

- (void)setInformationUnFavored:(NSString *)informationID inType:(NSString *) type{
    [self.params setObject:[NSUserDefaults getCurrentUserID] forKey:@"U"];
    [self.params setObject:[NSUserDefaults getCurrentUserSession] forKey:@"S"];
    [self.params setObject:[type stringByAppendingString:@".UnFavorite"]  forKey:@"M"];
    [self.params setObject:informationID forKey:@"Id"];
    [self addHashParam];
}

- (void)setInformationLike:(NSString *)informationID inType:(NSString *) type{
    [self.params setObject:[NSUserDefaults getCurrentUserID] forKey:@"U"];
    [self.params setObject:[NSUserDefaults getCurrentUserSession] forKey:@"S"];
    [self.params setObject:[type stringByAppendingString:@".Like"]  forKey:@"M"];
    [self.params setObject:informationID forKey:@"Id"];
    [self addHashParam];
}

- (void)setInformationUnLike:(NSString *)informationID inType:(NSString *) type{
    [self.params setObject:[NSUserDefaults getCurrentUserID] forKey:@"U"];
    [self.params setObject:[NSUserDefaults getCurrentUserSession] forKey:@"S"];
    [self.params setObject:[type stringByAppendingString:@".UnLike"]  forKey:@"M"];
    [self.params setObject:informationID forKey:@"Id"];
    [self addHashParam];
}

#pragma Vision API

- (void)getNewVersion {
    [self.params setObject:@"System.Version" forKey:@"M"];
    [self addHashParam];
}

#pragma Star API

- (void)getLatestStar {
    [self.params setObject:@"Person.GetLatest" forKey:@"M"];
    [self addHashParam];
}

- (void)getAllStarsWithNextPage:(int)nextPage {
    [self.params setObject:@"People.Get" forKey:@"M"];
    [self.params setObject:[NSString stringWithFormat:@"%d",nextPage] forKey:@"P"];
    [self addHashParam];
}

- (void)readStar:(NSString *)starID {
    [self.params setObject:@"Person.Read" forKey:@"M"];
    [self.params setObject:[NSString stringWithFormat:@"%@",starID] forKey:@"Id"];
    [self addHashParam];
}

- (void)setStarFavored:(NSString *)starID {
    [self.params setObject:[NSUserDefaults getCurrentUserID] forKey:@"U"];
    [self.params setObject:[NSUserDefaults getCurrentUserSession] forKey:@"S"];
    [self.params setObject:@"Person.Favorite" forKey:@"M"];
    [self.params setObject:[NSString stringWithFormat:@"%@",starID] forKey:@"Id"];
    [self addHashParam];
}

- (void)cancelStarFaved:(NSString *)starID {
    [self.params setObject:[NSUserDefaults getCurrentUserID] forKey:@"U"];
    [self.params setObject:[NSUserDefaults getCurrentUserSession] forKey:@"S"];
    [self.params setObject:@"Person.UnFavorite" forKey:@"M"];
    [self.params setObject:[NSString stringWithFormat:@"%@",starID] forKey:@"Id"];
    [self addHashParam];
}

- (void)likeStar:(NSString *)starID {
    [self.params setObject:[NSUserDefaults getCurrentUserID] forKey:@"U"];
    [self.params setObject:[NSUserDefaults getCurrentUserSession] forKey:@"S"];
    [self.params setObject:@"Person.Like" forKey:@"M"];
    [self.params setObject:[NSString stringWithFormat:@"%@",starID] forKey:@"Id"];
    [self addHashParam];
}

- (void)unlikeStar:(NSString *)starID {
    [self.params setObject:[NSUserDefaults getCurrentUserID] forKey:@"U"];
    [self.params setObject:[NSUserDefaults getCurrentUserSession] forKey:@"S"];
    [self.params setObject:@"Person.UnLike" forKey:@"M"];
    [self.params setObject:[NSString stringWithFormat:@"%@",starID] forKey:@"Id"];
    [self addHashParam];
}

@end

@interface WTClient() <UIWebViewDelegate>

@end

#define BASE_URL_STRING @"http://we.tongji.edu.cn"
#define PATH_STRING     @"/api/call"

@implementation WTClient

#pragma mark - Constructors

+ (WTClient *)sharedClient
{
    static WTClient *client = nil;
    static dispatch_once_t WTClientPredicate;
    dispatch_once(&WTClientPredicate, ^{
        client = [[WTClient alloc] initWithBaseURL:[NSURL URLWithString:BASE_URL_STRING]];
        client.parameterEncoding = AFFormURLParameterEncoding;
    });
    
    return client;
}

- (id)initWithBaseURL:(NSURL *)url
{
    self = [super initWithBaseURL:url];
    if (!self)
    {
        return nil;
    }
    
    [self registerHTTPOperationClass:[AFJSONRequestOperation class]];
    
	[self setDefaultHeader:@"Accept" value:@"application/json"];
    
    return self;
}

#pragma mark - Public methods

- (void)enqueueRequest:(WTRequest *)request {
    AFHTTPRequestOperation *operation = [self generateRequestOperation:request];
    [self enqueueHTTPRequestOperation:operation];
}

#pragma mark - Logic methods

- (AFHTTPRequestOperation *)generateRequestOperation:(WTRequest *)rawRequest {
    NSMutableURLRequest *urlRequest;
    NSString *HTTPMethod = rawRequest.HTTPMethod;
    NSDictionary *params = rawRequest.params;
    if([HTTPMethod isEqualToString:HttpMethodGET]) {
        urlRequest = [self requestWithMethod:HTTPMethod
                                     path:PATH_STRING
                               parameters:params];
    } else if([HTTPMethod isEqualToString:HttpMethodPOST]) {
        NSString *queryString= rawRequest.queryString;
        NSDictionary *postValue = rawRequest.postValue;
        urlRequest= [self requestWithMethod:HTTPMethod
                                    path:[NSString stringWithFormat:@"%@?%@", PATH_STRING, queryString]
                              parameters:postValue];
    } else if([HTTPMethod isEqualToString:HttpMethodUpLoadAvatar]) {
        NSData *imageData = UIImageJPEGRepresentation(rawRequest.avatarImage, 1.0);
        NSString *queryString= rawRequest.queryString;
        urlRequest = [self multipartFormRequestWithMethod:HttpMethodPOST
                                                  path:[NSString stringWithFormat:@"%@?%@", PATH_STRING, queryString]
                                            parameters:nil
                             constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
                                 [formData appendPartWithFileData:imageData
                                                             name:@"Image"
                                                         fileName:@"avatar.jpg"
                                                         mimeType:@"image/jpeg"];
                             }];
    }
    [urlRequest setTimeoutInterval:10];
    NSLog(@"%@", urlRequest);
    NSLog(@"%@", [[NSString alloc] initWithData:[urlRequest HTTPBody] encoding:self.stringEncoding]);
    AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:urlRequest success:^(AFHTTPRequestOperation *operation, id resposeObject) {
        NSDictionary *status = resposeObject[@"Status"];
        NSString *statusIDString = status[@"Id"];
        NSInteger statusID = statusIDString.integerValue;
        NSDictionary *result = resposeObject[@"Data"];
        
        if(result && statusID == 0) {
            if(rawRequest.successCompletionBlock) {
                rawRequest.successCompletionBlock(result);
            }
        } else {
            NSString *errorDesc = [NSString stringWithFormat:@"%@", status[@"Memo"]];
            NSError *error = [NSError errorWithDomain:[NSBundle mainBundle].bundleIdentifier
                                                 code:statusID
                                             userInfo:@{@"errorDesc" : errorDesc}];

            NSLog(@"Server responsed error code:%d\n\
                  desc: %@\n", statusID, errorDesc);
            
            if(rawRequest.failureCompletionBlock) {
                rawRequest.failureCompletionBlock(error);
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if(rawRequest.failureCompletionBlock) {
            rawRequest.failureCompletionBlock(error);
        }
    }];
    return operation;
}

@end
