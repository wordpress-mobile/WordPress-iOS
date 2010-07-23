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
#pragma mark Custom methods

- (UIImage *)favicon {
    NSDictionary *blog = [[BlogDataManager sharedDataManager] blogAtIndex:index];
    UIImage *faviconImage = nil;
    NSString *fileName = [NSString stringWithFormat:@"favicon-%@-%@.png", [blog valueForKey:kBlogHostName], [blog objectForKey:kBlogId]];
	fileName = [fileName stringByReplacingOccurrencesOfRegex:@"http(s?)://" withString:@""];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *faviconFilePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:fileName];

    if ([[NSFileManager defaultManager] fileExistsAtPath:faviconFilePath] == YES) {
        faviconImage = [UIImage imageWithContentsOfFile:faviconFilePath];
    }
	else {
		faviconImage = [UIImage imageNamed:@"favicon"];
		[self downloadFavicon];
	}

    return faviconImage;
}

- (void)downloadFavicon {
	[self performSelectorInBackground:@selector(downloadFaviconInBackground) withObject:nil];
}

- (void)downloadFaviconInBackground {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
    NSDictionary *blog = [[BlogDataManager sharedDataManager] blogAtIndex:index];
	NSString *faviconURL = [NSString stringWithFormat:@"%@favicon.ico", [blog valueForKey:@"url"]];
	if(![faviconURL hasPrefix:@"http"])
		faviconURL = [NSString stringWithFormat:@"http://%@", faviconURL];
	
    NSString *fileName = [NSString stringWithFormat:@"favicon-%@-%@.png", [blog valueForKey:kBlogHostName], [blog objectForKey:kBlogId]];
	fileName = [fileName stringByReplacingOccurrencesOfRegex:@"http(s?)://" withString:@""];
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *faviconFilePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:fileName];
	UIImage *faviconImage = [[UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:faviconURL]]] scaleImageToSize:CGSizeMake(16.0f, 16.0f)];
	
	if (faviconImage != NULL) {
		//[[NSNotificationCenter defaultCenter] postNotificationName:@"BlogsRefreshNotification" object:nil];
		[[NSFileManager defaultManager] createFileAtPath:faviconFilePath contents:UIImagePNGRepresentation(faviconImage) attributes:nil];
	}
	
	[pool release];
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
