//
//  SPS3Manager.h
//  Simperium
//
//  Created by Michael Johnston on 11-05-31.
//  Copyright 2011 Simperium. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SPBinaryManager.h"

#import <AWSiOSSDK/SimpleDB/AmazonSimpleDBClient.h>
#import <AWSiOSSDK/SQS/AmazonSQSClient.h>
#import <AWSiOSSDK/SNS/AmazonSNSClient.h>

@class Simperium;
@class SPManagedObject;
@class ASIHTTPRequest;
@class S3GetObjectResponse;
@class S3PutObjectResponse;

@interface SPS3Manager : SPBinaryManager <AmazonServiceRequestDelegate> {
    S3GetObjectResponse *downloadResponse;
    S3PutObjectResponse *uploadResponse;
    
    NSMutableDictionary *downloadsInProgressData;
    NSMutableDictionary *downloadsInProgressRequests;
    NSMutableDictionary *uploadsInProgressRequests;
    NSMutableDictionary *remoteFilesizeCache;
    NSMutableDictionary *bgTasks;
    
    ASIHTTPRequest *binaryTokenRequest;
    dispatch_queue_t backgroundQueue;
    NSString *bucketName;
    
}

@property(nonatomic, strong, readonly) NSMutableDictionary *downloadsInProgressData;
@property(nonatomic, strong, readonly) NSMutableDictionary *downloadsInProgressRequests;
@property(nonatomic, strong, readonly) NSMutableDictionary *uploadsInProgressRequests;
@property(nonatomic, strong, readonly) NSMutableDictionary *bgTasks;
@property(nonatomic, strong) NSString *bucketName;

-(id)initWithSimperium:(Simperium *)aSimperium;
-(int)sizeOfRemoteFile:(NSString *)filename;

@end
