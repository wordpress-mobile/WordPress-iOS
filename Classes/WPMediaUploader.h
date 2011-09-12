//
//  WPMediaUploader.h
//  WordPress
//
//  Created by Chris Boyd on 8/3/10.
//  Code is poetry.
//

#import <UIKit/UIKit.h>
#import "NSData+Base64.h"
#import "ASIFormDataRequest.h"
#import "NSString+XMLExtensions.h"
#import "SFHFKeychainUtils.h"
#import "Media.h"
#import "WordPressAppDelegate.h"

enum {
	kSendBufferSize = 32768
};

@class Media;
@interface WPMediaUploader : UIViewController <ASIHTTPRequestDelegate, UIAlertViewDelegate> {
	UILabel *messageLabel;
	UIProgressView *progressView;
    UIButton *stopButton;
	
    ASIFormDataRequest *request;
	BOOL isAtomPub;
}

@property (nonatomic, retain) IBOutlet UILabel *messageLabel;
@property (nonatomic, retain) IBOutlet UIProgressView *progressView;
@property (nonatomic, retain) IBOutlet UIButton *stopButton;
@property (nonatomic, assign) BOOL isAtomPub;
@property (nonatomic, retain) Media *media;
@property (nonatomic, readonly) NSString *localEncodedURL;

- (id)initWithMedia:(Media *)media;
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
- (void)checkAtomPub;
- (void)showAPIAlert;
- (void)buildXMLRPC;
- (void)sendXMLRPC;
- (void)sendAtomPub;

@end
