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
@dynamic blogID, blogName, url, username, password, xmlrpc;
@dynamic isAdmin;

#pragma mark -
#pragma mark Custom methods

+ (BOOL)blogExistsForURL:(NSString *)theURL withContext:(NSManagedObjectContext *)moc {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Blog"
                                        inManagedObjectContext:moc]];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"url like %@", theURL]];
    NSError *error = nil;
    NSArray *results = [moc executeFetchRequest:fetchRequest error:&error];
    [fetchRequest release]; fetchRequest = nil;

    return (results.count > 0);
}

+ (Blog *)createFromDictionary:(NSDictionary *)blogInfo withContext:(NSManagedObjectContext *)moc {
    Blog *blog = nil;
    NSString *blogUrl = [[blogInfo objectForKey:@"url"] stringByReplacingOccurrencesOfString:@"http://" withString:@""];
	if([blogUrl hasSuffix:@"/"])
		blogUrl = [blogUrl substringToIndex:blogUrl.length-1];
	blogUrl= [blogUrl stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

    if (![self blogExistsForURL:blogUrl withContext:moc]) {
        blog = [[[Blog alloc] initWithEntity:[NSEntityDescription entityForName:@"Blog"
                                                              inManagedObjectContext:moc]
             insertIntoManagedObjectContext:moc] autorelease];

        blog.url = blogUrl;
        blog.blogID = [NSNumber numberWithInt:[[blogInfo objectForKey:@"blogid"] intValue]];
        blog.blogName = [blogInfo objectForKey:@"blogName"];
		blog.xmlrpc = [blogInfo objectForKey:@"xmlrpc"];
        blog.username = [blogInfo objectForKey:@"username"];
        blog.isAdmin = [NSNumber numberWithInt:[[blogInfo objectForKey:@"isAdmin"] intValue]];

        NSError *error = nil;
        [SFHFKeychainUtils storeUsername:[blogInfo objectForKey:@"username"]
                             andPassword:[blogInfo objectForKey:@"password"]
                          forServiceName:blog.url
                          updateExisting:TRUE
                                   error:&error ];
        // TODO: save blog settings
	}
    return blog;
}

+ (NSInteger)countWithContext:(NSManagedObjectContext *)moc {
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:@"Blog" inManagedObjectContext:moc]];
    [request setIncludesSubentities:NO];

    NSError *err;
    NSUInteger count = [moc countForFetchRequest:request error:&err];
    [request release];
    if(count == NSNotFound) {
        count = 0;
    }
    return count;
}

- (UIImage *)favicon {
    UIImage *faviconImage = nil;
    NSString *fileName = [NSString stringWithFormat:@"favicon-%@-%@.png", self.hostURL, self.blogID];
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
	
	NSString *faviconURL = [NSString stringWithFormat:@"%@/favicon.ico", self.url];
	if(![faviconURL hasPrefix:@"http"])
		faviconURL = [NSString stringWithFormat:@"http://%@", faviconURL];
	
    NSString *fileName = [NSString stringWithFormat:@"favicon-%@-%@.png", self.blogName, self.blogID];
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

- (NSString *)hostURL {
    NSString *result = [NSString stringWithFormat:@"%@",
                         [self.url stringByReplacingOccurrencesOfRegex:@"http(s?)://" withString:@""]];

    if([result hasSuffix:@"/"])
        result = [result substringToIndex:[result length] - 1];

    return result;
}

- (BOOL)isWPcom {
    NSRange range = [self.url rangeOfString:@"wordpress.com"];
	return (range.location != NSNotFound);
}

#pragma mark -
#pragma mark Dealloc

- (void)dealloc {
    [super dealloc];
}

@end
