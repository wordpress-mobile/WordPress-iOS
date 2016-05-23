#import "ReaderPostServiceRemote.h"

#import "DateUtils.h"
#import "DisplayableImageHelper.h"
#import "RemoteReaderPost.h"
#import "RemoteSourcePostAttribution.h"
#import "ReaderTopicServiceRemote.h"
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
NSString * const PostRESTKeyScore = @"score";
NSString * const PostRESTKeySharingEnabled = @"sharing_enabled";
NSString * const PostRESTKeySiteID = @"site_ID";
NSString * const PostRESTKeySiteIsPrivate = @"site_is_private";
NSString * const PostRESTKeySiteName = @"site_name";
NSString * const PostRESTKeySiteURL = @"site_URL";
NSString * const PostRESTKeySlug = @"slug";
NSString * const PostRESTKeyStatus = @"status";
NSString * const PostRESTKeyTitle = @"title";
NSString * const PostRESTKeyTags = @"tags";
NSString * const POSTRESTKeyTagDisplayName = @"display_name";
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
static const NSUInteger ReaderPostTitleLength = 30;

@implementation ReaderPostServiceRemote

- (void)fetchPostsFromEndpoint:(NSURL *)endpoint
                         count:(NSUInteger)count
                        before:(NSDate *)date
                       success:(void (^)(NSArray<RemoteReaderPost *> *posts))success
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

- (void)fetchPostsFromEndpoint:(NSURL *)endpoint
                         count:(NSUInteger)count
                        offset:(NSUInteger)offset
                       success:(void (^)(NSArray<RemoteReaderPost *> *))success
                       failure:(void (^)(NSError *))failure
{
    NSDictionary *params = @{@"number": @(count),
                             @"offset": @(offset),
                             @"order": @"DESC",
                             @"meta":@"site,feed"
                             };
    [self fetchPostsFromEndpoint:endpoint withParameters:params success:success failure:failure];
}

