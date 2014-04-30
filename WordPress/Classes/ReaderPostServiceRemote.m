#import "ReaderPostServiceRemote.h"
#import "WordPressComApi.h"
#import "DateUtils.h"

@interface ReaderPostServiceRemote ()

@property (nonatomic, strong) WordPressComApi *api;

@end

@implementation ReaderPostServiceRemote

- (id)initWithRemoteApi:(WordPressComApi *)api {
    self = [super init];
    if (self) {
        _api = api;
    }

    return self;
}

- (void)fetchPostsFromEndpoint:(NSURL *)endpoint
                         count:(NSUInteger)count
                       success:(void (^)(NSArray *posts))success
                       failure:(void (^)(NSError *error))failure {

    NSNumber *numberToFetch = [NSNumber numberWithInteger:count];
    NSDictionary *params = @{@"number":numberToFetch};

    [self fetchPostsFromEndpoint:endpoint withParameters:params success:success failure:failure];
}


- (void)fetchPostsFromEndpoint:(NSURL *)endpoint
                         count:(NSUInteger)count
                         after:(NSDate *)date
                       success:(void (^)(NSArray *posts))success
                       failure:(void (^)(NSError *error))failure {

    NSNumber *numberToFetch = [NSNumber numberWithInteger:count];
    NSDictionary *params = @{@"number":numberToFetch,
                             @"after": [DateUtils isoStringFromDate:date],
                             @"order": @"ASC"
                             };

    [self fetchPostsFromEndpoint:endpoint withParameters:params success:success failure:failure];
}

- (void)fetchPostsFromEndpoint:(NSURL *)endpoint
                         count:(NSUInteger)count
                        before:(NSDate *)date
                       success:(void (^)(NSArray *posts))success
                       failure:(void (^)(NSError *error))failure {

    NSNumber *numberToFetch = [NSNumber numberWithInteger:count];
    NSDictionary *params = @{@"number":numberToFetch,
                             @"before": [DateUtils isoStringFromDate:date],
                             @"order": @"DESC"
                             };

    [self fetchPostsFromEndpoint:endpoint withParameters:params success:success failure:failure];
}

- (void)fetchPost:(NSUInteger)postID
         fromSite:(NSUInteger)siteID
          success:(void (^)(NSDictionary *post))success
          failure:(void (^)(NSError *error))failure {

    NSString *path = [NSString stringWithFormat:@"sites/%@/posts/%@/?meta=site", siteID, postID];
    [self.api getPath:path
           parameters:nil
              success:^(AFHTTPRequestOperation *operation, id responseObject) {
                  if (!success) {
                      return;
                  }

                  NSDictionary *dict = [self formatPostDictionary:(NSDictionary *)responseObject];
                  success(dict);

              } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                  if (failure) {
                      failure(error);
                  }
              }];
}

