//
//  WTClient.h
//  WeTongjiSDK
//
//  Created by tang zhixiong on 12-11-7.
//  Copyright (c) 2012年 WeTongji. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "AFHTTPClient.h"

@class WTRequest;

@interface WTClient : AFHTTPClient

+ (WTClient *)sharedClient;

- (void)enqueueRequest:(WTRequest *)request;

@end
