//
//  APIRequest.m
//  APIEngine
//
//  Created by Георгий Малюков on 10.02.17.
//  Copyright © 2017 Georgiy Malyukov. All rights reserved.
//

#import "APIRequest.h"
#import <AFNetworking/AFNetworking.h>
#import <JSONModel/JSONModel.h>

NSString *const GET = @"GET";
NSString *const POST = @"POST";
NSString *const PUT = @"PUT";
NSString *const DELETE = @"DELETE";

NSString *const APIRequestGot401NotAuthorizedNotification = @"APIRequestGot401NotAuthorizedNotification";


@interface APIRequest () {
    
}

@property (assign, nonatomic) Class                   responseClass;
@property (strong, nonatomic) NSDictionary            *responseHeaders;
@property (assign, nonatomic) BOOL                    completed;
@property (strong, nonatomic) NSMutableURLRequest     *request;
@property (strong, nonatomic) NSURLSessionDataTask    *dataTask;
@property (assign, nonatomic) float                   progress;
@property (copy, nonatomic)   APIRequestProgressBlock progressBlock;


#pragma mark - Utils

- (AFHTTPSessionManager*)sessionManager;
- (void)processResponse:(NSURLResponse *)response
         responseObject:(id)responseObject
                  error:(NSError *)error;
- (void)processError:(NSError *)error
             request:(NSURLRequest *)request
            response:(NSURLResponse *)response
      responseObject:(id)responseObject;

@end


@implementation APIRequest


#pragma mark - Root

+ (instancetype)requestWithCallback:(APIRequestCallback)callback {
    return [self requestWithCallback:callback progress:nil];
}

+ (instancetype)requestWithCallback:(APIRequestCallback)callback progress:(APIRequestProgressBlock)progress {
    APIRequest *req = [[self.class alloc] init];
    req.callback = callback;
    req.progressBlock = progress;
    
    return req;
}


#pragma mark - Configuration

+ (NSString *)serviceRootURL {
    NSAssert(0, @"Subclass APIRequest and override 'serviceRootURL' method to provide root service URL");
    return nil;
}

+ (NSDictionary *)customRequestHeaders {
    return @{};
}


#pragma mark - Usage

- (void)performRequestWithPath:(NSString *)path responseClass:(Class)responseClass parameters:(NSDictionary *)parameters method:(NSString *)httpMethod {
    self.responseClass = responseClass;
    
    if (![path hasPrefix:@"http"]) {
        path = [[self.class serviceRootURL] stringByAppendingString:path];
    }
    path = [path stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSLog(@"[REQUEST] %s: %@ %@, params: %@", __FUNCTION__, httpMethod, path, parameters);
    // init request
    NSError *error = nil;
    NSMutableURLRequest *request = [[self sessionManager].requestSerializer
                                    requestWithMethod:httpMethod
                                    URLString:path
                                    parameters:parameters
                                    error:&error];
    NSLog(@"[REQUEST] send %@, error = %@", request.URL.absoluteString, error.localizedDescription);
    // configure headers & perform request
    NSDictionary *customHeaders = [[self class] customRequestHeaders];
    
    for (NSString *key in customHeaders.allKeys) {
        [request setValue:customHeaders[key] forHTTPHeaderField:key];
    }
    [self performRequest:request responseClass:responseClass];
}

- (void)performRequest:(NSMutableURLRequest *)request responseClass:(Class)responseClass {
    self.request = request;
    // create task & resume it immediately
    self.dataTask = [[self sessionManager]
                     dataTaskWithRequest:request
                     uploadProgress:nil
                     downloadProgress:nil
                     completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
                         if (!error) {
                             [self processResponse:response
                                    responseObject:responseObject
                                             error:error];
                         }
                         else {
                             [self processError:error
                                        request:request
                                       response:response
                                 responseObject:responseObject];
                         }
                     }];
    [self.dataTask resume];
}

- (void)cancel {
    if (!self.isCompleted) {
        [self.dataTask cancel];
    }
}


#pragma mark - Properties

- (APISerializerType)requestSerializerType {
    return APISerializerTypeJSON; // JSON request is default
}

- (APISerializerType)responseSerializerType {
    return APISerializerTypeJSON; // JSON response is default
}


#pragma mark - Utils

- (AFHTTPSessionManager *)sessionManager {
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc]
                                     initWithBaseURL:[NSURL URLWithString:[self.class serviceRootURL]]];
    manager.requestSerializer = (self.requestSerializerType == APISerializerTypeHTTP
                                 ? [AFHTTPRequestSerializer serializer]
                                 : [AFJSONRequestSerializer serializer]);
    manager.responseSerializer = (self.responseSerializerType == APISerializerTypeHTTP
                                  ? [AFHTTPResponseSerializer serializer]
                                  : [AFJSONResponseSerializer serializer]);
    return manager;
}

- (void)processResponse:(NSURLResponse *)response responseObject:(id)responseObject error:(NSError *)error {
    // all is OK, no network errors
    NSLog(@"[RESPONSE] HTTP 200 OK %@", responseObject);
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    self.completed = YES;
    // read headers
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        self.responseHeaders = ((NSHTTPURLResponse *)response).allHeaderFields;
    }
    id res = responseObject;
    // perform object mapping if possible, otherwise return raw JSON
    if (self.responseClass && [responseObject isKindOfClass:[NSDictionary class]]) {
        res = [[self.responseClass alloc] initWithDictionary:responseObject error:&error];
    }
    else {
        res = responseObject;
    }
    if (self.callback) {
        self.callback(self, res, error);
    }
}

- (void)processError:(NSError *)error request:(NSURLRequest *)request response:(NSURLResponse *)response responseObject:(id)responseObject {
    NSLog(@"[ERROR] %s %@ ERROR %@ JSON:\n%@", __func__, request.URL.absoluteString, error, responseObject);
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    self.completed = YES;
    // check for 401 Not Authorized error
    if (((NSHTTPURLResponse *)response).statusCode == 401) {
        //                                 [[AppDelegate appDelegate] logoutOn401];
        [[NSNotificationCenter defaultCenter]
         postNotificationName:APIRequestGot401NotAuthorizedNotification
         object:nil];
    }
    else {
        id res = responseObject;
        
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *jsonDict = responseObject;
            // perform object mapping if possible, otherwise return raw JSON
            if (self.responseClass) {
                NSError *err = nil;
                res = [[self.responseClass alloc] initWithDictionary:jsonDict
                                                               error:&err];
            }
            else {
                res = jsonDict;
            }
        }
        if (self.callback) {
            self.callback(self, res, error);
        }
//        if (error.code == NSURLErrorNotConnectedToInternet) { ... }
    }
}

@end
