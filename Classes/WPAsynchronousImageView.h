//
//  WPAsynchronousImageView.h
//  WordPress
//
//  Created by Gareth Townsend on 10/07/09.
//
//  Adapted from: http://www.markj.net/iphone-asynchronous-table-image/
//

#import <UIKit/UIKit.h>


@interface WPAsynchronousImageView : UIImageView {
@private
    NSURLConnection *connection;
    NSMutableData *data;
    NSURL *url;
}

- (void)loadImageFromURL:(NSURL *)theUrl;

@end
