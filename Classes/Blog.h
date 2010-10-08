//
//  Blog.h
//  WordPress
//
//  Created by Gareth Townsend on 24/06/09.
//

#import <Foundation/Foundation.h>

@interface Blog : NSObject {
@private
    int index;
	NSString *blogID, *blogName, *url, *hostURL, *username, *password, *xmlrpc;
	BOOL isAdmin, hasVideoPress;
	NSMutableDictionary *settings;
}

@property int index;
@property (nonatomic, retain) NSString *blogID, *blogName, *url, *hostURL, *username, *password, *xmlrpc;
@property (nonatomic, assign) BOOL isAdmin, hasVideoPress;
@property (nonatomic, retain) NSMutableDictionary *settings;

- (id)initWithIndex:(int)blogIndex;
- (UIImage *)favicon;
- (void)downloadFavicon;
- (void)downloadFaviconInBackground;

@end
