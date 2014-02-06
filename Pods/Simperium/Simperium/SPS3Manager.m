//
//  SPS3Manager.m
//  Simperium
//
//  Created by John Carter on 11-05-31.
//  Copyright 2011 Simperium. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SPS3Manager.h"
#import "SPBinaryTransportDelegate.h"
#import "SPManagedObject.h"
#import "SPUser.h"
#import "Simperium.h"
#import "SPEnvironment.h"
#import "ASIHTTPRequest.h"
#import "NSString+Simperium.h"
#import "JSONKit+Simperium.h"

#import <AWSiOSSDK/S3/AmazonS3Client.h>

@interface SPS3Manager()
@property (nonatomic, strong) AmazonCredentials *awsCredentials;
@property (nonatomic, strong) AmazonS3Client *awsConnection;
@property (nonatomic, strong) NSDate *binaryAuthTokenExpiry;
@property (nonatomic, copy) NSString *binaryAuthID;
@property (nonatomic, copy) NSString *binaryAuthSecret;
@property (nonatomic, copy) NSString *binaryAuthSessionToken;
@property (nonatomic, copy) NSString *remoteURL;
@property (nonatomic, strong) NSMutableDictionary *remoteFilesizeCache;

-(BOOL)binaryTokenExpired;
-(BOOL)checkOrGetBinaryAuthentication;
-(BOOL)connectToAWS;
-(NSString *)getS3BucketName;
@end

@implementation SPS3Manager
@synthesize downloadsInProgressRequests;
@synthesize downloadsInProgressData;
@synthesize uploadsInProgressRequests;
@synthesize awsCredentials;
@synthesize awsConnection;
@synthesize binaryAuthTokenExpiry;
@synthesize binaryAuthID;
@synthesize binaryAuthSecret;
@synthesize binaryAuthSessionToken;
@synthesize remoteURL;
@synthesize remoteFilesizeCache;
@synthesize bgTasks;
@synthesize bucketName;

-(id)initWithSimperium:(Simperium *)aSimperium
{
    NSLog(@"Simperium initializing binary manager");
    if ((self = [super initWithSimperium:aSimperium])) {
        downloadsInProgressData = [NSMutableDictionary dictionaryWithCapacity: 3];
        downloadsInProgressRequests = [NSMutableDictionary dictionaryWithCapacity: 3];
        uploadsInProgressRequests = [NSMutableDictionary dictionaryWithCapacity: 3];
        remoteFilesizeCache = [NSMutableDictionary dictionaryWithCapacity: 3];
        bgTasks = [NSMutableDictionary dictionaryWithCapacity: 3];
        
        backgroundQueue = dispatch_queue_create("com.simperium.simperium.backgroundQueue", NULL);        
    }
    return self;
}

-(BOOL)binaryTokenExpired
{
    
    // Make sure all required auth data is here
    if ((!self.binaryAuthID) || (!self.binaryAuthSecret) || (!self.binaryAuthSessionToken) || (!self.binaryAuthTokenExpiry))
        return YES;
    
    // Check if expiry date is in the past
    NSDate *today = [NSDate date];
    if ([today compare: binaryAuthTokenExpiry] == NSOrderedDescending ) {
        return YES;
    }
    return NO;
}

/** Checks if user has a binary auth token, attempts to acquire one if user does not.
 
 @return A BOOL representing whether or not call was succesful.
 */

