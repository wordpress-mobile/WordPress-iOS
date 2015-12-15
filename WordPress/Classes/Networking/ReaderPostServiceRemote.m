#import "ReaderPostServiceRemote.h"

#import "DateUtils.h"
#import "DisplayableImageHelper.h"
#import "RemoteReaderPost.h"
#import "RemoteSourcePostAttribution.h"
#import "ReaderTopicServiceRemote.h"
#import "WordPressComApi.h"
#import <WordPressShared/NSString+XMLExtensions.h>
#import "WordPress-Swift.h"

// REST Post dictionary keys
NSString * const PostRESTKeyAttachments = @"attachments";
NSString * const PostRESTKeyAuthor = @"author";
NSString * const PostRESTKeyAvatarURL = @"avatar_URL";
NSString * const PostRESTKeyCommentCount = @"comment_count";
NSString * const PostRESTKeyCommentsOpen = @"comments_open";
NSString * const PostRESTKeyContent = @"content";
NSString * const PostRESTKeyDate = @"date";
NSString * const PostRESTKeyDateLiked = @"date_liked";
NSString * const PostRESTKeyDiscoverMetadata = @"discover_metadata";
NSString * const PostRESTKeyDiscussion = @"discussion";
NSString * const PostRESTKeyEditorial = @"editorial";
NSString * const PostRESTKeyEmail = @"email";
NSString * const PostRESTKeyExcerpt = @"excerpt";
NSString * const PostRESTKeyFeaturedMedia = @"featured_media";
NSString * const PostRESTKeyFeaturedImage = @"featured_image";
NSString * const PostRESTKeyFeedID = @"feed_ID";
NSString * const PostRESTKeyFeedItemID = @"feed_item_ID";
NSString * const PostRESTKeyGlobalID = @"global_ID";
NSString * const PostRESTKeyHighlightTopic = @"highlight_topic";
NSString * const PostRESTKeyHighlightTopicTitle = @"highlight_topic_title";
NSString * const PostRESTKeyILike = @"i_like";
NSString * const PostRESTKeyID = @"ID";
NSString * const PostRESTKeyIsExternal = @"is_external";
NSString * const PostRESTKeyIsFollowing = @"is_following";
NSString * const PostRESTKeyIsJetpack = @"is_jetpack";
NSString * const PostRESTKeyIsReblogged = @"is_reblogged";
NSString * const PostRESTKeyLikeCount = @"like_count";
NSString * const PostRESTKeyLikesEnabled = @"likes_enabled";
NSString * const PostRESTKeyName = @"name";
NSString * const PostRESTKeyNiceName = @"nice_name";
NSString * const PostRESTKeyPermalink = @"permalink";
NSString * const PostRESTKeyPostCount = @"post_count";
NSString * const PostRESTKeySharingEnabled = @"sharing_enabled";
NSString * const PostRESTKeySiteID = @"site_ID";
NSString * const PostRESTKeySiteIsPrivate = @"site_is_private";
NSString * const PostRESTKeySiteName = @"site_name";
NSString * const PostRESTKeySiteURL = @"site_URL";
NSString * const PostRESTKeySlug = @"slug";
NSString * const PostRESTKeyStatus = @"status";
NSString * const PostRESTKeyTitle = @"title";
NSString * const PostRESTKeyTags = @"tags";
NSString * const PostRESTKeyURL = @"URL";
NSString * const PostRESTKeyWordCount = @"word_count";

// Tag dictionary keys
NSString * const TagKeyPrimary = @"primaryTag";
NSString * const TagKeyPrimarySlug = @"primaryTagSlug";
NSString * const TagKeySecondary = @"secondaryTag";
NSString * const TagKeySecondarySlug = @"secondaryTagSlug";

// XPost Meta Keys
NSString * const PostRESTKeyMetadata = @"metadata";
NSString * const CrossPostMetaKey = @"key";
NSString * const CrossPostMetaValue = @"value";
NSString * const CrossPostMetaXPostPermalink = @"_xpost_original_permalink";
NSString * const CrossPostMetaXCommentPermalink = @"xcomment_original_permalink";
NSString * const CrossPostMetaXPostOrigin = @"xpost_origin";
NSString * const CrossPostMetaCommentPrefix = @"comment-";

static const NSInteger AvgWordsPerMinuteRead = 250;
static const NSInteger MinutesToReadThreshold = 2;

@implementation ReaderPostServiceRemote

