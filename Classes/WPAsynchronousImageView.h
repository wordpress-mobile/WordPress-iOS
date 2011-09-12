//
//  WPAsynchronousImageView.h
//  WordPress
//
//  Created by Gareth Townsend on 10/07/09.
//
//  Adapted from: http://www.markj.net/iphone-asynchronous-table-image/
//

#import <UIKit/UIKit.h>
#import "WordPressAppDelegate.h"

@interface WPAsynchronousImageView : UIImageView {
@private
    NSURLConnection *connection;
    NSMutableData *data;
    NSURL *url;
    BOOL isBlavatar;
    BOOL isWPCOM;
}

@property (nonatomic, assign) BOOL isBlavatar;
@property (nonatomic, assign) BOOL isWPCOM;


- (void)loadImageFromURL:(NSURL *)theUrl;

@end