-(BOOL)checkOrGetBinaryAuthentication
{
    /* check to see if current expiry has passed */
    /* or it was never acquired */
    if ([self binaryTokenExpired]) {
        
        NSLog(@"Simperium binary refreshing token: %@", self.binaryAuthURL);
        
        binaryTokenRequest = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:self.binaryAuthURL]];
        [binaryTokenRequest addRequestHeader:@"Content-Type" value:@"application/json"];
        [binaryTokenRequest addRequestHeader:@"X-Simperium-Token" value:[simperium.user authToken]];
        [binaryTokenRequest setRequestMethod:@"POST"];
        [binaryTokenRequest setTimeOutSeconds:10];
        [binaryTokenRequest startSynchronous];
        
        if ([binaryTokenRequest responseStatusCode] == 200) {
            NSString *response = [binaryTokenRequest responseString];
            NSLog(@"Binary auth response: %@", response);
            NSDictionary *userDict =  [[binaryTokenRequest responseString] sp_objectFromJSONString];
            
            self.binaryAuthID = [userDict objectForKey:@"access_id"];
            self.binaryAuthSecret = [userDict objectForKey:@"secret"];
            self.binaryAuthSessionToken = [userDict objectForKey:@"session_token"];
            self.bucketName = [userDict objectForKey:@"bucket_name"];
            self.keyPrefix = [userDict objectForKey:@"key_prefix"];
            
            // ARGH, fix the leading '/' character
            self.keyPrefix = [self.keyPrefix substringFromIndex:1];
            
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSS'Z'"];
                        
            self.binaryAuthTokenExpiry = [dateFormatter dateFromString:[NSString stringWithString:[userDict objectForKey:@"expiration"]]];
                        
            AmazonCredentials *credentials = [[AmazonCredentials alloc] initWithAccessKey: self.binaryAuthID withSecretKey: self.binaryAuthSecret withSecurityToken:self.binaryAuthSessionToken];
            self.awsCredentials = credentials;
            
            [self createLocalDirectoryForPrefix:self.keyPrefix];
            
            if (![self binaryTokenExpired]) {
                
                return YES;
            }
        }
        /* token request problem */
        else {
            NSLog(@"Simperium binary token request returned code %d (%@)",[binaryTokenRequest responseStatusCode], [binaryTokenRequest responseString]);
            self.binaryAuthID = nil;
            self.binaryAuthSecret = nil;
            self.binaryAuthSessionToken = nil;
            self.binaryAuthTokenExpiry = nil;
        }

        return NO;
    }
    
    /* token not expired */
    return YES;
}

-(BOOL)connectToAWS {
        
    if (!self.awsCredentials)
        return NO;
    
    if (self.awsConnection == nil) {
        //[AmazonLogger verboseLogging]; 
        AmazonS3Client *connection = [[AmazonS3Client alloc] initWithCredentials: self.awsCredentials];
        self.awsConnection = connection;
    }
        
    return YES;
}

-(NSString *)getS3BucketName {
    [self checkOrGetBinaryAuthentication];    
    return self.bucketName;
}

-(NSString *)prefixFilename:(NSString *)filename {
    [self checkOrGetBinaryAuthentication];
    return [NSString stringWithFormat:@"%@/%@",self.keyPrefix,filename];
}

-(NSData *)dataForFilename:(NSString *)filename
{       
    [self checkOrGetBinaryAuthentication];    
    
    if (![self binaryExists:filename])
        return nil;
 
    NSString *binaryPath = [self pathForFilename:filename];
    
    NSError *theError = nil;
    NSData *data = [NSData dataWithContentsOfFile: binaryPath options:NSDataWritingAtomic error: &theError];
    if (theError) {
        NSLog(@"Simperium error loading binary file (%@): %@", binaryPath, [theError localizedDescription]);
        return nil;
    }
    return data;
}

-(NSString *)addBinary:(NSData *)binaryData toObject:(SPManagedObject *)object bucketName:(NSString *)name attributeName:(NSString *)attributeName
{
    [self checkOrGetBinaryAuthentication];
    
    return [super addBinary:binaryData toObject:object bucketName:name attributeName:attributeName];
}

-(BOOL)binaryExists:(NSString *)filename
{
    NSString *fullPath = [self pathForFilename:filename];
    return [[NSFileManager defaultManager] fileExistsAtPath:fullPath];
}

