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

@synthesize index;

#pragma mark -
#pragma mark Initialize and dealloc

- (id)initWithIndex:(int)blogIndex {
    if (self = [super init]) {
        [self setIndex:blogIndex];
    }

    return self;
}

- (void)dealloc {
    [super dealloc];
}

#pragma mark -
#pragma mark psudo instance variables

- (UIImage *)favicon {
    NSDictionary *blog = [[BlogDataManager sharedDataManager] blogAtIndex:index];

    UIImage *faviconImage = nil;
    NSString *fileName = [NSString stringWithFormat:@"favicon-%@-%@.png", [blog objectForKey:kBlogHostName], [blog objectForKey:kBlogId]];

    NSLog(@"filename: %@", fileName);

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *faviconFilePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:fileName];

    if ([[NSFileManager defaultManager] fileExistsAtPath:faviconFilePath] == YES) {
        faviconImage = [UIImage imageWithContentsOfFile:faviconFilePath];
    } else {
        NSString *faviconURL = [[NSString alloc] initWithFormat:@"%@/favicon.ico", [blog valueForKey:@"url"]];
        faviconImage = [[UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:faviconURL]]] scaleImageToSize:CGSizeMake(16.0f, 16.0f)];
        [faviconURL release];

        if (faviconImage == NULL) {
            faviconImage = [UIImage imageNamed:@"favicon.ico"];
        }

        [[NSFileManager defaultManager] createFileAtPath:faviconFilePath contents:UIImagePNGRepresentation(faviconImage) attributes:nil];
    }

    return faviconImage;
}

@end