- (void)fetchPostsFromEndpoint:(NSURL *)endpoint
                         count:(NSUInteger)count
                        before:(NSDate *)date
                       success:(void (^)(NSArray *posts))success
                       failure:(void (^)(NSError *error))failure
{
    NSNumber *numberToFetch = @(count);
    NSDictionary *params = @{@"number":numberToFetch,
                             @"before": [DateUtils isoStringFromDate:date],
                             @"order": @"DESC",
                             @"meta":@"site,feed"
                             };

    [self fetchPostsFromEndpoint:endpoint withParameters:params success:success failure:failure];
}

- (void)fetchPost:(NSUInteger)postID
         fromSite:(NSUInteger)siteID
          success:(void (^)(RemoteReaderPost *post))success
          failure:(void (^)(NSError *error))failure {

    NSString *path = [NSString stringWithFormat:@"sites/%d/posts/%d/?meta=site", siteID, postID];
    NSString *requestUrl = [self pathForEndpoint:path
                                     withVersion:ServiceRemoteRESTApiVersion_1_1];
    
    [self.api GET:requestUrl
           parameters:nil
              success:^(AFHTTPRequestOperation *operation, id responseObject) {
                  if (!success) {
                      return;
                  }

                  RemoteReaderPost *post = [self formatPostDictionary:(NSDictionary *)responseObject];
                  success(post);

              } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                  if (failure) {
                      failure(error);
                  }
              }];
}

