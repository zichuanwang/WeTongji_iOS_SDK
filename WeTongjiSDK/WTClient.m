//
//  WTClient.m
//  WeTongjiSDK
//
//  Created by tang zhixiong on 12-11-7.
//  Copyright (c) 2012年 WeTongji. All rights reserved.
//

#import "WTClient.h"
#import "AFJSONRequestOperation.h"
#import "WTRequest.h"

@interface WTClient()

@end

#define BASE_URL_STRING @"http://leiz.name:8080"
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
    if (!request.isValid) {
        request.failureCompletionBlock(request.error);
    }
    AFHTTPRequestOperation *operation = [self generateRequestOperationWithRawRequest:request];
    [self enqueueHTTPRequestOperation:operation];
}

#pragma mark - Logic methods

- (NSMutableURLRequest *)generateURLRequestWithRawRequest:(WTRequest *)rawRequest {
    
    NSMutableURLRequest *URLRequest;
    NSString *HTTPMethod = rawRequest.HTTPMethod;
    NSDictionary *params = rawRequest.params;
    
    if([HTTPMethod isEqualToString:HttpMethodGET]) {
        
        URLRequest = [self requestWithMethod:HTTPMethod
                                        path:PATH_STRING
                                  parameters:params];
        
    } else if([HTTPMethod isEqualToString:HttpMethodPOST]) {
        
        NSString *queryString= rawRequest.queryString;
        NSDictionary *postValue = rawRequest.postValue;
        URLRequest= [self requestWithMethod:HTTPMethod
                                       path:[NSString stringWithFormat:@"%@?%@", PATH_STRING, queryString]
                                 parameters:postValue];
        
    } else if([HTTPMethod isEqualToString:HttpMethodUpLoadAvatar]) {
        
        NSData *imageData = UIImageJPEGRepresentation(rawRequest.avatarImage, 1.0);
        NSString *queryString= rawRequest.queryString;
        URLRequest = [self multipartFormRequestWithMethod:HttpMethodPOST
                                                     path:[NSString stringWithFormat:@"%@?%@", PATH_STRING, queryString]
                                               parameters:nil
                                constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
                                    [formData appendPartWithFileData:imageData
                                                                name:@"Image"
                                                            fileName:@"avatar.jpg"
                                                            mimeType:@"image/jpeg"];
                                }];
    }
    [URLRequest setTimeoutInterval:10];
    
    NSLog(@"%@", URLRequest);
    NSLog(@"%@", [[NSString alloc] initWithData:[URLRequest HTTPBody] encoding:self.stringEncoding]);
    
    return URLRequest;
}

- (AFHTTPRequestOperation *)generateRequestOperationWithURLRequest:(NSMutableURLRequest *)URLRequest rawRequest:(WTRequest *)rawRequest {
    AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:URLRequest success:^(AFHTTPRequestOperation *operation, id resposeObject) {
        NSDictionary *status = resposeObject[@"Status"];
        NSString *statusIDString = status[@"Id"];
        NSInteger statusID = statusIDString.integerValue;
        NSDictionary *result = resposeObject[@"Data"];
        
        if(result && statusID == 0) {
            if (rawRequest.preSuccessCompletionBlock) {
                rawRequest.preSuccessCompletionBlock(result);
            }
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

- (AFHTTPRequestOperation *)generateRequestOperationWithRawRequest:(WTRequest *)rawRequest {
    NSMutableURLRequest *URLRequest = [self generateURLRequestWithRawRequest:rawRequest];
    AFHTTPRequestOperation *operation = [self generateRequestOperationWithURLRequest:URLRequest rawRequest:rawRequest];
    return operation;
}

@end
