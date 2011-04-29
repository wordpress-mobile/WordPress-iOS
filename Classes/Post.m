// 
//  Post.m
//  WordPress
//
//  Created by Chris Boyd on 8/9/10.
//

#import "Post.h"
#import "WPDataController.h"

@interface Post(PrivateMethods)
+ (Post *)newPostForBlog:(Blog *)blog;
- (void)uploadInBackground;
- (void)didUploadInBackground;
- (void)failedUploadInBackground;
@end

@implementation Post 

@dynamic geolocation, tags;
@dynamic latitudeID, longitudeID, publicID;
@dynamic categories;
@synthesize specialType;

- (void)dealloc {
    self.specialType = nil;
    [super dealloc];
}

+ (Post *)newPostForBlog:(Blog *)blog {
    Post *post = [[Post alloc] initWithEntity:[NSEntityDescription entityForName:@"Post"
                                                          inManagedObjectContext:[blog managedObjectContext]]
               insertIntoManagedObjectContext:[blog managedObjectContext]];

    post.blog = blog;
    
    return post;
}

+ (Post *)newDraftForBlog:(Blog *)blog {
    Post *post = [self newPostForBlog:blog];
    post.remoteStatus = AbstractPostRemoteStatusLocal;
    post.status = @"publish";
    [post save];
    
    return post;
}

+ (Post *)findWithBlog:(Blog *)blog andPostID:(NSNumber *)postID {
    NSSet *results = [blog.posts filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"postID == %@ AND original == NULL",postID]];
    
    if (results && (results.count > 0)) {
        return [[results allObjects] objectAtIndex:0];
    }
    return nil;
}

+ (Post *)createOrReplaceFromDictionary:(NSDictionary *)postInfo forBlog:(Blog *)blog {
    Post *post = [self findWithBlog:blog andPostID:[[postInfo objectForKey:@"postid"] numericValue]];
    
    if (post == nil) {
        post = [[Post newPostForBlog:blog] autorelease];
    }
 	[post updateFromDictionary:postInfo];
    [post findComments];
    return post;
}

- (void )updateFromDictionary:(NSDictionary *)postInfo {
    self.postTitle      = [postInfo objectForKey:@"title"];
	//keep attention: getPosts and getPost returning IDs in different types
	if ([[postInfo objectForKey:@"postid"] isKindOfClass:[NSString class]]) {
	  self.postID         = [[postInfo objectForKey:@"postid"] numericValue];
	} else {
	  self.postID         = [postInfo objectForKey:@"postid"];
	}
      
	self.content        = [postInfo objectForKey:@"description"];
    self.date_created_gmt    = [postInfo objectForKey:@"date_created_gmt"];
    self.status         = [postInfo objectForKey:@"post_status"];
    self.password       = [postInfo objectForKey:@"wp_password"];
    self.tags           = [postInfo objectForKey:@"mt_keywords"];
	self.permaLink      = [postInfo objectForKey:@"permaLink"];
	self.mt_excerpt		= [postInfo objectForKey:@"mt_excerpt"];
	self.mt_text_more	= [postInfo objectForKey:@"mt_text_more"];
	self.wp_slug		= [postInfo objectForKey:@"wp_slug"];
	
    self.remoteStatus   = AbstractPostRemoteStatusSync;
    if ([postInfo objectForKey:@"categories"]) {
        [self setCategoriesFromNames:[postInfo objectForKey:@"categories"]];
    }

	self.latitudeID = nil;
	self.longitudeID = nil;
	self.publicID = nil;
	
	if ([postInfo objectForKey:@"custom_fields"]) {
		NSArray *customFields = [postInfo objectForKey:@"custom_fields"];
		NSString *geo_longitude = nil;
		NSString *geo_latitude = nil;
		NSString *geo_longitude_id = nil;
		NSString *geo_latitude_id = nil;
		NSString *geo_public_id = nil;
		for (NSDictionary *customField in customFields) {
			NSString *ID = [customField objectForKey:@"id"];
			NSString *key = [customField objectForKey:@"key"];
			NSString *value = [customField objectForKey:@"value"];

			if (key) {
				if ([key isEqualToString:@"geo_longitude"]) {
					geo_longitude = value;
					geo_longitude_id = ID;
				} else if ([key isEqualToString:@"geo_latitude"]) {
					geo_latitude = value;
					geo_latitude_id = ID;
				} else if ([key isEqualToString:@"geo_public"]) {
					geo_public_id = ID;
				}
			}
		}
		
		if (geo_latitude && geo_longitude) {
			CLLocationCoordinate2D coord;
			coord.latitude = [geo_latitude doubleValue];
			coord.longitude = [geo_longitude doubleValue];
			Coordinate *c = [[Coordinate alloc] initWithCoordinate:coord];
			self.geolocation = c;
			self.latitudeID = geo_latitude_id;
			self.longitudeID = geo_longitude_id;
			self.publicID = geo_public_id;
			[c release];
		}
	}
	return;   
}

