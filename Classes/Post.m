// 
//  Post.m
//  WordPress
//
//  Created by Chris Boyd on 8/9/10.
//

#import "Post.h"
#import "NSMutableDictionary+Helpers.h"

@interface Post(InternalProperties)
// We shouldn't need to store this, but if we don't send IDs on edits
// custom fields get duplicated and stop working
@property (nonatomic, retain) NSString *latitudeID;
@property (nonatomic, retain) NSString *longitudeID;
@property (nonatomic, retain) NSString *publicID;
@end

@implementation Post(InternalProperties)
@dynamic latitudeID, longitudeID, publicID;
@end

#pragma mark -

@interface AbstractPost (WordPressApi)
- (NSDictionary *)XMLRPCDictionary;
@end

@interface Post (WordPressApi)
- (NSDictionary *)XMLRPCDictionary;
- (void)postPostWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure;
- (void)getPostWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure;
- (void)editPostWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure;
- (void)deletePostWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure;
@end


@interface Post(PrivateMethods)
+ (Post *)newPostForBlog:(Blog *)blog;
- (void)uploadInBackground;
- (void)didUploadInBackground;
- (void)failedUploadInBackground;
@end

#pragma mark -

@implementation Post 

@dynamic geolocation, tags, postFormat;
@dynamic categories;
@synthesize specialType, featuredImageURL;

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

+ (Post *)findOrCreateWithBlog:(Blog *)blog andPostID:(NSNumber *)postID {
    Post *post = [self findWithBlog:blog andPostID:postID];

    if (post == nil) {
        post = [Post newDraftForBlog:blog];
        post.postID = postID;
    }
    [post findComments];
    return post;
}

- (id)init {
    if (self = [super init]) {
        appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
    }
    
    return self;
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
    if ([[postInfo objectForKey:@"date_created_gmt"] isKindOfClass:[NSDate class]]) {
        self.date_created_gmt    = [postInfo objectForKey:@"date_created_gmt"];
    } else {
        self.dateCreated = [postInfo objectForKey:@"dateCreated"];
    }
    self.status         = [postInfo objectForKey:@"post_status"];
    NSString *password = [postInfo objectForKey:@"wp_password"];
    if ([password isEqualToString:@""]) {
        password = nil;
    }
    self.password = password;
    self.tags           = [postInfo objectForKey:@"mt_keywords"];
	self.permaLink      = [postInfo objectForKey:@"permaLink"];
	self.mt_excerpt		= [postInfo objectForKey:@"mt_excerpt"];
	self.mt_text_more	= [postInfo objectForKey:@"mt_text_more"];
    NSString *wp_more_text = [postInfo objectForKey:@"wp_more_text"];
    if ([wp_more_text length] > 0) {
        wp_more_text = [@" " stringByAppendingFormat:wp_more_text]; // Give us a little padding.
    }
    if (self.mt_text_more && self.mt_text_more.length > 0) {
        self.content = [NSString stringWithFormat:@"%@\n\n<!--more%@-->\n\n%@", self.content, wp_more_text, self.mt_text_more];
        self.mt_text_more = nil;
    }
	self.wp_slug		= [postInfo objectForKey:@"wp_slug"];
	self.post_thumbnail = [[postInfo objectForKey:@"wp_post_thumbnail"] numericValue];
    if (self.post_thumbnail != nil && [self.post_thumbnail intValue] == 0)
        self.post_thumbnail = nil;
	self.postFormat		= [postInfo objectForKey:@"wp_post_format"];
	
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
		}
	}
	return;   
}

- (NSString *)categoriesText {
    return [[[self.categories valueForKey:@"categoryName"] allObjects] componentsJoinedByString:@", "];
}

- (NSString *)postFormatText {
    NSDictionary *allFormats = self.blog.postFormats;
    NSString *formatText = self.postFormat;
    if ([allFormats objectForKey:self.postFormat]) {
        formatText = [allFormats objectForKey:self.postFormat];
    }
    if ((formatText == nil || [formatText isEqualToString:@""]) && [allFormats objectForKey:@"standard"]) {
        formatText = [allFormats objectForKey:@"standard"];
    }
    return formatText;
}

- (void)setPostFormatText:(NSString *)postFormatText {
    __block NSString *format = nil;
    [self.blog.postFormats enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([obj isEqual:postFormatText]) {
            format = (NSString *)key;
            *stop = YES;
        }
    }];
    self.postFormat = format;
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
    
    if ((self.postFormat != ((Post *)self.original).postFormat)
        && (![self.postFormat isEqual:((Post *)self.original).postFormat]))
        return YES;

    if (![self.categories isEqual:((Post *)self.original).categories]) return YES;
    
	if ((self.geolocation != ((Post *)self.original).geolocation)
		 && (![self.geolocation isEqual:((Post *)self.original).geolocation]) )
        return YES;

    return NO;
}