-(int)sizeOfRemoteFile:(NSString *)filename
{   
    NSNumber *cached = [remoteFilesizeCache objectForKey:filename];
    if (cached) {
        return [cached intValue];
    }
    S3GetObjectRequest *headRequest = [[S3GetObjectRequest alloc] initWithKey:filename withBucket: [self getS3BucketName]];
    headRequest.httpMethod = @"HEAD";
        
    S3Response *headResponse = [[S3Response alloc] init];
    headResponse = [self.awsConnection invoke:headRequest];
    
    if (headResponse.httpStatusCode == 200) {
        [remoteFilesizeCache setObject:[NSNumber numberWithInt:headResponse.contentLength] forKey:filename];
        return headResponse.contentLength;
    }
        
    return 0;
}

NSString *hackFilename;

-(void)startDownloading:(NSString *)filename
{
    [self checkOrGetBinaryAuthentication];
    [self connectToAWS];
    
    hackFilename = [filename copy];
    
    UIApplication *app = [UIApplication sharedApplication];
    UIBackgroundTaskIdentifier tempBgTask = [app beginBackgroundTaskWithExpirationHandler:^{
        
        NSLog(@"Expired Download for %@.",filename);
        [app endBackgroundTask:[[self.bgTasks objectForKey:filename] intValue]];
        [self.bgTasks setObject:[NSNumber numberWithInt:UIBackgroundTaskInvalid] forKey:filename];
        
    }];
    
    [self.bgTasks setObject:[NSNumber numberWithInt: tempBgTask] forKey:filename];
    dispatch_async(backgroundQueue, ^{
        __block int sizeOfRemoteFile;
        // Get the file size on another thread since it can take awhile
        // (not strictly safe to do this here due to the cache implementation, but ok for prototype)
        sizeOfRemoteFile = [self sizeOfRemoteFile:filename];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"Start Downloading: %@/%@",[self getS3BucketName],filename);
            NSLog(@"Size of remote file: %d",sizeOfRemoteFile);
            
            // @TODO error handling ?
            [transmissionProgress setObject:[NSNumber numberWithInt:sizeOfRemoteFile] forKey:filename];
            
            S3GetObjectRequest *downloadRequest = [[S3GetObjectRequest alloc] initWithKey:filename withBucket: [self getS3BucketName]];
            
            [downloadRequest setDelegate:self];
            downloadResponse = [self.awsConnection getObject: downloadRequest];
            NSMutableData *fileData = [[NSMutableData alloc] initWithCapacity:1024];
            [downloadsInProgressData setObject: fileData forKey:filename];
            [downloadsInProgressRequests setObject: downloadRequest forKey:filename];
            
            for (id<SPBinaryTransportDelegate>delegate in delegates) {
                if ([delegate respondsToSelector:@selector(binaryDownloadStarted:)]) 
                    [delegate binaryDownloadStarted:filename];
            }
        });
    
    });
}

