//
//  WPAsynchronousImageView.h
//  WordPress
//
//  Created by Gareth Townsend on 10/07/09.
//  Copyright 2009 Clear Interactive. All rights reserved.
//
//  Adapted from: http://www.markj.net/iphone-asynchronous-table-image/
//

#import <UIKit/UIKit.h>

@interface WPAsynchronousImageView : UIImageView {
@private
    NSURLConnection *connection;
    NSMutableData *data;
}

- (void)loadImageFromURL:(NSURL *)url;

@end
