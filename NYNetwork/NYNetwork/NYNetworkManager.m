//
//  NYNetworkManager.m
//  NYNetwork
//
//  Created by 牛严 on 16/6/28.
//  Copyright © 2016年 NYNetwork. All rights reserved.
//

#import "NYNetworkManager.h"
#import "NYHTTPConnection.h"
#import <objc/runtime.h>
#import <FBRetainCycleDetector/FBRetainCycleDetector.h>

@implementation NYNetworkManager

+ (instancetype)sharedManager
{
    static NYNetworkManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (void)addRequest:(NYBaseRequest *)request
{
    __weak typeof(self) weakSelf = self;
    NYHTTPConnection *connection =
    [[NYHTTPConnection alloc]init];
    [connection connectWithRequest:request success:^(NYHTTPConnection *connection, id responseJsonObject) {
        [weakSelf processConnection:connection withRequest:request responseJsonObject:responseJsonObject];
    } failure:^(NYHTTPConnection *connection, NSError *error) {
        [weakSelf processConnection:connection withRequest:request error:error];
    }];
    FBRetainCycleDetector *detector = [FBRetainCycleDetector new];
    [detector addCandidate:connection];
    NSSet *retainCycles = [detector findRetainCycles];
    NSLog(@"connection %@", retainCycles);
    
}

- (void)processConnection:(NYHTTPConnection *)connection withRequest:(NYBaseRequest *)request responseJsonObject:(id)responseJsonObject
{
    request.responseObject = responseJsonObject;
    [self callBackRequestSuccess:request];
}

- (void)processConnection:(NYHTTPConnection *)connection withRequest:(NYBaseRequest *)request error:(NSError *)error
{
    request.error = error;
    [self callBackRequestFailure:request];
}

//--------------------------------------------回调--------------------------------------------
/**
 *  成功回调
 *
 *  @param request
 */
- (void)callBackRequestSuccess:(NYBaseRequest *)request
{
    if (request.success) {
        [self defaultMethodRequestSuccessWithRequest:request];
        request.success(request,request.responseObject);
    }
    if ([request.delegate respondsToSelector:@selector(requesetFinished:)]) {
        [request.delegate requesetFinished:request];
    }
    [self clearRequestBlock:request];
}

/**
 *  失败回调
 *
 *  @param request
 */
- (void)callBackRequestFailure:(NYBaseRequest *)request
{    
    if (request.failure) {
        [self defaultMethodRequestFaulureWithRequest:request];
        request.failure(request,request.error);
    }
    if ([request.delegate respondsToSelector:@selector(requestFailed:)]) {
        [request.delegate requestFailed:request];
    }
    [self clearRequestBlock:request];
}

- (void)clearRequestBlock:(NYBaseRequest *)request
{
    request.success = nil;
    request.failure = nil;
}

//---------------------------------在回调中默认执行方法，在扩展中重写--------------------------
- (void)defaultMethodRequestSuccessWithRequest:(NYBaseRequest *)request
{
}

- (void)defaultMethodRequestFaulureWithRequest:(NYBaseRequest *)request
{
}

@end