#define ACCESS_KEY_ID          @"AKIAJNUVGT4RMW7R55QA"
#define SECRET_KEY             @"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"
#define BUCKET                 @"my-unique-name-AKIAJNUVGT4RMW7R55QApicture-bucket"
-(void)startUploading:(NSString *)filename
{
    [self checkOrGetBinaryAuthentication];
    [self connectToAWS];
    
//    UIApplication *app = [UIApplication sharedApplication];
//    UIBackgroundTaskIdentifier tempBgTask = [app beginBackgroundTaskWithExpirationHandler:^{
//    
//        NSLog(@"Expired Upload for %@.",filename);
//        [app endBackgroundTask:[[self.bgTasks objectForKey:filename] intValue]];
//        [self.bgTasks setObject:[NSNumber numberWithInt:UIBackgroundTaskInvalid] forKey:filename];
//        
//    }];
//    
//    [self.bgTasks setObject:[NSNumber numberWithInt: tempBgTask] forKey:filename];
    
    //dispatch_async(dispatch_get_main_queue(), ^{
        NSData *data = [self dataForFilename:filename];
        if (data == nil) {
            NSAssert1(0, @"Simperium error: could not find binary file: %@", filename);
        }

    @try {
        //AmazonS3Client *s3 = [[AmazonS3Client alloc] initWithAccessKey:ACCESS_KEY_ID withSecretKey:SECRET_KEY];
        //AmazonS3Client *s3 = [[AmazonS3Client alloc] initWithAccessKey:self.binaryAuthID withSecretKey:self.binaryAuthSecret];

        //[self.awsConnection createBucket:[[S3CreateBucketRequest alloc] initWithName:[self getS3BucketName]]];

        NSString *s3bucketName = [self getS3BucketName];
        NSString *s3filename = [self prefixFilename:filename];
        S3PutObjectRequest *uploadRequest = [[S3PutObjectRequest alloc] initWithKey:s3filename inBucket:s3bucketName];
        
        // Create the picture bucket.
        //[s3 createBucket:[[S3CreateBucketRequest alloc] initWithName:BUCKET]];
        
        // Upload image data.  Remember to set the content type.
        //S3PutObjectRequest *por = [[S3PutObjectRequest alloc] initWithKey:@"NameOfThePicture" inBucket:BUCKET];
        //por.data = data;
        [uploadRequest setDelegate: self];
        //uploadRequest.contentType = @"image/jpeg";
        uploadRequest.data = data;

        NSLog(@"Simperium uploading binary %@ to path: %@", s3filename, s3bucketName);
        NSLog(@"Size of local file: %d",[self sizeOfLocalFile:filename]);

        // @TODO error handling ?
        [transmissionProgress setObject:[NSNumber numberWithInt: [self sizeOfLocalFile:filename]] forKey:filename];

        uploadResponse = [self.awsConnection putObject: uploadRequest];
        //uploadResponse = [s3 putObject: uploadRequest];
        [uploadsInProgressRequests setObject: uploadRequest forKey: filename];

        for (id<SPBinaryTransportDelegate>delegate in delegates) {
            if ([delegate respondsToSelector:@selector(binaryUploadStarted:)]) 
                [delegate binaryUploadStarted:filename];
        }
    }   @catch (AmazonClientException *exception) {
        NSLog(@"S3 error: %@", exception.message);
    }
    //});
}

// Sent as data is received.
-(void)request: (S3Request *)request didReceiveData: (NSData *) data {
    
    // Only use this for download notifications
    if ([request isKindOfClass:[S3PutObjectRequest class]])
         return;
         
    if (data != nil) {

        long progress = [[transmissionProgress objectForKey:request.key] intValue];
        long receivedSize = [data length];
        [transmissionProgress setObject:[NSNumber numberWithInt:(progress - receivedSize)] forKey:request.key];
        
        for (id<SPBinaryTransportDelegate>delegate in delegates) {
            if ([delegate respondsToSelector: @selector(binaryDownloadReceivedBytes:forFilename:)]) {
                [delegate binaryDownloadReceivedBytes:[data length] forFilename: request.key];
            }
                        
            if ([delegate respondsToSelector: @selector(binaryDownloadPercent:object:)]) {
                int remoteSize = [self sizeOfRemoteFile:request.key];
                int remoteRemaining = [self sizeRemainingToTransmit:request.key];
                float percent = 1.0 - ((float) remoteRemaining / (float) remoteSize);
                NSDictionary *objectPath = [[pendingBinaryDownloads objectForKey:request.key] objectAtIndex:0];
                NSString *fromKey = [objectPath objectForKey:BIN_KEY];
                NSString *fromBucketName = [objectPath objectForKey:BIN_BUCKET];
                SPManagedObject *object = [[simperium bucketForName:fromBucketName] objectForKey:fromKey];
                [delegate binaryDownloadPercent:percent object:object];
            }
        }
    }
    else {
        
        for (id<SPBinaryTransportDelegate>delegate in delegates) {
            if ([delegate respondsToSelector: @selector(binaryDownloadReceivedBytes:forFilename:)]) {
                [delegate binaryDownloadReceivedBytes:0 forFilename: request.key];
            }
        }
    }
}

