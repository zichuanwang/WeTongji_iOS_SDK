//
//  WTElectricityBalanceQueryService.m
//  WeTongjiSDK
//
//  Created by 王 紫川 on 12-11-30.
//  Copyright (c) 2012年 WeTongji. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WTElectricityBalanceQueryService.h"
#import "TFHpple.h"

#define BASE_URL_STRING @"http://nyglzx.tongji.edu.cn/web/datastat.aspx"

#define kDistrictIndexArray @"DistrictIndexArray"

#define DistrictBuildingIndexInvalid (-1)

typedef enum {
    WTElectricityBalanceQueryProcessStateLoading,
    WTElectricityBalanceQueryProcessStateSelectingDistrict,
    WTElectricityBalanceQueryProcessStateQuerying,
} WTElectricityBalanceQueryProcessState;

@interface WTElectricityBalanceQueryService() <UIWebViewDelegate>

@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) NSDictionary *districtBuildingMap;
@property (nonatomic, assign) WTElectricityBalanceQueryProcessState processState;

@property (nonatomic, copy) WTSuccessCompletionBlock successCompletionBlock;
@property (nonatomic, copy) WTFailureCompletionBlock failureCompletionBlock;

@property (nonatomic, copy) NSString *district;
@property (nonatomic, copy) NSString *building;
@property (nonatomic, copy) NSString *room;

@property (nonatomic, assign) NSUInteger districtIndex;
@property (nonatomic, assign) NSUInteger buildingIndex;

@property (nonatomic, assign) BOOL isBusy;

@end

@implementation WTElectricityBalanceQueryService

#pragma mark - Life cycle

+ (WTElectricityBalanceQueryService *)sharedService
{
    static WTElectricityBalanceQueryService *instance = nil;
    static dispatch_once_t WTElectricityBalanceQueryServicePredicate;
    dispatch_once(&WTElectricityBalanceQueryServicePredicate, ^{
        instance = [[WTElectricityBalanceQueryService alloc] init];
    });
    return instance;
}

- (id)init {
    self = [super init];
    if(self) {
        [self loadDistrictBuildingMap];
        
        self.webView = [[UIWebView alloc] init];
        self.webView.delegate = self;
        
        self.districtIndex = DistrictBuildingIndexInvalid;
        self.buildingIndex = DistrictBuildingIndexInvalid;
    }
    return self;
}

#pragma mark - Logic methods

- (void)loadDistrictBuildingMap {
    NSString *configFilePath = [[NSBundle mainBundle] pathForResource:@"WTDistrictBuildingMap" ofType:@"plist"];
    self.districtBuildingMap = [[NSDictionary alloc] initWithContentsOfFile:configFilePath];
}

- (void)configDistrictBuildingIndex {
    NSArray *districtIndexArray = self.districtBuildingMap[kDistrictIndexArray];
    [districtIndexArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if([self.district isEqualToString:obj]) {
            self.districtIndex = idx;
            *stop = YES;
        }
    }];
    self.districtIndex += 1;
    
    NSArray *buildingIndexArray = self.districtBuildingMap[self.district];
    [buildingIndexArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if([self.building isEqualToString:obj]) {
            self.buildingIndex = idx;
            *stop = YES;
        }
    }];
}

- (NSString *)parserBalanceWithHTMLData:(NSData *)HTMLData {
    NSDateFormatter *form = [[NSDateFormatter alloc] init];
    [form setDateFormat:@"yyyy-MM-dd"];
    NSString *todayDateString = [form stringFromDate:[[NSDate date] dateByAddingTimeInterval:-60 * 60 * 24]];
    
    TFHpple *xpathParser = [[TFHpple alloc] initWithHTMLData:HTMLData];
    NSArray *elements = [xpathParser searchWithXPathQuery:@"//td"];
    
    __block NSUInteger todayElementIndex = -1;
    [elements enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        TFHppleElement *element = obj;
        if([todayDateString isEqualToString:element.text]) {
            todayElementIndex = idx;
            *stop = YES;
        }
    }];
    
    if(todayElementIndex == -1)
        return nil;
    
    NSUInteger resultElementIndex = todayElementIndex + 3;
    if(elements.count > resultElementIndex) {
        TFHppleElement *resultElement = elements[resultElementIndex];
        NSString *result = [NSString stringWithFormat:@"%@ kWh", resultElement.text];
        return result;
    }    
    return nil;
}


#pragma mark - Public methods

- (void)getElectricChargeBalanceWithDistrict:(NSString *)district
                                    building:(NSString *)building
                                        room:(NSString *)room
                                successBlock:(WTSuccessCompletionBlock)success
                                failureBlock:(WTFailureCompletionBlock)failure {
    if(self.isBusy)
        return;
    
    if(!(district && building && room))
        return;
    
    self.district = district;
    self.building = building;
    self.room = room;
    
    [self configDistrictBuildingIndex];
    
    if(self.districtIndex == DistrictBuildingIndexInvalid
       || self.buildingIndex == DistrictBuildingIndexInvalid
       || self.room.length == 0)
        return;
    
    self.successCompletionBlock = success;
    self.failureCompletionBlock = failure;
    
    NSURL *url =[[NSURL alloc] initWithString:BASE_URL_STRING];
    NSURLRequest *request =  [[NSURLRequest alloc] initWithURL:url];
    [self.webView loadRequest:request];
    
    self.isBusy = YES;
    self.processState = WTElectricityBalanceQueryProcessStateLoading;
}

#pragma mark - UIWebViewDelegate

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    switch (self.processState) {
        case WTElectricityBalanceQueryProcessStateLoading: {
            [self.webView stringByEvaluatingJavaScriptFromString:@"document.form1.DistrictDown.options[2].selected=true;"];
            [self.webView stringByEvaluatingJavaScriptFromString:@"document.form1.DistrictDown.onchange()"];
            self.processState = WTElectricityBalanceQueryProcessStateSelectingDistrict;
            break;
        }
        case WTElectricityBalanceQueryProcessStateSelectingDistrict: {
            [self.webView stringByEvaluatingJavaScriptFromString:@"document.form1.BuildingDown.options[10].selected=true;"];
            [self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.form1.RoomnameText.value=\"%@\"", self.room]];
            [webView stringByEvaluatingJavaScriptFromString:@"document.form1.Submit.click();"];
            self.processState = WTElectricityBalanceQueryProcessStateQuerying;
            break;
        }
        case WTElectricityBalanceQueryProcessStateQuerying: {
            if(self.successCompletionBlock) {
                NSString *HTMLString = [self.webView stringByEvaluatingJavaScriptFromString:@"document.documentElement.innerHTML"];
                NSString *UTF8String = [HTMLString stringByReplacingOccurrencesOfString:@"gb2312" withString:@"UTF-8"];
                NSLog(@"UTF8 string: %@", UTF8String);
                NSString *balance = [self parserBalanceWithHTMLData:[UTF8String dataUsingEncoding:NSUTF8StringEncoding]];
                if(balance == nil || balance.length == 0) {
                    if(self.failureCompletionBlock) {
                        NSError *error = [[NSError alloc] initWithDomain:@"WeTongji" code:-1 userInfo:nil];
                        self.failureCompletionBlock(error);
                    }
                } else {
                    if(self.successCompletionBlock) {
                        self.successCompletionBlock(balance);
                    }
                }
                self.isBusy = NO;
            }
            break;
        }
        default:
            break;
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    if(self.failureCompletionBlock) {
        self.failureCompletionBlock(error);
    }
    self.isBusy = NO;
}

@end