- (void)likePost:(NSUInteger)postID forSite:(NSUInteger)siteID success:(void (^)())success failure:(void (^)(NSError *error))failure {
    NSString *path = [NSString stringWithFormat:@"sites/%d/posts/%d/likes/new", siteID, postID];
    [self.api postPath:path parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success();
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

- (void)unlikePost:(NSUInteger)postID forSite:(NSUInteger)siteID success:(void (^)())success failure:(void (^)(NSError *error))failure {
    NSString *path = [NSString stringWithFormat:@"sites/%@/posts/%@/likes/mine/delete", siteID, postID];
    [self.api postPath:path parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success();
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

- (void)followSite:(NSUInteger)siteID success:(void (^)())success failure:(void(^)(NSError *error))failure {
    NSString *path = [NSString stringWithFormat:@"sites/%d/follows/new", siteID];
    [self.api postPath:path parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success();
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

- (void)unfollowSite:(NSUInteger)siteID success:(void (^)())success failure:(void(^)(NSError *error))failure {
    NSString *path = [NSString stringWithFormat:@"sites/%d/follows/mine/delete", siteID];
    [self.api postPath:path parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success();
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

- (void)reblogPost:(NSUInteger)postID fromSite:(NSUInteger)siteID toSite:(NSUInteger)targetSiteID note:(NSString *)note success:(void (^)(BOOL isReblogged))success failure:(void (^)(NSError *error))failure {
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObject:[NSNumber numberWithInteger:targetSiteID] forKey:@"destination_site_id"];

    if ([note length] > 0) {
        [params setObject:note forKey:@"note"];
    }

    NSString *path = [NSString stringWithFormat:@"sites/%d/posts/%d/reblogs/new", siteID, postID];
    [self.api postPath:path parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            NSDictionary *dict = (NSDictionary *)responseObject;
            BOOL isReblogged = [[dict numberForKey:@"is_reblogged"] boolValue];
            success(isReblogged);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

#pragma mark - Private Methods

/**
 Fetches the posts from the specified remote endpoint

 @param params A dictionary of parameters supported by the endpoint. Params are converted to the request's query string.
 @param success block called on a successful fetch.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)fetchPostsFromEndpoint:(NSURL *)endpoint
                    withParameters:(NSDictionary *)params
                           success:(void (^)(NSArray *posts))success
                           failure:(void (^)(NSError *))failure {


    [self.api getPath:[endpoint absoluteString]
           parameters:params
              success:^(AFHTTPRequestOperation *operation, id responseObject) {
                  if (!success) {
                      return;
                  }

                  NSArray *arr = [responseObject arrayForKey:@"posts"];
                  NSMutableArray *posts = [NSMutableArray array];
                  for (NSDictionary *dict in arr) {
                      [posts addObject:[self formatPostDictionary:dict]];
                  }
                  success(posts);

              } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                  if (failure) {
                      failure(error);
                  }
              }];
}

/**
 Sanitizes a post object from the REST API.
 
 @param dict A dictionary representing a post object from the REST API
 @return A dictionary with keys matching what is expected by the LocalService
 */
- (NSDictionary *)formatPostDictionary:(NSDictionary *)dict {

    NSMutableDictionary *post = [NSMutableDictionary dictionary];
    NSDictionary *authorDict = [dict dictionaryForKey:@"author"];

    [post setObject:[self stringOrEmptyString:[authorDict stringForKey:@"nice_name"]] forKey:@"author"]; // typically the author's screen name
    [post setObject:[self stringOrEmptyString:[authorDict stringForKey:@"avatar_URL"]] forKey:@"authorAvatarURL"];
    [post setObject:[self stringOrEmptyString:[authorDict stringForKey:@"name"]] forKey:@"authorDisplayName"]; // Typically the author's given name
    [post setObject:[self authorEmailFromAuthorDictionary:authorDict] forKey:@"authorEmail"];
    [post setObject:[self stringOrEmptyString:[authorDict stringForKey:@"URL"]] forKey:@"authorURL"];
    [post setObject:[self siteNameFromPostDictionary:dict] forKey:@"blogName"];
    [post setObject:[self siteURLFromPostDictionary:dict] forKey:@"blogURL"];
    [post setObject:[dict numberForKey:@"comment_count"] forKey:@"commentCount"];
    [post setObject:[dict numberForKey:@"comments_open"] forKey:@"commentsOpen"];
    [post setObject:[self stringOrEmptyString:[dict stringForKey:@"content"]] forKey:@"content"];
    [post setObject:[self stringOrEmptyString:[dict stringForKey:@"date"]] forKey:@"date_created_gmt"];
    [post setObject:[self featuredImageFromPostDictionary:dict] forKey:@"featuredImage"];
    [post setObject:[self stringOrEmptyString:[dict stringForKey:@"global_ID"]] forKey:@"globalID"];
    [post setObject:[self siteIsPrivateFromPostDictionary:dict] forKey:@"isBlogPrivate"];
    [post setObject:[dict numberForKey:@"is_following"] forKey:@"isFollowing"];
    [post setObject:[dict numberForKey:@"i_like"] forKey:@"isLiked"];
    [post setObject:[dict numberForKey:@"is_reblogged"] forKey:@"isReblogged"];
    [post setObject:[self isWPComFromPostDictionary:dict] forKey:@"isWPCom"];
    [post setObject:[dict numberForKey:@"like_count"] forKey:@"likeCount"];
    [post setObject:[self stringOrEmptyString:[dict stringForKey:@"URL"]] forKey:@"permaLink"];
    [post setObject:[dict numberForKey:@"ID"] forKey:@"postID"];
    [post setObject:[self stringOrEmptyString:[dict stringForKey:@"title"]] forKey:@"postTitle"];
    [post setObject:[dict numberForKey:@"site_ID"] forKey:@"siteID"];
    [post setObject:[self sortDateFromPostDictionary:dict] forKey:@"sortDate"];
    [post setObject:[self stringOrEmptyString:[dict stringForKey:@"status"]] forKey:@"status"];
    [post setObject:[self stringOrEmptyString:[dict stringForKey:@"excerpt"]] forKey:@"summary"];
    [post setObject:[self tagsFromPostDictionary:dict] forKey:@"tags"];

    return post;
}

#pragma mark - Utils

/**
 Checks the value of the string passed. If the string is nil, an empty string is returned.
 
 @param str The string to check for nil.
 @ Returns the string passed if it was not nil, or an empty string if the value passed was nil.
 */
- (NSString *)stringOrEmptyString:(NSString *)str {
    if (!str) {
        return @"";
    }
    return str;
}

/**
 Format a featured image url into an expected format. 

 @param img The URL path to the featured image.
 @return A sanitized URL.
 */
- (NSString *)sanitizeFeaturedImageString:(NSString *)img {

    NSRange rng = [img rangeOfString:@"mshots/"];
    if (NSNotFound != rng.location) {
        // MShots are sceen caps of the actual site. There URLs look like this:
        // https://s0.wp.com/mshots/v1/http%3A%2F%2Fsitename.wordpress.com%2F2013%2F05%2F13%2Fr-i-p-mom%2F?w=252
        // We want the URL but not the size info in the query string.
        rng = [img rangeOfString:@"?" options:NSBackwardsSearch];
        img = [img substringWithRange:NSMakeRange(0, rng.location)];
    } else if (NSNotFound != [img rangeOfString:@"imgpress"].location) {
        // ImagePress urls look like this:
        // https://s0.wp.com/imgpress?resize=252%2C160&url=http%3A%2F%2Fsitename.files.wordpress.com%2F2014%2F04%2Fimage-name.jpg&unsharpmask=80,0.5,3
        // We want the URL of the image being sent to ImagePress without all the ImagePress stuff
        NSRange rng;
        rng.location = [img rangeOfString:@"http" options:NSBackwardsSearch].location; // the beginning of the image URL
        rng.length = [img rangeOfString:@"&unsharp" options:NSBackwardsSearch].location - rng.location; // ImagePress filters.
        img = [img substringWithRange:rng];

        // Actually decode twice to remove the encodings
        img = [img stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        img = [img stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

        // Remove the protocol. We'll specify http or https when used.
        img = [self removeProtocolFromPath:img];
    } else {
        img = [self removeProtocolFromPath:img];
    }
    return img;
}

/** 
 Strip the protocol from the beginning of an image path
 
 @param img The image URL.
 @return A string of the image url with the protocol removed.
 */
- (NSString *)removeProtocolFromPath:(NSString *)imagePath {
    NSRange rng = [imagePath rangeOfString:@"://" options:NSBackwardsSearch];
    if (rng.location == NSNotFound) {
        return imagePath;
    }
    rng.location = rng.location + 3;
    return [imagePath substringFromIndex:rng.location];
}

#pragma mark - Data sanitization methods

/**
 The v1 API result is inconsistent in that it will return a 0 when there is no author email.
 
 @param dict The author dictionary.
 @return The author's email address or an empty string.
 */
- (NSString *)authorEmailFromAuthorDictionary:(NSDictionary *)dict {
    NSString *authorEmail = [dict stringForKey:@"email"];

    // if 0 or less than minimum email length. a@a.aa
    if([authorEmail isEqualToString:@"0"] || [authorEmail length] < 6) {
        authorEmail = @"";
    }

    return authorEmail;
}

/**
 Parse whether the post belongs to a wpcom blog.

 @param A dictionary representing a post object from the REST API
 @return @1 if the post belongs to a wpcom blog, else @0
 */
- (NSNumber *)isWPComFromPostDictionary:(NSDictionary *)dict {
    NSNumber *isExternal = [dict numberForKey:@"is_external"];
    BOOL isWPCom = ![isExternal boolValue];
    return [NSNumber numberWithBool:isWPCom];
}

/**
 Get the tags assigned to a post and return them as a comma separated string.
 
 @param dict A dictionary representing a post object from the REST API.
 @return A comma separated list of tags, or an empty string if no tags are found.
 */
- (NSString *)tagsFromPostDictionary:(NSDictionary *)dict {
    NSDictionary *tagsDict = [dict dictionaryForKey:@"tags"];
    NSArray *tagsList = [NSArray arrayWithArray:[tagsDict allKeys]];
    NSString *tags = [tagsList componentsJoinedByString:@", "];
    if (tags == nil) {
        tags = @"";
    }
    return tags;
}

/**
 Get the date the post should be sorted by.

 @param dict A dictionary representing a post object from the REST API.
 @return The date string that should be used when sorting the post.
 */
- (NSString *)sortDateFromPostDictionary:(NSDictionary *)dict {
    // Sort date varies depending on the endpoint we're fetching from.
    NSString *sortDate = [self stringOrEmptyString:[dict stringForKey:@"date"]];

    // Date liked is returned by the read/liked end point.  Use this for sorting recent likes.
    NSString *likedDate = [dict stringForKey:@"date_liked"];
    if (likedDate != nil) {
        sortDate = likedDate;
    }

    // Values set in editorial trumps the rest
    NSString *editorialDate = [dict stringForKeyPath:@"editorial.displayed_on"];
    if (editorialDate != nil) {
        sortDate = editorialDate;
    }

    return sortDate;
}

/**
 Get the url path of the featured image to use for a post.

 @param dict A dictionary representing a post object from the REST API.
 @return The url path for the featured iamge or an empty string.
 */
- (NSString *)featuredImageFromPostDictionary:(NSDictionary *)dict {

    NSString *featuredImage = @"";

    NSDictionary *featured_media = [dict dictionaryForKey:@"featured_media"];
    if (featured_media && [[featured_media stringForKey:@"type"] isEqualToString:@"image"]) {
        featuredImage = [self stringOrEmptyString:[featured_media stringForKey:@"uri"]];
    }

    // Values set in editorial trumps the rest
    NSString *editorialImage = [dict stringForKeyPath:@"editorial.image"];
    if (editorialImage != nil) {
        featuredImage = editorialImage;
    }

    return [self sanitizeFeaturedImageString:featuredImage];
}

/**
 Get the name of the post's site.

 @param dict A dictionary representing a post object from the REST API.
 @return The name of the post's site or an empty string.
 */
- (NSString *)siteNameFromPostDictionary:(NSDictionary *)dict {
    // Blog Name
    NSString *siteName = [self stringOrEmptyString:[dict stringForKey:@"site_name"]];

    // For some endpoints blogname is defined in meta
    NSString *metaBlogName = [dict stringForKeyPath:@"meta.data.site.name"];
    if (metaBlogName != nil) {
        siteName = metaBlogName;
    }

    // Values set in editorial trumps the rest
    NSString *editorialSiteName = [dict stringForKeyPath:@"editorial.blog_name"];
    if (editorialSiteName != nil) {
        siteName = editorialSiteName;
    }

    return siteName;
}

/**
 Retrives the post site's URL

 @param dict A dictionary representing a post object from the REST API.
 @return The URL path of the post's site.
 */
- (NSString *)siteURLFromPostDictionary:(NSDictionary *)dict {
    NSString *siteURL = [self stringOrEmptyString:[dict stringForKey:@"site_URL"]];

    NSString *metaSiteURL = [dict stringForKeyPath:@"meta.data.site.URL"];
    if (metaSiteURL != nil) {
        siteURL = metaSiteURL;
    }

    return siteURL;
}

/**
 Retrives the privacy preference for the post's site.

 @param dict A dictionary representing a post object from the REST API.
 @return An NSNumber representing a boolean value of whether the site is or is not private.
 */
- (NSNumber *)siteIsPrivateFromPostDictionary:(NSDictionary *)dict {
    NSNumber *isPrivate = [dict numberForKey:@"site_is_private"];

    NSNumber *metaIsPrivate = [dict numberForKeyPath:@"meta.data.site.is_private"];
    if (metaIsPrivate != nil) {
        isPrivate = metaIsPrivate;
    }

    return isPrivate;
}

@end