#pragma mark - QuickPhoto
- (void)mediaDidUploadSuccessfully:(NSNotification *)notification {
    Media *media = (Media *)[notification object];
    [media save];

    // check if post deleted after media upload started
    if (self.content == nil) {
        appDelegate.isUploadingPost = NO;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"PostUploadCancelled" object:self];
    } else {
        self.content = [NSString stringWithFormat:@"%@\n\n%@", [media html], self.content];
        [self uploadWithSuccess:nil failure:nil];
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)mediaUploadFailed:(NSNotification *)notification {
    appDelegate.isUploadingPost = NO;

    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Quick Photo Failed", @"")
                                                    message:NSLocalizedString(@"Sorry, the photo upload failed. The post has been saved as a Local Draft.", @"")
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"OK", @"")
                                          otherButtonTitles:nil];
    [alert show];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)uploadWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {    
    [self save];
    
    if ([self hasRemote]) {
        [self editPostWithSuccess:success failure:failure];
    } else {
        [self postPostWithSuccess:success failure:failure];
    }
}

- (void)getFeaturedImageURLWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {
    WPFLogMethod();
    NSArray *parameters = [NSArray arrayWithObjects:self.blog.blogID, self.blog.username, [self.blog fetchPassword], self.post_thumbnail, nil];
    [self.blog.api callMethod:@"wp.getMediaItem"
                   parameters:parameters
                      success:^(AFHTTPRequestOperation *operation, id responseObject) {
                          NSDictionary *mediaItem = (NSDictionary *)responseObject;
                          self.featuredImageURL = [mediaItem objectForKey:@"link"];
                          if (success) success();
                      } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                          if (failure) {
                              failure(error);
                          }
                      }];
}

@end

@implementation Post (WordPressApi)

- (NSDictionary *)XMLRPCDictionary {
    NSMutableDictionary *postParams = [NSMutableDictionary dictionaryWithDictionary:[super XMLRPCDictionary]];
    
    [postParams setValueIfNotNil:self.postFormat forKey:@"wp_post_format"];
    [postParams setValueIfNotNil:self.tags forKey:@"mt_keywords"];

    if ([self valueForKey:@"categories"] != nil) {
        NSMutableSet *categories = [self mutableSetValueForKey:@"categories"];
        NSMutableArray *categoryNames = [NSMutableArray arrayWithCapacity:[categories count]];
        for (Category *cat in categories) {
            [categoryNames addObject:cat.categoryName];
        }
        [postParams setObject:categoryNames forKey:@"categories"];
    }
    Coordinate *c = [self valueForKey:@"geolocation"];
    // Warning
    // XMLRPCEncoder sends floats with an integer type (i4), so WordPress ignores the decimal part
    // We send coordinates as strings to avoid that
    NSMutableArray *customFields = [NSMutableArray array];
    NSMutableDictionary *latitudeField = [NSMutableDictionary dictionaryWithCapacity:3];
    NSMutableDictionary *longitudeField = [NSMutableDictionary dictionaryWithCapacity:3];
    NSMutableDictionary *publicField = [NSMutableDictionary dictionaryWithCapacity:3];
    if (c != nil) {
        [latitudeField setValue:@"geo_latitude" forKey:@"key"];
        [latitudeField setValue:[NSString stringWithFormat:@"%f", c.latitude] forKey:@"value"];
        [longitudeField setValue:@"geo_longitude" forKey:@"key"];
        [longitudeField setValue:[NSString stringWithFormat:@"%f", c.longitude] forKey:@"value"];
        [publicField setValue:@"geo_public" forKey:@"key"];
        [publicField setValue:@"1" forKey:@"value"];
    }
    if ([self valueForKey:@"latitudeID"]) {
        [latitudeField setValue:[self valueForKey:@"latitudeID"] forKey:@"id"];
    }
    if ([self valueForKey:@"longitudeID"]) {
        [longitudeField setValue:[self valueForKey:@"longitudeID"] forKey:@"id"];
    }
    if ([self valueForKey:@"publicID"]) {
        [publicField setValue:[self valueForKey:@"publicID"] forKey:@"id"];
    }
    if ([latitudeField count] > 0) {
        [customFields addObject:latitudeField];
    }
    if ([longitudeField count] > 0) {
        [customFields addObject:longitudeField];
    }
    if ([publicField count] > 0) {
        [customFields addObject:publicField];
    }
    
    if ([customFields count] > 0) {
        [postParams setObject:customFields forKey:@"custom_fields"];
    }
	
    if (self.status == nil)
        self.status = @"publish";
    [postParams setObject:self.status forKey:@"post_status"];
    
    return postParams;
}

