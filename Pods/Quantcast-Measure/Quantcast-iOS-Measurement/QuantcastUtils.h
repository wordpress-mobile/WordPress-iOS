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

/*!
 @class QuantcastUtils
 @internal
 */
@interface QuantcastUtils : NSObject

+(NSString*)quantcastCacheDirectoryPath;
+(NSString*)quantcastCacheDirectoryPathCreatingIfNeeded;

+(NSString*)quantcastDataGeneratingDirectoryPath;
+(NSString*)quantcastDataReadyToUploadDirectoryPath;
+(NSString*)quantcastUploadInProgressDirectoryPath;

+(void)emptyAllQuantcastCaches;

+(NSString*)quantcastHash:(NSString*)inStrToHash;

+(NSData*)gzipData:(NSData*)inData error:(NSError**)outError;

/*!
 @internal
 @method handleConnection:didReceiveAuthenticationChallenge:withTrustedHost: 
 @abstract Convenience method for handdling https authentication challenges
 @discussion This method handles https authentication chalenges sent to NSURLConnectionDelegate objects
 @param connection the passed NSURLConnection
 @param challenge the passed NSURLAuthenticationChallenge
 @param inTrustedHost the domain name that self-signed certificates should be accepted from. Pass nil if none should be accepted.
 @param inEnableLogging YES if logging should be enabled
 */
+(void)handleConnection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge withTrustedHost:(NSString*)inTrustedHost loggingEnabled:(BOOL)inEnableLogging;

/*!
 @internal
 @method updateSchemeForURL:
 @abstract Adjusts the URL scheme based on the linkage to the Securirty framework
 @discussion If the code is compiled with QCMEASUREMENT_USE_SECURE_CONNECTIONS defined to 1, the URL scheme will adjusted to use https. Otherwise, the URL will use http.
 @param inURL the URL to adjust. It doesn't matter what the current scheme is.
 @return The adjusted URL
 */
+(NSURL*)updateSchemeForURL:(NSURL*)inURL;

/*!
 @internal
 @method encodeLabelsList:
 @abstract converts a list of NSString labels to a single NSString properly encoded for transmission
 @param inLabelsArrayOrNil An NSArray containing one or more NSStrings
 @return A NSString that should be used for the single NSString label functions
 */
+(NSString*)encodeLabelsList:(NSArray*)inLabelsArrayOrNil;

+(NSString*)urlEncodeString:(NSString*)inString;
+(NSString*)JSONEncodeString:(NSString*)inString;

@end