- (void)likePost:(NSUInteger)postID
         forSite:(NSUInteger)siteID
         success:(void (^)())success
         failure:(void (^)(NSError *error))failure
{
    NSString *path = [NSString stringWithFormat:@"sites/%d/posts/%d/likes/new", siteID, postID];
    NSString *requestUrl = [self pathForEndpoint:path
                                     withVersion:ServiceRemoteRESTApiVersion_1_1];
    
    [self.api POST:requestUrl parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success();
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

- (void)unlikePost:(NSUInteger)postID
           forSite:(NSUInteger)siteID
           success:(void (^)())success
           failure:(void (^)(NSError *error))failure
{
    NSString *path = [NSString stringWithFormat:@"sites/%d/posts/%d/likes/mine/delete", siteID, postID];
    NSString *requestUrl = [self pathForEndpoint:path
                                     withVersion:ServiceRemoteRESTApiVersion_1_1];
    
    [self.api POST:requestUrl parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success();
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
                           failure:(void (^)(NSError *))failure
{
    NSString *path = [endpoint absoluteString];
    
    [self.api GET:path
           parameters:params
              success:^(AFHTTPRequestOperation *operation, id responseObject) {
                  if (!success) {
                      return;
                  }

                  NSArray *jsonPosts = [responseObject arrayForKey:@"posts"];
                  NSArray *posts = [jsonPosts wp_map:^id(NSDictionary *jsonPost) {
                      return [self formatPostDictionary:jsonPost];
                  }];
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
 @return A `RemoteReaderPost` object
 */
- (RemoteReaderPost *)formatPostDictionary:(NSDictionary *)dict
{
    RemoteReaderPost *post = [[RemoteReaderPost alloc] init];

    NSDictionary *authorDict = [dict dictionaryForKey:PostRESTKeyAuthor];
    NSDictionary *discussionDict = [dict dictionaryForKey:PostRESTKeyDiscussion] ?: dict;
    
    post.author = [self stringOrEmptyString:[authorDict stringForKey:PostRESTKeyNiceName]]; // typically the author's screen name
    post.authorAvatarURL = [self stringOrEmptyString:[authorDict stringForKey:PostRESTKeyAvatarURL]];
    post.authorDisplayName = [self stringOrEmptyString:[authorDict stringForKey:PostRESTKeyName]]; // Typically the author's given name
    post.authorEmail = [self authorEmailFromAuthorDictionary:authorDict];
    post.authorURL = [self stringOrEmptyString:[authorDict stringForKey:PostRESTKeyURL]];
    post.siteIconURL = [self stringOrEmptyString:[dict stringForKeyPath:@"meta.data.site.icon.img"]];
    post.blogName = [self siteNameFromPostDictionary:dict];
    post.blogDescription = [self siteDescriptionFromPostDictionary:dict];
    post.blogURL = [self siteURLFromPostDictionary:dict];
    post.commentCount = [discussionDict numberForKey:PostRESTKeyCommentCount];
    post.commentsOpen = [[discussionDict numberForKey:PostRESTKeyCommentsOpen] boolValue];
    post.content = [self stringOrEmptyString:[dict stringForKey:PostRESTKeyContent]];
    post.date_created_gmt = [self stringOrEmptyString:[dict stringForKey:PostRESTKeyDate]];
    post.featuredImage = [self featuredImageFromPostDictionary:dict];
    post.feedID = [dict numberForKey:PostRESTKeyFeedID];
    post.feedItemID = [dict numberForKey:PostRESTKeyFeedItemID];
    post.globalID = [self stringOrEmptyString:[dict stringForKey:PostRESTKeyGlobalID]];
    post.isBlogPrivate = [self siteIsPrivateFromPostDictionary:dict];
    post.isFollowing = [[dict numberForKey:PostRESTKeyIsFollowing] boolValue];
    post.isLiked = [[dict numberForKey:PostRESTKeyILike] boolValue];
    post.isReblogged = [[dict numberForKey:PostRESTKeyIsReblogged] boolValue];
    post.isWPCom = [self isWPComFromPostDictionary:dict];
    post.likeCount = [dict numberForKey:PostRESTKeyLikeCount];
    post.permalink = [self stringOrEmptyString:[dict stringForKey:PostRESTKeyURL]];
    post.postID = [dict numberForKey:PostRESTKeyID];
    post.postTitle = [self stringOrEmptyString:[dict stringForKey:PostRESTKeyTitle]];
    post.siteID = [dict numberForKey:PostRESTKeySiteID];
    post.sortDate = [self sortDateFromPostDictionary:dict];
    post.status = [self stringOrEmptyString:[dict stringForKey:PostRESTKeyStatus]];
    post.summary = [self stringOrEmptyString:[dict stringForKey:PostRESTKeyExcerpt]];
    post.tags = [self tagsFromPostDictionary:dict];
    post.isSharingEnabled = [[dict numberForKey:PostRESTKeySharingEnabled] boolValue];
    post.isLikesEnabled = [[dict numberForKey:PostRESTKeyLikesEnabled] boolValue];

    NSDictionary *tags = [self primaryAndSecondaryTagsFromPostDictionary:dict];
    if (tags) {
        post.primaryTag = [tags stringForKey:TagKeyPrimary];
        post.primaryTagSlug = [tags stringForKey:TagKeyPrimarySlug];
        post.secondaryTag = [tags stringForKey:TagKeySecondary];
        post.secondaryTagSlug = [tags stringForKey:TagKeySecondarySlug];
    }

    post.isExternal = [[dict numberForKey:PostRESTKeyIsExternal] boolValue];
    post.isJetpack = [[dict numberForKey:PostRESTKeyIsJetpack] boolValue];
    post.wordCount = [dict numberForKey:PostRESTKeyWordCount];
    post.readingTime = [self readingTimeForWordCount:post.wordCount];

    if ([dict arrayForKeyPath:@"discover_metadata.discover_fp_post_formats"]) {
        post.sourceAttribution = [self sourceAttributionFromDictionary:[dict dictionaryForKey:PostRESTKeyDiscoverMetadata]];
    }

    RemoteReaderCrossPostMeta *crossPostMeta = [self crossPostMetaFromPostDictionary:dict];
    if (crossPostMeta) {
        post.crossPostMeta = crossPostMeta;
    }

    return post;
}

- (RemoteReaderCrossPostMeta *)crossPostMetaFromPostDictionary:(NSDictionary *)dict
{
    BOOL crossPostMetaFound = NO;

    RemoteReaderCrossPostMeta *meta = [RemoteReaderCrossPostMeta new];

    NSArray *metadata = [dict arrayForKey:PostRESTKeyMetadata];
    for (NSDictionary *obj in metadata) {
        if ([[obj stringForKey:CrossPostMetaKey] isEqualToString:CrossPostMetaXPostPermalink] ||
            [[obj stringForKey:CrossPostMetaKey] isEqualToString:CrossPostMetaXCommentPermalink]) {

            NSString *path = [obj stringForKey:CrossPostMetaValue];
            NSURL *url = [NSURL URLWithString:path];
            if (!url) {
                NSLog(@"break");
            }

            meta.siteURL = [NSString stringWithFormat:@"%@://%@", url.scheme, url.host];
            meta.postURL = [NSString stringWithFormat:@"%@/%@", meta.siteURL, url.path];
            if ([url.fragment hasPrefix:CrossPostMetaCommentPrefix]) {
                meta.commentURL = [url absoluteString];
            }
        } else if ([[obj stringForKey:CrossPostMetaKey] isEqualToString:CrossPostMetaXPostOrigin]) {
            NSString *value = [obj stringForKey:CrossPostMetaValue];
            NSArray *IDS = [value componentsSeparatedByString:@":"];
            meta.siteID = [[IDS firstObject] numericValue];
            meta.postID = [[IDS lastObject] numericValue];

            crossPostMetaFound = YES;
        }
    }

    if (!crossPostMetaFound) {
        return nil;
    }

    return meta;
}

- (NSDictionary *)primaryAndSecondaryTagsFromPostDictionary:(NSDictionary *)dict
{
    NSString *primaryTag = @"";
    NSString *primaryTagSlug = @"";
    NSString *secondaryTag = @"";
    NSString *secondaryTagSlug = @"";
    NSString *editorialTag;
    NSString *editorialSlug;

    // Loop over all the tags.
    // If the current tag's post count is greater than the previous post count,
    // make it the new primary tag, and make a previous primary tag the secondary tag.
    NSArray *remoteTags = [[dict dictionaryForKey:PostRESTKeyTags] allValues];
    if (remoteTags) {
        NSInteger highestCount = 0;
        NSInteger secondHighestCount = 0;
        for (NSDictionary *tag in remoteTags) {
            NSInteger count = [[tag numberForKey:PostRESTKeyPostCount] integerValue];
            if (count > highestCount) {
                secondaryTag = primaryTag;
                secondaryTagSlug = primaryTagSlug;
                secondHighestCount = highestCount;

                primaryTag = [tag stringForKey:PostRESTKeyName] ?: @"";
                primaryTagSlug = [tag stringForKey:PostRESTKeySlug] ?: @"";
                highestCount = count;

            } else if (count > secondHighestCount) {
                secondaryTag = [tag stringForKey:PostRESTKeyName] ?: @"";
                secondaryTagSlug = [tag stringForKey:PostRESTKeySlug] ?: @"";
                secondHighestCount = count;

            }
        }
    }

    NSDictionary *editorial = [dict dictionaryForKey:PostRESTKeyEditorial];
    if (editorial) {
        editorialSlug = [editorial stringForKey:PostRESTKeyHighlightTopic];
        editorialTag = [editorial stringForKey:PostRESTKeyHighlightTopicTitle] ?: [editorialSlug capitalizedString];
    }

    if (editorialSlug) {
        secondaryTag = primaryTag;
        secondaryTagSlug = primaryTagSlug;
        primaryTag = editorialTag;
        primaryTagSlug = editorialSlug;
    }

    primaryTag = [primaryTag stringByDecodingXMLCharacters];
    secondaryTag = [secondaryTag stringByDecodingXMLCharacters];

    return @{
             TagKeyPrimary:primaryTag,
             TagKeyPrimarySlug:primaryTagSlug,
             TagKeySecondary:secondaryTag,
             TagKeySecondarySlug:secondaryTagSlug,
             };
}

- (NSNumber *)readingTimeForWordCount:(NSNumber *)wordCount
{
    NSInteger count = [wordCount integerValue];
    NSInteger minutesToRead = count / AvgWordsPerMinuteRead;
    if (minutesToRead < MinutesToReadThreshold) {
        return @(0);
    }
    return @(minutesToRead);
}

/**
 Composes discover attribution if needed.

 @param dict A dictionary representing a discover_metadata object from the REST API
 @return A `RemoteDiscoverAttribution` object
 */
- (RemoteSourcePostAttribution *)sourceAttributionFromDictionary:(NSDictionary *)dict
{
    NSArray *taxonomies = [dict arrayForKey:@"discover_fp_post_formats"];
    if ([taxonomies count] == 0) {
        return nil;
    }

    RemoteSourcePostAttribution *sourceAttr = [RemoteSourcePostAttribution new];
    sourceAttr.permalink = [dict stringForKey:PostRESTKeyPermalink];
    sourceAttr.authorName = [dict stringForKeyPath:@"attribution.author_name"];
    sourceAttr.authorURL = [dict stringForKeyPath:@"attribution.author_url"];
    sourceAttr.avatarURL = [dict stringForKeyPath:@"attribution.avatar_url"];
    sourceAttr.blogName = [dict stringForKeyPath:@"attribution.blog_name"];
    sourceAttr.blogURL = [dict stringForKeyPath:@"attribution.blog_url"];
    sourceAttr.blogID = [dict numberForKeyPath:@"featured_post_wpcom_data.blog_id"];
    sourceAttr.postID = [dict numberForKeyPath:@"featured_post_wpcom_data.post_id"];
    sourceAttr.commentCount = [dict numberForKeyPath:@"featured_post_wpcom_data.comment_count"];
    sourceAttr.likeCount = [dict numberForKeyPath:@"featured_post_wpcom_data.like_count"];
    sourceAttr.taxonomies = [self slugsFromDiscoverPostTaxonomies:taxonomies];
    return sourceAttr;
}


#pragma mark - Utils

/**
 Checks the value of the string passed. If the string is nil, an empty string is returned.

 @param str The string to check for nil.
 @ Returns the string passed if it was not nil, or an empty string if the value passed was nil.
 */
- (NSString *)stringOrEmptyString:(NSString *)str
{
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
- (NSString *)sanitizeFeaturedImageString:(NSString *)img
{
    if (!img) {
        return [NSString string];
    }
    NSRange mshotRng = [img rangeOfString:@"wp.com/mshots/"];
    if (NSNotFound != mshotRng.location) {
        // MShots are sceen caps of the actual site. There URLs look like this:
        // https://s0.wp.com/mshots/v1/http%3A%2F%2Fsitename.wordpress.com%2F2013%2F05%2F13%2Fr-i-p-mom%2F?w=252
        // We want the mshot URL but not the size info in the query string.
        NSRange rng = [img rangeOfString:@"?" options:NSBackwardsSearch];
        if (rng.location != NSNotFound) {
            img = [img substringWithRange:NSMakeRange(0, rng.location)];
        }
        return img;
    }

    NSRange imgPressRng = [img rangeOfString:@"wp.com/imgpress"];
    if (imgPressRng.location != NSNotFound) {
        // ImagePress urls look like this:
        // https://s0.wp.com/imgpress?resize=252%2C160&url=http%3A%2F%2Fsitename.files.wordpress.com%2F2014%2F04%2Fimage-name.jpg&unsharpmask=80,0.5,3
        // We want the URL of the image being sent to ImagePress without all the ImagePress stuff

        // Find the start of the actual URL for the image
        NSRange httpRng = [img rangeOfString:@"http" options:NSBackwardsSearch];
        NSInteger location = 0;
        if (httpRng.location != NSNotFound) {
            location = httpRng.location;
        }

        // Find the last of the image press options after the image URL
        // Search from the start of the URL to the end of the string
        NSRange ampRng = [img rangeOfString:@"&" options:nil range:NSMakeRange(location, [img length] - location)];
        // Default length is the remainder of the string following the start of the image URL.
        NSInteger length = [img length] - location;
        if (ampRng.location != NSNotFound) {
            // The actual length is the location of the first ampersand after the starting index of the image URL, minus the starting index of the image URL.
            length = ampRng.location - location;
        }

        // Retrieve the image URL substring from the range.
        img = [img substringWithRange:NSMakeRange(location, length)];

        // Actually decode twice to remove the encodings
        img = [img stringByRemovingPercentEncoding];
        img = [img stringByRemovingPercentEncoding];
    }
    return img;
}

#pragma mark - Data sanitization methods

/**
 The v1 API result is inconsistent in that it will return a 0 when there is no author email.

 @param dict The author dictionary.
 @return The author's email address or an empty string.
 */
- (NSString *)authorEmailFromAuthorDictionary:(NSDictionary *)dict
{
    NSString *authorEmail = [dict stringForKey:PostRESTKeyEmail];

    // if 0 or less than minimum email length. a@a.aa
    if ([authorEmail isEqualToString:@"0"] || [authorEmail length] < 6) {
        authorEmail = @"";
    }

    return authorEmail;
}

/**
 Parse whether the post belongs to a wpcom blog.

 @param A dictionary representing a post object from the REST API
 @return YES if the post belongs to a wpcom blog, else NO
 */
- (BOOL)isWPComFromPostDictionary:(NSDictionary *)dict
{
    BOOL isExternal = [[dict numberForKey:PostRESTKeyIsExternal] boolValue];
    BOOL isJetpack = [[dict numberForKey:PostRESTKeyIsJetpack] boolValue];

    return !isJetpack && !isExternal;
}

/**
 Get the tags assigned to a post and return them as a comma separated string.

 @param dict A dictionary representing a post object from the REST API.
 @return A comma separated list of tags, or an empty string if no tags are found.
 */
- (NSString *)tagsFromPostDictionary:(NSDictionary *)dict
{
    NSDictionary *tagsDict = [dict dictionaryForKey:PostRESTKeyTags];
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
- (NSString *)sortDateFromPostDictionary:(NSDictionary *)dict
{
    // Sort date varies depending on the endpoint we're fetching from.
    NSString *sortDate = [self stringOrEmptyString:[dict stringForKey:PostRESTKeyDate]];

    // Date liked is returned by the read/liked end point.  Use this for sorting recent likes.
    NSString *likedDate = [dict stringForKey:PostRESTKeyDateLiked];
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
 @return The url path for the featured image or an empty string.
 */
- (NSString *)featuredImageFromPostDictionary:(NSDictionary *)dict
{
    NSDictionary *featured_media = [dict dictionaryForKey:PostRESTKeyFeaturedMedia];

    // Editorial trumps all
    NSString *featuredImage = [dict stringForKeyPath:@"editorial.image"];

    // User specified featured image.
    if ([featuredImage length] == 0) {
        featuredImage = [dict stringForKey:PostRESTKeyFeaturedImage];
    }

    // If no featured image specified, try featured media.
    if (([featuredImage length] == 0) && ([[featured_media stringForKey:@"type"] isEqualToString:@"image"])) {
        featuredImage = [self stringOrEmptyString:[featured_media stringForKey:@"uri"]];
    }

    // If still no image specified, try attachments.
    if ([featuredImage length] == 0) {
        NSDictionary *attachments = [dict dictionaryForKey:PostRESTKeyAttachments];
        NSString *imageToDisplay = [DisplayableImageHelper searchPostAttachmentsForImageToDisplay:attachments];
        featuredImage = [self stringOrEmptyString:imageToDisplay];
    }

    // If stilll no match, parse content
    if ([featuredImage length] == 0) {
        NSString *content = [dict stringForKey:PostRESTKeyContent];
        NSString *imageToDisplay = [DisplayableImageHelper searchPostContentForImageToDisplay:content];
        featuredImage = [self stringOrEmptyString:imageToDisplay];
    }

    featuredImage = [self sanitizeFeaturedImageString:featuredImage];

    return featuredImage;
}

/**
 Get the name of the post's site.

 @param dict A dictionary representing a post object from the REST API.
 @return The name of the post's site or an empty string.
 */
- (NSString *)siteNameFromPostDictionary:(NSDictionary *)dict
{
    // Blog Name
    NSString *siteName = [self stringOrEmptyString:[dict stringForKey:PostRESTKeySiteName]];

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
 Get the description of the post's site.

 @param dict A dictionary representing a post object from the REST API.
 @return The description of the post's site or an empty string.
 */
- (NSString *)siteDescriptionFromPostDictionary:(NSDictionary *)dict
{
    return [self stringOrEmptyString:[dict stringForKeyPath:@"meta.data.site.description"]];
}

/**
 Retrives the post site's URL

 @param dict A dictionary representing a post object from the REST API.
 @return The URL path of the post's site.
 */
- (NSString *)siteURLFromPostDictionary:(NSDictionary *)dict
{
    NSString *siteURL = [self stringOrEmptyString:[dict stringForKey:PostRESTKeySiteURL]];

    NSString *metaSiteURL = [dict stringForKeyPath:@"meta.data.site.URL"];
    if (metaSiteURL != nil) {
        siteURL = metaSiteURL;
    }

    return siteURL;
}

/**
 Retrives the privacy preference for the post's site.

 @param dict A dictionary representing a post object from the REST API.
 @return YES if the site is private.
 */
- (BOOL)siteIsPrivateFromPostDictionary:(NSDictionary *)dict
{
    NSNumber *isPrivate = [dict numberForKey:PostRESTKeySiteIsPrivate];

    NSNumber *metaIsPrivate = [dict numberForKeyPath:@"meta.data.site.is_private"];
    if (metaIsPrivate != nil) {
        isPrivate = metaIsPrivate;
    }

    return [isPrivate boolValue];
}

- (NSArray *)slugsFromDiscoverPostTaxonomies:(NSArray *)discoverPostTaxonomies
{
    return [discoverPostTaxonomies wp_map:^id(NSDictionary *dict) {
        return [dict stringForKey:PostRESTKeySlug];
    }];
}

@end
