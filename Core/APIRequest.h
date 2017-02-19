//
//  APIRequest.h
//  APIEngine
//
//  Created by Георгий Малюков on 10.02.17.
//  Copyright © 2017 Georgiy Malyukov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "APIResponse.h"

FOUNDATION_EXPORT NSString *const GET;
FOUNDATION_EXPORT NSString *const POST;
FOUNDATION_EXPORT NSString *const PUT;
FOUNDATION_EXPORT NSString *const DELETE;

FOUNDATION_EXPORT NSString *const APIRequestGot401NotAuthorizedNotification;

@class APIRequest;

typedef void(^APIRequestCallback)(APIResponse *response, NSError *error);
typedef void(^APIRequestProgressBlock)(float progress);

typedef NS_ENUM(NSInteger, APISerializerType) {
    APISerializerTypeHTTP,
    APISerializerTypeJSON
};


@interface APIRequest : NSObject {
    
}

@property (readonly, nonatomic) NSURL               *url;
@property (readonly, nonatomic) APISerializerType   requestSerializerType;
@property (readonly, nonatomic) Class               responseClass;
@property (readonly, nonatomic) NSDictionary        *responseHeaders;
@property (readonly, nonatomic) APISerializerType   responseSerializerType;
@property (copy, nonatomic)     APIRequestCallback  callback;

@property (readonly, nonatomic, getter=isCompleted) BOOL completed;


#pragma mark - Root

+ (instancetype)requestWithCallback:(APIRequestCallback)callback;
+ (instancetype)requestWithCallback:(APIRequestCallback)callback progress:(APIRequestProgressBlock)progress;


#pragma mark - Configuration

+ (NSString *)serviceRootURL;
+ (NSDictionary *)customRequestHeaders;


#pragma mark - Usage

- (void)performRequestWithPath:(NSString *)path
                 responseClass:(Class)responseClass
                    parameters:(NSDictionary *)parameters
                        method:(NSString *)httpMethod;
- (void)performRequest:(NSMutableURLRequest *)request responseClass:(Class)responseClass;
- (void)cancel;

@end
