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
	NSString *blogID, *blogName, *url, *username, *password, *xmlrpc;
	BOOL isAdmin;
}

@property int index;
@property (nonatomic, retain) NSString *blogID, *blogName, *url, *username, *password, *xmlrpc;
@property (nonatomic, assign) BOOL isAdmin;

- (id)initWithIndex:(int)blogIndex;

- (UIImage *)favicon;

@end
