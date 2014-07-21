#import "Post.h"
#import "NSMutableDictionary+Helpers.h"
#import "ContextManager.h"
#import "WPAvatarSource.h"

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

#pragma mark -

@implementation Post 

@dynamic geolocation, tags, postFormat;
@dynamic categories;
@dynamic authorAvatarURL;
@synthesize specialType;

#pragma mark - NSManagedObject subclass methods

- (void)didTurnIntoFault {
    [super didTurnIntoFault];
    
    self.specialType = nil;
}

#pragma mark -

+ (NSString *const)remoteUniqueIdentifier {
    return @"postid";
}

- (void)updateFromDictionary:(NSDictionary *)postInfo {
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
    if ([postInfo objectForKey:@"wp_author_display_name"]) {
        self.author = [postInfo objectForKey:@"wp_author_display_name"];
    }
    else if ([postInfo objectForKey:@"author"]) {
        NSDictionary *author = [postInfo objectForKey:@"author"];
        self.author = [author objectForKey:@"name"];
        self.authorAvatarURL = [author objectForKey:@"avatar_URL"];
    }
    self.tags           = [postInfo objectForKey:@"mt_keywords"];
	self.permaLink      = [postInfo objectForKey:@"permaLink"];
	self.mt_excerpt		= [postInfo objectForKey:@"mt_excerpt"];
	self.mt_text_more	= [postInfo objectForKey:@"mt_text_more"];
    NSString *wp_more_text = [postInfo objectForKey:@"wp_more_text"];
    if ([wp_more_text length] > 0) {
        wp_more_text = [@" " stringByAppendingString:wp_more_text]; // Give us a little padding.
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
        NSSet *results = [self.blog.categories filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"categoryName = %@", categoryName]];
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

- (BOOL)hasChanged {
    if ([super hasChanged]) {
        return YES;
    }
   
    Post *original = (Post *)self.original;
    if (!original) {
        return NO;
    }
    
    if (([self.tags length] != [original.tags length])
        && (![self.tags isEqual:original.tags])) {
        return YES;
    }
    
    if (self.hasRemote) {
        CLLocationCoordinate2D coord1 = self.geolocation.coordinate;
        CLLocationCoordinate2D coord2 = original.geolocation.coordinate;
        if ((coord1.latitude != coord2.latitude) || (coord1.longitude != coord2.longitude)) {
            return YES;
        }
    }
    
    return NO;
}

- (BOOL)hasSiteSpecificChanges {
    if ([super hasSiteSpecificChanges]) {
        return YES;
    }
    
    Post *original = (Post *)self.original;
    
    if ((self.postFormat != original.postFormat)
        && (![self.postFormat isEqual:original.postFormat])) {
        return YES;
    }
    
    if (![self.categories isEqual:original.categories]) {
        return YES;
    }
    
    return NO;
}

- (BOOL)hasCategories
{
    if ([self.categories count] > 0)
        return true;
    else
        return false;
}

- (BOOL)hasTags
{
    if ([[self.tags trim] length] > 0)
        return true;
    else
        return false;
}

#pragma mark - Avatar

- (UIImage *)cachedAvatarWithSize:(CGSize)size
{
    NSString *hash;
    WPAvatarSourceType type = [self avatarSourceTypeWithHash:&hash];
    if (!hash) {
        return nil;
    }
    return [[WPAvatarSource sharedSource] cachedImageForAvatarHash:hash ofType:type withSize:size];
}

- (void)fetchAvatarWithSize:(CGSize)size success:(void (^)(UIImage *image))success
{
    NSString *hash;
    WPAvatarSourceType type = [self avatarSourceTypeWithHash:&hash];

    if (hash) {
        [[WPAvatarSource sharedSource] fetchImageForAvatarHash:hash ofType:type withSize:size success:success];
    } else if (success) {
        success(nil);
    }
}

- (WPAvatarSourceType)avatarSourceTypeWithHash:(NSString **)hash
{
    if (self.authorAvatarURL) {
        NSURL *avatarURL = [NSURL URLWithString:self.authorAvatarURL];
        if (avatarURL) {
            return [[WPAvatarSource sharedSource] parseURL:avatarURL forAvatarHash:hash];
        }
    }
    return WPAvatarSourceTypeUnknown;
}

#pragma mark - QuickPhoto
- (void)mediaDidUploadSuccessfully:(NSNotification *)notification {
    Media *media = (Media *)[notification object];
    [media save];

    // check if post deleted after media upload started
    if (self.content == nil) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"PostUploadCancelled" object:self];
    } else {
        self.content = [NSString stringWithFormat:@"%@\n\n%@", [media html], self.content];
        [self uploadWithSuccess:nil failure:nil];
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)mediaUploadFailed:(NSNotification *)notification {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Quick Photo Failed", @"")
                                                    message:NSLocalizedString(@"Sorry, the photo upload failed. The post has been saved as a Local Draft.", @"")
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"OK", @"")
                                          otherButtonTitles:nil];
    [alert show];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)uploadWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {
    if ([self hasRemote]) {
        [self editPostWithSuccess:success failure:failure];
    } else {
        [self postPostWithSuccess:success failure:failure];
    }
}

