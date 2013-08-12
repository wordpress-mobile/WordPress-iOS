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

#ifndef __has_feature
#define __has_feature(x) 0
#endif
#ifndef __has_extension
#define __has_extension __has_feature // Compatibility with pre-3.0 compilers.
#endif

#if __has_feature(objc_arc) && __clang_major__ >= 3
#error "Quantcast Measurement is not designed to be used with ARC. Please add '-fno-objc-arc' to this file's compiler flags"
#endif // __has_feature(objc_arc)

#import "QuantcastUploadManager.h"
#import "QuantcastDataManager.h"
#import "QuantcastUtils.h"
#import "QuantcastParameters.h"
#import "QuantcastNetworkReachability.h"
#import "QuantcastEvent.h"
#import "QuantcastUploadJSONOperation.h"

@interface QuantcastUploadManager ()
@property (readonly,nonatomic) BOOL ableToUpload;

-(void)networkReachabilityChanged:(NSNotification*)inNotification;
-(void)uploadJSONFile:(NSString*)inJSONFilePath dataManager:(QuantcastDataManager*)inDataManager;


@end

@implementation QuantcastUploadManager
@synthesize ableToUpload=_ableToUpload;

-(id)initWithReachability:(id<QuantcastNetworkReachability>)inNetworkReachabilityOrNil;
{
    self = [super init];
    
    if (self) {
        
        // if there is no Reachability object, assume we are debugging and enable uploading
        _ableToUpload = YES;
        
        if ( nil != inNetworkReachabilityOrNil ) {
         
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkReachabilityChanged:) name:kQuantcastNetworkReachabilityChangedNotification object:inNetworkReachabilityOrNil];

            
            if ( [inNetworkReachabilityOrNil currentReachabilityStatus] == QuantcastNotReachable ){
                _ableToUpload = NO;
            }
        }
        // seed random
        
        srandom(time(0));
                        
        // check uploading directory for any unfinished uploads, and move them to ready to upload directory
        NSError* dirError = nil;
        NSFileManager* fileManager = [NSFileManager defaultManager];
        
        NSString* uploadingDir = [QuantcastUtils quantcastUploadInProgressDirectoryPath];
        NSArray* dirContents = [fileManager contentsOfDirectoryAtPath:uploadingDir error:&dirError];
        
        if ( nil == dirError && [dirContents count] > 0 ) {
            NSString* readyToUploadDirPath = [QuantcastUtils quantcastDataReadyToUploadDirectoryPath];

            for (NSString* filename in dirContents) {
                NSString*  currentFilePath = [uploadingDir stringByAppendingPathComponent:filename];
                
                if ([filename hasSuffix:@"json"]) {
                    NSString* newFilePath = [readyToUploadDirPath stringByAppendingPathComponent:filename];
                    
                    
                    NSError* error;
                    
                    if ( ![fileManager moveItemAtPath:currentFilePath toPath:newFilePath error:&error] ) {
                        // error, will robinson
                        NSLog(@"QC Measurement: Could not relocate file '%@' to '%@'. Error = %@", currentFilePath, newFilePath, error );
                        
                    }

                }
                
            }
            
        }        
        
    }
    
    return self;
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    
    [super dealloc];
}

-(void)networkReachabilityChanged:(NSNotification*)inNotification {
   
    id<QuantcastNetworkReachability> reachabilityObj = (id<QuantcastNetworkReachability>)[inNotification object];
    
    if ( [reachabilityObj currentReachabilityStatus] == QuantcastNotReachable ){
        _ableToUpload = NO;
    }
    else {
        _ableToUpload = YES;
    }

}

#pragma mark - Upload Management

+(NSString*)generateUploadID {
    
    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
    CFStringRef uuidStr = CFUUIDCreateString(kCFAllocatorDefault, uuid);
    
    NSString* uploadID = [NSString stringWithString:(NSString *)uuidStr ];
    
    CFRelease(uuidStr);
    CFRelease(uuid);

    return uploadID;
}

-(void)initiateUploadForReadyJSONFilesWithDataManager:(QuantcastDataManager*)inDataManager {
    
    @synchronized(self) {
        
        if (self.ableToUpload ) {
            //
            // first, get the list of json files in the ready directory, then initiate a transfer for each
            //
            NSFileManager* fileManager = [NSFileManager defaultManager];
            
            NSString* readyDirPath = [QuantcastUtils quantcastDataReadyToUploadDirectoryPath];
            
            NSError* dirError = nil;
            NSArray* dirContents = [fileManager contentsOfDirectoryAtPath:readyDirPath error:&dirError];
            
            if ( nil == dirError && [dirContents count] > 0 ) {
                
                for (NSString* filename in dirContents) {
                    if ( [filename hasSuffix:@"json"] ) {
                        
                        NSString* filePath = [readyDirPath stringByAppendingPathComponent:filename];
                        
                        // get teh upload ID from the file

                        [self uploadJSONFile:filePath dataManager:inDataManager];
                        
                    }
                    
                }
            }
        }
    }

}

