//
//  WPMediaUploader.h
//  WordPress
//
//  Created by Chris Boyd on 8/3/10.
//  Code is poetry.
//

#import <UIKit/UIKit.h>
#import "BlogDataManager.h"
#import "NSData+Base64.h"
#import "ASIFormDataRequest.h"
#import "NSString+XMLExtensions.h"

enum {
	kSendBufferSize = 32768
};

@interface WPMediaUploader : UIViewController <ASIHTTPRequestDelegate, UIAlertViewDelegate> {
	UILabel *messageLabel;
	UIProgressView *progressView;
    UIButton *stopButton;
	
	MediaType mediaType;
	MediaOrientation orientation;
	NSString *filename, *xmlrpcURL, *xmlrpcHost, *localURL, *localEncodedURL;
	NSData *bits;
	float filesize;
	BOOL isAtomPub;
}

@property (nonatomic, retain) IBOutlet UILabel *messageLabel;
@property (nonatomic, retain) IBOutlet UIProgressView *progressView;
@property (nonatomic, retain) IBOutlet UIButton *stopButton;
@property (nonatomic, assign) MediaType mediaType;
@property (nonatomic, retain) NSString *filename, *xmlrpcURL, *xmlrpcHost, *localURL, *localEncodedURL;
@property (nonatomic, assign) float filesize;
@property (nonatomic, assign) MediaOrientation orientation;
@property (nonatomic, retain) NSData *bits;
@property (nonatomic, assign) BOOL isAtomPub;

- (void)start;
- (void)stop;
- (void)stopWithStatus:(NSString *)status;
- (void)stopWithNotificationName:(NSString *)notificationName;
- (void)finishWithNotificationName:(NSString *)notificationName object:(NSObject *)object userInfo:(NSDictionary *)userInfo;
- (void)reset;
- (IBAction)cancelAction:(id)sender;
- (void)updateStatus:(NSString *)status;
- (NSString *)xmlrpcPrefix;
- (NSString *)xmlrpcSuffix;
- (void)updateProgress:(NSDictionary *)values;
- (void)base64EncodeFile;
- (void)base64EncodeImage;
- (void)checkAtomPub;
- (void)showAPIAlert;
- (void)buildXMLRPC;
- (void)sendXMLRPC;
- (void)sendAtomPub;

@end