- (Media *)featuredImage {
    if (!self.post_thumbnail) {
        return nil;
    }

    NSArray *arr = [self.blog.media allObjects];
    if ([arr count] == 0) {
        return nil;
    }

    NSUInteger index = [arr indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        if ([((Media *)obj).mediaID isEqualToNumber:self.post_thumbnail] ){
            *stop = YES;
            return YES;
        }
        return NO;
    }];

    if (index == NSNotFound) {
        return nil;
    }

    return [arr objectAtIndex:index];
}

- (void)setFeaturedImage:(Media *)featuredImage {
    self.post_thumbnail = featuredImage.mediaID;
}

@end

@implementation Post (WordPressApi)

- (NSDictionary *)XMLRPCDictionary {
    NSMutableDictionary *postParams = [NSMutableDictionary dictionaryWithDictionary:[super XMLRPCDictionary]];
    
    [postParams setValueIfNotNil:self.postFormat forKey:@"wp_post_format"];
    [postParams setValueIfNotNil:self.tags forKey:@"mt_keywords"];

    if ([self hasRemote] && self.dateCreated == nil) {
        // Change the date of an already published post to the current date/time. (publish immediately)
        // Pass the current date so the post is updated correctly
        [postParams setValue:[NSDate date] forKeyPath:@"date_created_gmt"];
    }

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
    DDLogMethod();
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
                                                                                       if (!self.date_created_gmt) {
                                                                                           // Set the temporary date until we get it from the server so it sorts properly on the list
                                                                                           self.date_created_gmt = [NSDate date];
                                                                                       }
                                                                                       [self save];
                                                                                       [self getPostWithSuccess:success failure:failure];
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
    DDLogMethod();
    NSArray *parameters = [NSArray arrayWithObjects:self.postID, self.blog.username, self.blog.password, nil];
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
    DDLogMethod();
    if (self.postID == nil) {
        if (failure) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Can't edit a post if it's not in the server" forKey:NSLocalizedDescriptionKey];
            NSError *error = [NSError errorWithDomain:@"org.wordpress.iphone" code:0 userInfo:userInfo];
            dispatch_async(dispatch_get_main_queue(), ^{
                failure(error);
            });
        }
        return;
    }

    NSArray *parameters = [NSArray arrayWithObjects:self.postID, self.blog.username, self.blog.password, [self XMLRPCDictionary], nil];
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
                          [self getPostWithSuccess:success failure:failure];
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
    BOOL remote = [self hasRemote];
    if (remote) {
        NSArray *parameters = [NSArray arrayWithObjects:@"unused", self.postID, self.blog.username, self.blog.password, nil];
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
        dispatch_async(dispatch_get_main_queue(), ^{
            success();
        });
    }
}

@end