- (void)fetchPost:(NSUInteger)postID
         fromSite:(NSUInteger)siteID
          success:(void (^)(RemoteReaderPost *post))success
          failure:(void (^)(NSError *error))failure {

    NSString *path = [NSString stringWithFormat:@"read/sites/%d/posts/%d/?meta=site", siteID, postID];
    NSString *requestUrl = [self pathForEndpoint:path
                                     withVersion:ServiceRemoteWordPressComRESTApiVersion_1_2];
    
    [self.wordPressComRestApi GET:requestUrl
           parameters:nil
              success:^(id responseObject, NSHTTPURLResponse *httpResponse) {
                  if (!success) {
                      return;
                  }

                  RemoteReaderPost *post = [self formatPostDictionary:(NSDictionary *)responseObject];
                  success(post);

              } failure:^(NSError *error, NSHTTPURLResponse *httpResponse) {
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
                                     withVersion:ServiceRemoteWordPressComRESTApiVersion_1_1];
    
    [self.wordPressComRestApi POST:requestUrl parameters:nil success:^(id responseObject, NSHTTPURLResponse *httpResponse) {
        if (success) {
            success();
        }
    } failure:^(NSError *error, NSHTTPURLResponse *httpResponse) {
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
                                     withVersion:ServiceRemoteWordPressComRESTApiVersion_1_1];
    
    [self.wordPressComRestApi POST:requestUrl parameters:nil success:^(id responseObject, NSHTTPURLResponse *httpResponse) {
        if (success) {
            success();
        }
    } failure:^(NSError *error, NSHTTPURLResponse *httpResponse) {
        if (failure) {
            failure(error);
        }
    }];
}

- (NSString *)endpointUrlForSearchPhrase:(NSString *)phrase
{
    NSAssert([phrase length] > 0, @"A search phrase is required.");

    NSString *endpoint = [NSString stringWithFormat:@"read/search?q=%@", [phrase stringByUrlEncoding]];
    NSString *absolutePath = [self pathForEndpoint:endpoint withVersion:ServiceRemoteWordPressComRESTApiVersion_1_2];
    NSURL *url = [NSURL URLWithString:absolutePath relativeToURL:[NSURL URLWithString:WordPressComRestApi.apiBaseURLString]];
    return [url absoluteString];
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
                           success:(void (^)(NSArray<RemoteReaderPost *> *posts))success
                           failure:(void (^)(NSError *))failure
{
    NSString *path = [endpoint absoluteString];
    
    [self.wordPressComRestApi GET:path
           parameters:params
              success:^(id responseObject, NSHTTPURLResponse *httpResponse) {
                  if (!success) {
                      return;
                  }

                  NSArray *jsonPosts = [responseObject arrayForKey:@"posts"];
                  NSArray *posts = [jsonPosts wp_map:^id(NSDictionary *jsonPost) {
                      return [self formatPostDictionary:jsonPost];
                  }];
                  success(posts);

              } failure:^(NSError *error, NSHTTPURLResponse *httpResponse) {
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
    post.content = [self postContentFromPostDictionary:dict];
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
    post.postTitle = [self postTitleFromPostDictionary:dict];
    post.score = [dict numberForKey:PostRESTKeyScore];
    post.siteID = [dict numberForKey:PostRESTKeySiteID];
    post.sortDate = [self sortDateFromPostDictionary:dict];
    post.sortRank = [self sortRankFromScore:post.score orSortDate:post.sortDate];
    post.status = [self stringOrEmptyString:[dict stringForKey:PostRESTKeyStatus]];
    post.summary = [self postSummaryFromPostDictionary:dict orPostContent:post.content];
    post.tags = [self tagsFromPostDictionary:dict];
    post.isSharingEnabled = [[dict numberForKey:PostRESTKeySharingEnabled] boolValue];
    post.isLikesEnabled = [[dict numberForKey:PostRESTKeyLikesEnabled] boolValue];

    // Construct a title if necessary.
    if ([post.postTitle length] == 0 && [post.summary length] > 0) {
        post.postTitle = [self titleFromSummary:post.summary];
    }

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
        if (![obj isKindOfClass:[NSDictionary class]]) {
            continue;
        }
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
        NSString *tagTitle;
        for (NSDictionary *tag in remoteTags) {
            NSInteger count = [[tag numberForKey:PostRESTKeyPostCount] integerValue];
            if (count > highestCount) {
                secondaryTag = primaryTag;
                secondaryTagSlug = primaryTagSlug;
                secondHighestCount = highestCount;

                tagTitle = [tag stringForKey:POSTRESTKeyTagDisplayName] ?: [tag stringForKey:PostRESTKeyName];
                primaryTag = tagTitle ?: @"";
                primaryTagSlug = [tag stringForKey:PostRESTKeySlug] ?: @"";
                highestCount = count;

            } else if (count > secondHighestCount) {
                tagTitle = [tag stringForKey:POSTRESTKeyTagDisplayName] ?: [tag stringForKey:PostRESTKeyName];
                secondaryTag = tagTitle ?: @"";
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
 @return The NSDate that should be used when sorting the post.
 */
- (NSDate *)sortDateFromPostDictionary:(NSDictionary *)dict
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

    return [DateUtils dateFromISOString:sortDate];
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

    return [self makePlainText:siteName];
}

/**
 Get the description of the post's site.

 @param dict A dictionary representing a post object from the REST API.
 @return The description of the post's site or an empty string.
 */
- (NSString *)siteDescriptionFromPostDictionary:(NSDictionary *)dict
{
    NSString *description = [self stringOrEmptyString:[dict stringForKeyPath:@"meta.data.site.description"]];
    return [self makePlainText:description];
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
 Retrives the post content from results dictionary

 @param dict A dictionary representing a post object from the REST API.
 @return The formatted post content.
 */
- (NSString *)postContentFromPostDictionary:(NSDictionary *)dict {
    NSString *content = [self stringOrEmptyString:[dict stringForKey:PostRESTKeyContent]];
    return [self formatContent:content];
}

/**
 Get the title of the post

 @param dict A dictionary representing a post object from the REST API.
 @return The title of the post or an empty string.
 */
- (NSString *)postTitleFromPostDictionary:(NSDictionary *)dict {
    NSString *title = [self stringOrEmptyString:[dict stringForKey:PostRESTKeyTitle]];
    return [self makePlainText:title];
}

/**
 Get the summary for the post, or crafts one from the post content.

 @param dict A dictionary representing a post object from the REST API.
 @param content The formatted post content.
 @return The summary for the post or an empty string.
 */
- (NSString *)postSummaryFromPostDictionary:(NSDictionary *)dict orPostContent:(NSString *)content {
    NSString *summary = [self stringOrEmptyString:[dict stringForKey:PostRESTKeyExcerpt]];
    summary = [self formatSummary:summary];
    if (!summary) {
        summary = [self createSummaryFromContent:content];
    }
    return summary;
}

/**
 Derive a sort rank from either the score or the sortDate.
 
 @param score The search score of a post. 
 @param sortDate The sort date of the post.
 @return A numeric sort rank (double) as an NSNumber.
 */
- (NSNumber *)sortRankFromScore:(NSNumber *)score orSortDate:(NSDate *)sortDate
{
    if (score > 0) {
        return score;
    }
    return @(sortDate.timeIntervalSinceReferenceDate);
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





#pragma mark - Content Formatting and Sanitization

/**
 Formats the post content.
 Removes transforms videopress markup into video tags, strips inline styles and tidys up paragraphs.

 @param content The post content as a string.
 @return The formatted content.
 */
- (NSString *)formatContent:(NSString *)content
{
    if ([self containsVideoPress:content]) {
        content = [self formatVideoPress:content];
    }
    content = [self normalizeParagraphs:content];
    content = [self removeInlineStyles:content];
    content = [content stringByReplacingHTMLEmoticonsWithEmoji];

    return content;
}

/**
 Formats a post's summary.  The excerpts provided by the REST API contain HTML and have some extra content appened to the end.
 HTML is stripped and the extra bit is removed.

 @param string The summary to format.
 @return The formatted summary.
 */
- (NSString *)formatSummary:(NSString *)summary
{
    summary = [self makePlainText:summary];

    NSString *continueReading = NSLocalizedString(@"Continue reading", @"Part of a prompt suggesting that there is more content for the user to read.");
    continueReading = [NSString stringWithFormat:@"%@ →", continueReading];

    NSRange rng = [summary rangeOfString:continueReading options:NSCaseInsensitiveSearch];
    if (rng.location != NSNotFound) {
        summary = [summary substringToIndex:rng.location];
    }

    return summary;
}

/**
 Create a summary for the post based on the post's content.

 @param string The post's content string. This should be the formatted content string.
 @return A summary for the post.
 */
- (NSString *)createSummaryFromContent:(NSString *)string
{
    return [BasePost summaryFromContent:string];
}

/**
 Transforms the specified string to plain text.  HTML markup is removed and HTML entities are decoded.

 @param string The string to transform.
 @return The transformed string.
 */
- (NSString *)makePlainText:(NSString *)string
{
    return [NSString makePlainText:string];
}

/**
 Clean up paragraphs and in an HTML string. Removes duplicate paragraph tags and unnecessary DIVs.

 @param string The string to normalize.
 @return A string with normalized paragraphs.
 */
- (NSString *)normalizeParagraphs:(NSString *)string
{
    if (!string) {
        return @"";
    }

    static NSRegularExpression *regexDivStart;
    static NSRegularExpression *regexDivEnd;
    static NSRegularExpression *regexPStart;
    static NSRegularExpression *regexPEnd;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSError *error;
        regexDivStart = [NSRegularExpression regularExpressionWithPattern:@"<div[^>]*>" options:NSRegularExpressionCaseInsensitive error:&error];
        regexDivEnd = [NSRegularExpression regularExpressionWithPattern:@"</div>" options:NSRegularExpressionCaseInsensitive error:&error];
        regexPStart = [NSRegularExpression regularExpressionWithPattern:@"<p[^>]*>\\s*<p[^>]*>" options:NSRegularExpressionCaseInsensitive error:&error];
        regexPEnd = [NSRegularExpression regularExpressionWithPattern:@"</p>\\s*</p>" options:NSRegularExpressionCaseInsensitive error:&error];
    });

    // Convert div tags to p tags
    string = [regexDivStart stringByReplacingMatchesInString:string options:NSMatchingReportCompletion range:NSMakeRange(0, [string length]) withTemplate:@"<p>"];
    string = [regexDivEnd stringByReplacingMatchesInString:string options:NSMatchingReportCompletion range:NSMakeRange(0, [string length]) withTemplate:@"</p>"];

    // Remove duplicate p tags.
    string = [regexPStart stringByReplacingMatchesInString:string options:NSMatchingReportCompletion range:NSMakeRange(0, [string length]) withTemplate:@"<p>"];
    string = [regexPEnd stringByReplacingMatchesInString:string options:NSMatchingReportCompletion range:NSMakeRange(0, [string length]) withTemplate:@"</p>"];

    return string;
}

/**
 Strip inline styles from the passed HTML sting.

 @param string An HTML string to sanitize.
 @return A string with inline styles removed.
 */
- (NSString *)removeInlineStyles:(NSString *)string
{
    if (!string) {
        return @"";
    }

    static NSRegularExpression *regex;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSError *error;
        regex = [NSRegularExpression regularExpressionWithPattern:@"style=\"[^\"]*\"" options:NSRegularExpressionCaseInsensitive error:&error];
    });

    // Remove inline styles.
    return [regex stringByReplacingMatchesInString:string options:NSMatchingReportCompletion range:NSMakeRange(0, [string length]) withTemplate:@""];
}

/**
 Check the specified string for occurances of videopress videos.

 @param string The string to search.
 @return YES if a match was found, else returns NO.
 */

- (BOOL)containsVideoPress:(NSString *)string
{
    return [string rangeOfString:@"class=\"videopress-placeholder"].location != NSNotFound;
}

/**
 Replace occurances of videopress markup with video tags int he passed HTML string.

 @param string An HTML string.
 @return The HTML string with videopress markup replaced with in image tag.
 */
- (NSString *)formatVideoPress:(NSString *)string
{
    NSMutableString *mstr = [string mutableCopy];

    static NSRegularExpression *regexVideoPress;
    static NSRegularExpression *regexMp4;
    static NSRegularExpression *regexSrc;
    static NSRegularExpression *regexPoster;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSError *error;
        regexVideoPress = [NSRegularExpression regularExpressionWithPattern:@"<div.*class=\"video-player[\\S\\s]+?<div.*class=\"videopress-placeholder[\\s\\S]*?</noscript>" options:NSRegularExpressionCaseInsensitive error:&error];
        regexMp4 = [NSRegularExpression regularExpressionWithPattern:@"mp4[\\s\\S]+?mp4" options:NSRegularExpressionCaseInsensitive error:&error];
        regexSrc = [NSRegularExpression regularExpressionWithPattern:@"http\\S+mp4" options:NSRegularExpressionCaseInsensitive error:&error];
        regexPoster = [NSRegularExpression regularExpressionWithPattern:@"<img.*class=\"videopress-poster[\\s\\S]*?>" options:NSRegularExpressionCaseInsensitive error:&error];
    });

    // Find instances of VideoPress markup.

    NSArray *matches = [regexVideoPress matchesInString:mstr options:NSRegularExpressionCaseInsensitive range:NSMakeRange(0, [mstr length])];
    for (NSTextCheckingResult *match in [matches reverseObjectEnumerator]) {
        // compose videopress string

        // Find the mp4 in the markup.
        NSRange mp4Match = [regexMp4 rangeOfFirstMatchInString:mstr options:NSRegularExpressionCaseInsensitive range:match.range];
        if (mp4Match.location == NSNotFound) {
            DDLogError(@"%@ failed to match mp4 JSON string while formatting video press markup: %@", NSStringFromSelector(_cmd), [mstr substringWithRange:match.range]);
            [mstr replaceCharactersInRange:match.range withString:@""];
            continue;
        }
        NSString *mp4 = [mstr substringWithRange:mp4Match];

        // Get the mp4 url.
        NSRange srcMatch = [regexSrc rangeOfFirstMatchInString:mp4 options:NSRegularExpressionCaseInsensitive range:NSMakeRange(0, [mp4 length])];
        if (srcMatch.location == NSNotFound) {
            DDLogError(@"%@ failed to match mp4 src when formatting video press markup: %@", NSStringFromSelector(_cmd), mp4);
            [mstr replaceCharactersInRange:match.range withString:@""];
            continue;
        }
        NSString *src = [mp4 substringWithRange:srcMatch];
        src = [src stringByReplacingOccurrencesOfString:@"\\/" withString:@"/"];

        NSString *height = @"200"; // default
        NSString *placeholder = @"";
        NSRange posterMatch = [regexPoster rangeOfFirstMatchInString:string options:NSRegularExpressionCaseInsensitive range:NSMakeRange(0, [string length])];
        if (posterMatch.location != NSNotFound) {
            NSString *poster = [string substringWithRange:posterMatch];
            NSString *value = [self parseValueForAttributeNamed:@"height" inElement:poster];
            if (value) {
                height = value;
            }

            value = [self parseValueForAttributeNamed:@"src" inElement:poster];
            if (value) {
                placeholder = value;
            }
        }

        // Compose a video tag to replace the default markup.
        NSString *fmt = @"<video src=\"%@\" controls width=\"100%%\" height=\"%@\" poster=\"%@\"><source src=\"%@\" type=\"video/mp4\"></video>";
        NSString *vid = [NSString stringWithFormat:fmt, src, height, placeholder, src];

        [mstr replaceCharactersInRange:match.range withString:vid];
    }

    return mstr;
}

- (NSString *)parseValueForAttributeNamed:(NSString *)attribute inElement:(NSString *)element
{
    NSString *value = @"";
    NSString *attrStr = [NSString stringWithFormat:@"%@=\"", attribute];
    NSRange attrRange = [element rangeOfString:attrStr];
    if (attrRange.location != NSNotFound) {
        NSInteger location = attrRange.location + attrRange.length;
        NSInteger length = [element length] - location;
        NSRange ending = [element rangeOfString:@"\"" options:NSCaseInsensitiveSearch range:NSMakeRange(location, length)];
        value = [element substringWithRange:NSMakeRange(location, ending.location - location)];
    }
    return value;
}

/**
 Creates a title for the post from the post's summary.

 @param summary The already formatted post summary.
 @return A title for the post that is a snippet of the summary.
 */
- (NSString *)titleFromSummary:(NSString *)summary
{
    return [summary stringByEllipsizingWithMaxLength:ReaderPostTitleLength preserveWords:YES];
}


@end