- (BOOL)removeWithError:(NSError **)error {
	BOOL res = NO;
    if ([self hasRemote]) {
		WPDataController *dc = [[WPDataController alloc] init];
		[dc  mwDeletePost:self];
		
		if(dc.error) {
			if (error != nil) 
				*error = dc.error;
			WPLog(@"Error while deleting post: %@", [dc.error localizedDescription]);
		} 
		//even if there was an error on the XML-RPC call we should always delete post from coredata
		//and inform the user about that error.
		//Wheter the post is still on the server it will be downloaded again when list is refreshed. 
		//Otherwise if someone has deleted a post on the server, you can't get rid of it
		//there are other approach to solve this internally in the app, but i think this is the easiest one.
		res = YES; //the post doesn't exist anymore on the server. we can return YES even if there are errors deleting it from db
		[super removeWithError:nil]; 
		//}
		[dc release];
	} else {
		//we should remove the post from the db even if it is a "LocalDraft"
		res = [super removeWithError:nil]; 
	}
	return res;
}

- (void)uploadInBackground {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    if ([self hasRemote]) {
        if ([[WPDataController sharedInstance] mwEditPost:self]) {
			[[WPDataController sharedInstance] updateSinglePost:self];
            self.remoteStatus = AbstractPostRemoteStatusSync;
			[self performSelectorOnMainThread:@selector(didUploadInBackground) withObject:nil waitUntilDone:NO];
        } else {
            NSLog(@"Post update failed");
            self.remoteStatus = AbstractPostRemoteStatusFailed;
            [self performSelectorOnMainThread:@selector(failedUploadInBackground) withObject:nil waitUntilDone:NO];
        }
    } else {
        int postID = [[WPDataController sharedInstance] mwNewPost:self];
        if (postID == -1) {
            NSLog(@"Post upload failed");
            self.remoteStatus = AbstractPostRemoteStatusFailed;
            [self performSelectorOnMainThread:@selector(failedUploadInBackground) withObject:nil waitUntilDone:NO];
        } else {
            self.postID = [NSNumber numberWithInt:postID];          
            [[WPDataController sharedInstance] updateSinglePost:self];
			self.remoteStatus = AbstractPostRemoteStatusSync;
			[self performSelectorOnMainThread:@selector(didUploadInBackground) withObject:nil waitUntilDone:NO];
        }
    }
    [self save];

    [pool release];
}

- (void)didUploadInBackground {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"PostUploaded" object:self];
}

- (void)failedUploadInBackground {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"PostUploadFailed" object:self];
}

- (void)upload {
    if ([self.password isEmpty])
        self.password = nil;

    [super upload];
    [self save];

    self.remoteStatus = AbstractPostRemoteStatusPushing;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [self performSelectorInBackground:@selector(uploadInBackground) withObject:nil];
}

- (void)autosave {
    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {
        // We better not crash on autosave
        WPFLog(@"[Autosave] Unresolved Core Data Save error %@, %@", error, [error userInfo]);
        [FlurryAPI logError:@"Autosave" message:[error localizedDescription] error:error];
    }
}

- (NSString *)categoriesText {
    return [[[self.categories valueForKey:@"categoryName"] allObjects] componentsJoinedByString:@", "];
}

- (void)setCategoriesFromNames:(NSArray *)categoryNames {
    [self.categories removeAllObjects];
	NSMutableSet *categories = nil;
	
    for (NSString *categoryName in categoryNames) {
        NSSet *results = [self.blog.categories filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"categoryName like %@", categoryName]];
        if (results && (results.count > 0)) {
			if(categories == nil) {
				categories = [NSMutableSet setWithSet:results];
			} else {
				[categories unionSet:results];
			}
		}
    }
	
	if (categories && (categories.count > 0)) {
		self.categories = categories;
	}
}

- (BOOL)hasChanges {
    if ([super hasChanges]) return YES;

    if ((self.tags != ((Post *)self.original).tags)
        && (![self.tags isEqual:((Post *)self.original).tags]))
        return YES;

    if (![self.categories isEqual:((Post *)self.original).categories]) return YES;
	
	if ((self.geolocation != ((Post *)self.original).geolocation)
		 && (![self.geolocation isEqual:((Post *)self.original).geolocation]) )
        return YES;

    return NO;
}

@end
