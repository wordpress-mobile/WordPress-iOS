/*
 * Copyright 2012 Quantcast Corp.
 *
 * This software is licensed under the Quantcast Mobile App Measurement Terms of Service
 * https://www.quantcast.com/learning-center/quantcast-terms/mobile-app-measurement-tos
 * (the “License”). You may not use this file unless (1) you sign up for an account at
 * https://www.quantcast.com and click your agreement to the License and (2) are in
 * compliance with the License. See the License for the specific language governing
 * permissions and limitations under the License.
 *
 */

#import <Foundation/Foundation.h>

@class QuantcastDataManager;

/*!
 @class QuantcastUploadJSONOperation
 @internal
 */
@interface QuantcastUploadJSONOperation : NSOperation <NSURLConnectionDataDelegate> {
    QuantcastDataManager* _dataManager;
    NSURLRequest* _request;
    NSURLConnection* _connection;
    
    NSString* _jsonFilePath;
    NSString* _uploadID;
    
    BOOL _isExecuting;
    BOOL _isFinished;
    BOOL _isSuccessful;
    
    NSDate* _startTime;

    UIBackgroundTaskIdentifier _backgroundTask;

}
@property(nonatomic, readonly ) BOOL successful;
@property(nonatomic, assign) BOOL enableLogging;

-(id)initUploadForJSONFile:(NSString*)inJSONFilePath withUploadID:(NSString*)inUploadID withURLRequest:(NSURLRequest*)inURLRequest dataManager:(QuantcastDataManager*)inDataManager;

// these methods are "private"
-(void)done;
-(void)uploadFailed;

@end