-(void)uploadJSONFile:(NSString*)inJSONFilePath dataManager:(QuantcastDataManager*)inDataManager {    
    
    NSString* uploadID = nil;
    NSString* uploadingFilePath = nil;
    
    // get NSURLRequest
    
    NSURLRequest* urlRequest = [self urlRequestForJSONFile:inJSONFilePath reportingUploadID:&uploadID newFilePath:&uploadingFilePath];
    
    if ( nil == uploadID ) {
        // some kind of error. don't upload
        if (self.enableLogging) {
            NSLog(@"QC Measurement: Could not upload JSON file '%@' because upload ID was not found in contents", inJSONFilePath );
        }
        
        return;
    }
    
    // send it!
    
    QuantcastUploadJSONOperation* op = [[[QuantcastUploadJSONOperation alloc] initUploadForJSONFile:uploadingFilePath 
                                                                                       withUploadID:uploadID 
                                                                                     withURLRequest:urlRequest 
                                                                                        dataManager:inDataManager] autorelease];
    op.enableLogging = self.enableLogging;
    
    [inDataManager.opQueue addOperation:op];
    
}


-(NSURLRequest*)urlRequestForJSONFile:(NSString*)inJSONFilePath 
                    reportingUploadID:(NSString**)outUploadID 
                          newFilePath:(NSString**)outNewFilePath 
{
    
    // set upload ID to nil to start with. Only report it if request gene is successful
    
    (*outUploadID) = nil;
    
    NSError* compressError = nil;
    
    NSData* uncompressedBodyData = [NSData dataWithContentsOfFile:inJSONFilePath];

    NSData* bodyData = [QuantcastUtils  gzipData:uncompressedBodyData error:&compressError];
    
    if ( nil != compressError ) {
        if (self.enableLogging) {
            NSLog(@"QC Measurement: Error while trying to compress upload data = %@", compressError);
        }
        
        return nil;
    }
    
    NSURL* postURL = [QuantcastUtils updateSchemeForURL:[NSURL URLWithString:QCMEASUREMENT_UPLOAD_URL]];
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:postURL 
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData 
                                                       timeoutInterval:QCMEASUREMENT_CONN_TIMEOUT_SECONDS];
    
    
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];	
    [request setValue:@"gzip" forHTTPHeaderField:@"Content-Encoding"];	
    [request setHTTPBody:bodyData];
    [request setValue:[NSString stringWithFormat:@"%d", [bodyData length]] forHTTPHeaderField:@"Content-Length"];
    
    //
    // move the file to the uploading diretory to signify that a url request has been generated and no new ones should be created.
    //
    
    NSString* filename = [inJSONFilePath lastPathComponent];
    
    (*outNewFilePath) = [[QuantcastUtils quantcastUploadInProgressDirectoryPath] stringByAppendingPathComponent:filename];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:(*outNewFilePath)]) {
        if (self.enableLogging) {
            NSLog(@"QC Measurement: Upload file '%@' already exists at path '%@'. Deleting ...", filename, (*outNewFilePath) );
        }
        
        [[NSFileManager defaultManager] removeItemAtPath:(*outNewFilePath) error:nil];
    }

    NSError* error;

    if ( ![[NSFileManager defaultManager] moveItemAtPath:inJSONFilePath toPath:(*outNewFilePath) error:&error] ) {
        if (self.enableLogging) {
            NSLog(@"QC Measurement: Could note move file '%@' to location '%@'. Error = %@", inJSONFilePath, (*outNewFilePath), [error localizedDescription] );
        }
        
        return nil;
    }
    
    // now extract upload id from JSON
    
    NSString* jsonStr = [[[NSString alloc] initWithData:uncompressedBodyData encoding:NSUTF8StringEncoding] autorelease]; 
    
    NSRange keyRange = [jsonStr rangeOfString:@"\"uplid\":\""];
    
    jsonStr = [jsonStr substringFromIndex:keyRange.location+keyRange.length];
    
    NSRange terminatorRang = [jsonStr rangeOfString:@"\",\"qcv\":"];
    
    (*outUploadID) = [jsonStr substringToIndex:terminatorRang.location];
    
    return request;
}

#pragma mark - Debugging

@synthesize enableLogging;

- (NSString *)description {
    return [NSString stringWithFormat:@"<QuantcastUploadManager %p>", self ];
}

@end
