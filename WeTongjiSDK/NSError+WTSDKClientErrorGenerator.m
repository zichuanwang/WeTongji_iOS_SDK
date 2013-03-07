//
//  NSError+WTSDKClientErrorGenerator.m
//  WeTongjiSDK
//
//  Created by 王 紫川 on 13-3-7.
//  Copyright (c) 2013年 WeTongji. All rights reserved.
//

#import "NSError+WTSDKClientErrorGenerator.h"

@implementation NSError (WTSDKClientErrorGenerator)

+ (NSError *)createErrorWithErrorCode:(WTSDKClientErrorCode)errorCode {
    NSString *errorDesc = nil;
    switch (errorCode) {
        case ErrorCodeNeedUserLogin:
        {
            errorDesc = @"此功能需要用户登录后使用";
        }
            break;
            
        default:
            break;
    }
    NSError *error = [NSError errorWithDomain:[NSBundle mainBundle].bundleIdentifier
                                         code:errorCode
                                     userInfo:@{@"errorDesc" : errorDesc}];
    return error;
}

@end