- (void)postPostWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {
    WPFLogMethod();
    // XML-RPC doesn't like empty post thumbnail ID's for new posts, but it's required to delete them on edit. see #1395 and #1507
    NSMutableDictionary *xmlrpcDictionary = [NSMutableDictionary dictionaryWithDictionary:[self XMLRPCDictionary]];
    if ([[xmlrpcDictionary objectForKey:@"wp_post_thumbnail"] isEqual:@""]) {
        [xmlrpcDictionary removeObjectForKey:@"wp_post_thumbnail"];
    }
    NSArray *parameters = [self.blog getXMLRPCArgsWithExtra:xmlrpcDictionary];
    self.remoteStatus = AbstractPostRemoteStatusPushing;

    NSMutableURLRequest *request = [self.blog.api requestWithMethod:@"metaWeblog.newPost"
                                                  parameters:parameters];
    if (self.specialType != nil) {
        [request addValue:self.specialType forHTTPHeaderField:@"WP-Quick-Post"];
    }
    AFHTTPRequestOperation *operation = [self.blog.api HTTPRequestOperationWithRequest:request
                                                                               success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                                                                   if ([self isDeleted] || self.managedObjectContext == nil)
                                                                                       return;

                                                                                   if ([responseObject respondsToSelector:@selector(numericValue)]) {
                                                                                       self.postID = [responseObject numericValue];
                                                                                       self.remoteStatus = AbstractPostRemoteStatusSync;
                                                                                       // Set the temporary date until we get it from the server so it sorts properly on the list
                                                                                       self.date_created_gmt = [DateUtils localDateToGMTDate:[NSDate date]];
                                                                                       [self save];
                                                                                       [self getPostWithSuccess:nil failure:nil];
                                                                                       if (success) success();
                                                                                       [[NSNotificationCenter defaultCenter] postNotificationName:@"PostUploaded" object:self];
                                                                                   } else if (failure) {
                                                                                       self.remoteStatus = AbstractPostRemoteStatusFailed;
                                                                                       NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Invalid value returned for new post: %@", responseObject] forKey:NSLocalizedDescriptionKey];
                                                                                       NSError *error = [NSError errorWithDomain:@"org.wordpress.iphone" code:0 userInfo:userInfo];
                                                                                       failure(error);
                                                                                       [[NSNotificationCenter defaultCenter] postNotificationName:@"PostUploadFailed" object:self];
                                                                                   }

                                                                               } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                                                                   if ([self isDeleted] || self.managedObjectContext == nil)
                                                                                       return;

                                                                                   self.remoteStatus = AbstractPostRemoteStatusFailed;
                                                                                   if (failure) failure(error);
                                                                                   [[NSNotificationCenter defaultCenter] postNotificationName:@"PostUploadFailed" object:self];
                                                                               }];
    [self.blog.api enqueueHTTPRequestOperation:operation];
}

- (void)getPostWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {
    WPFLogMethod();
    NSArray *parameters = [NSArray arrayWithObjects:self.postID, self.blog.username, [self.blog fetchPassword], nil];
    [self.blog.api callMethod:@"metaWeblog.getPost"
                   parameters:parameters
                      success:^(AFHTTPRequestOperation *operation, id responseObject) {
                          if ([self isDeleted] || self.managedObjectContext == nil)
                              return;

                          [self updateFromDictionary:responseObject];
                          [self save];
                          if (success) success();
                      } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                          if (failure) {
                              failure(error);
                          }
                      }];
}

- (void)editPostWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {
    WPFLogMethod();
    if (self.postID == nil) {
        if (failure) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Can't edit a post if it's not in the server" forKey:NSLocalizedDescriptionKey];
            NSError *error = [NSError errorWithDomain:@"org.wordpress.iphone" code:0 userInfo:userInfo];
            failure(error);
        }
        return;
    }

    NSArray *parameters = [NSArray arrayWithObjects:self.postID, self.blog.username, [self.blog fetchPassword], [self XMLRPCDictionary], nil];
    self.remoteStatus = AbstractPostRemoteStatusPushing;
    
    if( self.isFeaturedImageChanged == NO ) {
        NSMutableDictionary *xmlrpcDictionary = (NSMutableDictionary*) [parameters objectAtIndex:3] ;
        [xmlrpcDictionary removeObjectForKey:@"wp_post_thumbnail"];
    }
    
    [self.blog.api callMethod:@"metaWeblog.editPost"
                   parameters:parameters
                      success:^(AFHTTPRequestOperation *operation, id responseObject) {
                          if ([self isDeleted] || self.managedObjectContext == nil)
                              return;

                          self.remoteStatus = AbstractPostRemoteStatusSync;
                          [self getPostWithSuccess:nil failure:nil];
                          if (success) success();
                          [[NSNotificationCenter defaultCenter] postNotificationName:@"PostUploaded" object:self];
                      } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                          if ([self isDeleted] || self.managedObjectContext == nil)
                              return;

                          self.remoteStatus = AbstractPostRemoteStatusFailed;
                          if (failure) failure(error);
                          [[NSNotificationCenter defaultCenter] postNotificationName:@"PostUploadFailed" object:self];
                      }];
}

- (void)deletePostWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {
    WPFLogMethod();
    BOOL remote = [self hasRemote];
    if (remote) {
        NSArray *parameters = [NSArray arrayWithObjects:@"unused", self.postID, self.blog.username, [self.blog fetchPassword], nil];
        [self.blog.api callMethod:@"metaWeblog.deletePost"
                       parameters:parameters
                          success:^(AFHTTPRequestOperation *operation, id responseObject) {
                              if (success) success();
                          } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                              if (failure) failure(error);
                          }];
    }
    [self remove];
    if (!remote && success) {
        success();
    }
}

@end