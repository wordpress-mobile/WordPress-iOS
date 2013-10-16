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

@class QuantcastDatabase;
@class QuantcastEvent;
@class QuantcastUploadManager;
@class QuantcastPolicy;
@protocol QuantcastNetworkReachability;

/*!
 @class QuantcastDataManager
 @internal
 */
@interface QuantcastDataManager : NSObject {
    QuantcastDatabase*  _db;
    
    QuantcastUploadManager* _uploadManager;
    QuantcastPolicy* _policy;
    NSOperationQueue* _opQueue;
    
    BOOL _enableLogging;
    BOOL _isOptOut;
}
@property (readonly) QuantcastUploadManager* uploadManager;
@property (readonly) QuantcastPolicy* policy;
@property (readonly) NSOperationQueue* opQueue;

// this method is exposed only for unit testing purposes
+(void)initializeMeasurementDatabase:(QuantcastDatabase*)inDB;

-(id)initWithOptOut:(BOOL)inOptOutStatus policy:(QuantcastPolicy*)inPolicy;

/*!
 @internal
 @method enableDataUploading
 @abstract data uploading is not enabled by default. This is done mostly for unit testing purposes. This mehtod must be called before data uploading can start.
 */
-(void)enableDataUploadingWithReachability:(id<QuantcastNetworkReachability>)inNetworkReachability;

#pragma mark - Recording Events
@property (assign,nonatomic) NSUInteger uploadEventCount;
@property (assign,nonatomic) NSUInteger backgroundUploadEventCount;

-(void)recordEvent:(QuantcastEvent*)inEvent;
-(NSArray*)recordedEvents;

-(NSUInteger)eventCount;

-(void)initiateDataUpload;

#pragma mark - JSON conversion

-(NSString*)genJSONStringWithDeletingDatabase:(BOOL)inDoDeleteDB;

#pragma mark - Opt-Out Handling
@property (assign,nonatomic) BOOL isOptOut;

#pragma mark - Data File Management

/*!
 @internal
 @method dumpDataManagerToFileWithUploadID:
 @abstract creates a json file containing all the events in the passed datamanager.
 @param inUploadID A string containing an upload ID. This value should be globally unique.
 @result The file path of the file created. This will be nil if the file was not created successfully.
 */
-(NSString*)dumpDataManagerToFileWithUploadID:(NSString*)inUploadID;

/*!
 @internal
 @method trimEventsDatabaseBy:
 @abstract Removes the oldest events from the event database by the indicated event count
 @param inEventsToDelete the desired number of events to delete from the event database
 */
-(void)trimEventsDatabaseBy:(NSUInteger)inEventsToDelete;

#pragma mark - Debugging
@property (assign,nonatomic) BOOL enableLogging;

- (NSString *)description;


@end
