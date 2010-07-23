//
//  Blog.m
//  WordPress
//
//  Created by Gareth Townsend on 24/06/09.
//

#import "Blog.h"
#import "BlogDataManager.h"
#import "UIImage+INResizeImageAllocator.h"

@implementation Blog
@synthesize blogID, blogName, url, host, username, password, xmlrpc, isAdmin;

@synthesize index;

#pragma mark -
#pragma mark Initialize

- (id)initWithIndex:(int)blogIndex {
    if (self = [super init]) {
        [self setIndex:blogIndex];
    }

    return self;
}

#pragma mark -
#pragma mark Pseudo instance variables
- (UIImage *)favicon {
    NSDictionary *blog = [[BlogDataManager sharedDataManager] blogAtIndex:index];
    UIImage *faviconImage = nil;
    NSString *fileName = [NSString stringWithFormat:@"favicon-%@-%@.png", [blog objectForKey:kBlogHostName], [blog objectForKey:kBlogId]];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *faviconFilePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:fileName];

    if ([[NSFileManager defaultManager] fileExistsAtPath:faviconFilePath] == YES) {
        faviconImage = [UIImage imageWithContentsOfFile:faviconFilePath];
    }
	else {
        NSString *faviconURL = [NSString stringWithFormat:@"%@favicon.ico", [blog valueForKey:@"url"]];
		if(![faviconURL hasPrefix:@"http://"])
			faviconURL = [NSString stringWithFormat:@"http://%@", faviconURL];
        faviconImage = [[UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:faviconURL]]] scaleImageToSize:CGSizeMake(16.0f, 16.0f)];

        if (faviconImage == NULL) {
            faviconImage = [UIImage imageNamed:@"favicon"];
        }

        [[NSFileManager defaultManager] createFileAtPath:faviconFilePath contents:UIImagePNGRepresentation(faviconImage) attributes:nil];
    }

    return faviconImage;
}

#pragma mark -
#pragma mark Dealloc

- (void)dealloc {
	[blogID release];
	[blogName release];
	[url release];
	[host release];
	[username release];
	[password release];
	[xmlrpc release];
    [super dealloc];
}

@end