// Sent when body data has been read and processed.
-(void)request: (S3Request *)request didCompleteWithResponse: (S3Response *) response {
    // TODO: handle AWS exceptions
    NSLog(@"Simperium binary request completed (%@)",request.key);
    
    UIBackgroundTaskIdentifier bgTask = [[self.bgTasks objectForKey:request.key] intValue];
    if (bgTask != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:bgTask]; 
        bgTask = UIBackgroundTaskInvalid;
        [self.bgTasks setObject:[NSNumber numberWithInt: UIBackgroundTaskInvalid] forKey:request.key];
    }
    
    // For download requests
    if ([downloadsInProgressData objectForKey:request.key] != nil) {
        NSLog(@"Simperium binary download finished (%d)",response.httpStatusCode);
        
        [downloadsInProgressData setObject:response.body forKey:request.key];
        NSString *path = [self pathForFilename: request.key];        
        NSError *theError;
        if (![[downloadsInProgressData objectForKey:request.key] writeToFile:path options:NSDataWritingAtomic error: &theError]) {
            NSLog(@"Simperium error storing downloaded binary file: %@", [theError localizedDescription]);
            NSLog(@"Failured during writeToFile");
        }
        
        [self finishedDownloading:request.key];
        [downloadsInProgressData removeObjectForKey:request.key];
    }
    else if ([uploadsInProgressRequests objectForKey:request.key] != nil) {
        NSLog(@"Simperium binary upload finished (%d)",response.httpStatusCode);
        [uploadsInProgressRequests removeObjectForKey:request.key];
        [self finishedUploading:request.key];
    }
    else {
        NSLog(@"How did we get in here?");
    }
}

// Sent when the request transmitted data.
-(void)request: (S3Request *)request didSendData: (NSInteger) bytesWritten totalBytesWritten: (NSInteger) totalBytesWritten totalBytesExpectedToWrite: (NSInteger) totalBytesExpectedToWrite {
    
    long progress = [[transmissionProgress objectForKey:request.key] intValue];
    [transmissionProgress setObject:[NSNumber numberWithInt:(progress - bytesWritten)] forKey:request.key];
    
    for (id<SPBinaryTransportDelegate>delegate in delegates) {
        if ([delegate respondsToSelector: @selector(binaryUploadReceivedBytes:forFilename:)]) {
            [delegate binaryUploadTransmittedBytes:bytesWritten forFilename: request.key];
        }
        
        if ([delegate respondsToSelector: @selector(binaryUploadPercent:object:)]) {
            
            int remoteSize = [self sizeOfLocalFile:request.key];
            int remoteRemaining = [self sizeRemainingToTransmit:request.key];
            float percent = 1.0 - ((float) remoteRemaining / (float) remoteSize);
            
            NSDictionary *objectPath = [pendingBinaryUploads objectForKey:request.key];
            NSString *fromKey = [objectPath objectForKey:BIN_KEY];
            NSString *fromBucketName = [objectPath objectForKey:BIN_BUCKET];
            
            SPManagedObject *object = [[simperium bucketForName:fromBucketName] objectForKey:fromKey];
            [delegate binaryUploadPercent:percent object: object];
        }        
    }
}

// Sent when there was a basic failure with the underlying connection. 
-(void)request: (S3Request *)request didFailWithError: (NSError *) error {
    NSLog(@"Simperium binary basic failure: %@",error);

    if ([downloadsInProgressData objectForKey:request.key] != nil) {
    
        for (id<SPBinaryTransportDelegate>delegate in delegates) {
            if ([delegate respondsToSelector:@selector(binaryDownloadFailed:withError:)]) 
                [delegate binaryDownloadFailed:request.key withError:error];
        }
        
    }
    else if ([uploadsInProgressRequests objectForKey:request.key] != nil) {
     
        for (id<SPBinaryTransportDelegate>delegate in delegates) {
            if ([delegate respondsToSelector:@selector(binaryUploadFailed:withError:)]) 
                [delegate binaryUploadFailed:request.key withError:error];
        }
        
    }
    else {
    }
    
    // Retry
}

// Sent when the service responded with an exception.
// @todo -- how do we want to handle this
//-(void)request: (AmazonServiceRequest *)request didFailWithServiceException: (NSException *) exc {    
//    NSLog(@"Simperium binary exception: %@",exc);
//}

@end
