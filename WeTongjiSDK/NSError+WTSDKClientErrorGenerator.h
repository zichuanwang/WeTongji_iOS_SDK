//
//  NSError+WTSDKClientErrorGenerator.h
//  WeTongjiSDK
//
//  Created by 王 紫川 on 13-3-7.
//  Copyright (c) 2013年 WeTongji. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSError (WTSDKClientErrorGenerator)

typedef enum {
    ErrorCodeNeedUserLogin = 10000,
} WTSDKClientErrorCode;

+ (NSError *)createErrorWithErrorCode:(WTSDKClientErrorCode)errorCode;

@end
