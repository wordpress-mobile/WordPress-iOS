#import "RemoteReaderPost.h"
#import "RemoteSourcePostAttribution.h"
#import "WPKit-Swift.h"

@import NSObject_SafeExpectations;
@import WordPressShared;

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
NSString * const PostRESTKeyIsSeen = @"is_seen";
NSString * const PostRESTKeyLikeCount = @"like_count";
NSString * const PostRESTKeyLikesEnabled = @"likes_enabled";
NSString * const PostRESTKeyName = @"name";
NSString * const PostRESTKeyNiceName = @"nice_name";
NSString * const PostRESTKeyPermalink = @"permalink";
NSString * const PostRESTKeyPostCount = @"post_count";
NSString * const PostRESTKeyScore = @"score";
NSString * const PostRESTKeySharingEnabled = @"sharing_enabled";
NSString * const PostRESTKeySiteID = @"site_ID";
NSString * const PostRESTKeySiteIsAtomic = @"site_is_atomic";
NSString * const PostRESTKeySiteIsPrivate = @"site_is_private";
NSString * const PostRESTKeySiteName = @"site_name";
NSString * const PostRESTKeySiteURL = @"site_URL";
NSString * const PostRESTKeySlug = @"slug";
NSString * const PostRESTKeyStatus = @"status";
NSString * const PostRESTKeyTitle = @"title";
NSString * const PostRESTKeyTaggedOn = @"tagged_on";
NSString * const PostRESTKeyTags = @"tags";
NSString * const POSTRESTKeyTagDisplayName = @"display_name";
NSString * const PostRESTKeyURL = @"URL";
NSString * const PostRESTKeyWordCount = @"word_count";
NSString * const PostRESTKeyRailcar = @"railcar";
NSString * const PostRESTKeyOrganizationID = @"meta.data.site.organization_id";
NSString * const PostRESTKeyCanSubscribeComments = @"can_subscribe_comments";
NSString * const PostRESTKeyIsSubscribedComments = @"is_subscribed_comments";
NSString * const POSTRESTKeyReceivesCommentNotifications = @"subscribed_comments_notifications";

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

@implementation RemoteReaderPost

/**
 Sanitizes a post object from the REST API.

 @param dict A dictionary representing a post object from the REST API
 @return A `RemoteReaderPost` object
 */
- (instancetype)initWithDictionary:(NSDictionary *)dict;
{
    NSDictionary *authorDict = [dict dictionaryForKey:PostRESTKeyAuthor];
    NSDictionary *discussionDict = [dict dictionaryForKey:PostRESTKeyDiscussion] ?: dict;

    self.authorID = [authorDict numberForKey:PostRESTKeyID];
    self.author = [self stringOrEmptyString:[authorDict stringForKey:PostRESTKeyNiceName]]; // typically the author's screen name
    self.authorAvatarURL = [self stringOrEmptyString:[authorDict stringForKey:PostRESTKeyAvatarURL]];
    self.authorDisplayName = [[self stringOrEmptyString:[authorDict stringForKey:PostRESTKeyName]] stringByDecodingXMLCharacters]; // Typically the author's given name
    self.authorEmail = [self authorEmailFromAuthorDictionary:authorDict];
    self.authorURL = [self stringOrEmptyString:[authorDict stringForKey:PostRESTKeyURL]];
    self.siteIconURL = [self stringOrEmptyString:[dict stringForKeyPath:@"meta.data.site.icon.img"]];
    self.blogName = [self siteNameFromPostDictionary:dict];
    self.blogDescription = [self siteDescriptionFromPostDictionary:dict];
    self.blogURL = [self siteURLFromPostDictionary:dict];
    self.commentCount = [discussionDict numberForKey:PostRESTKeyCommentCount];
    self.commentsOpen = [[discussionDict numberForKey:PostRESTKeyCommentsOpen] boolValue];
    self.content = [self postContentFromPostDictionary:dict];
    self.date_created_gmt = [self stringOrEmptyString:[dict stringForKey:PostRESTKeyDate]];
    self.featuredImage = [self featuredImageFromPostDictionary:dict];
    self.feedID = [dict numberForKey:PostRESTKeyFeedID];
    self.feedItemID = [dict numberForKey:PostRESTKeyFeedItemID];
    self.globalID = [self stringOrEmptyString:[dict stringForKey:PostRESTKeyGlobalID]];
    self.isBlogAtomic = [self siteIsAtomicFromPostDictionary:dict];
    self.isBlogPrivate = [self siteIsPrivateFromPostDictionary:dict];
    self.isFollowing = [[dict numberForKey:PostRESTKeyIsFollowing] boolValue];
    self.isLiked = [[dict numberForKey:PostRESTKeyILike] boolValue];
    self.isReblogged = [[dict numberForKey:PostRESTKeyIsReblogged] boolValue];
    self.isWPCom = [self isWPComFromPostDictionary:dict];
    self.likeCount = [dict numberForKey:PostRESTKeyLikeCount];
    self.permalink = [self stringOrEmptyString:[dict stringForKey:PostRESTKeyURL]];
    self.postID = [dict numberForKey:PostRESTKeyID];
    self.postTitle = [self postTitleFromPostDictionary:dict];
    self.score = [dict numberForKey:PostRESTKeyScore];
    self.siteID = [dict numberForKey:PostRESTKeySiteID];
    self.sortDate = [self sortDateFromPostDictionary:dict];
    self.sortRank = @(self.sortDate.timeIntervalSinceReferenceDate);
    self.status = [self stringOrEmptyString:[dict stringForKey:PostRESTKeyStatus]];
    self.summary = [self postSummaryFromPostDictionary:dict orPostContent:self.content];
    self.tags = [self tagsFromPostDictionary:dict];
    self.isSharingEnabled = [[dict numberForKey:PostRESTKeySharingEnabled] boolValue];
    self.isLikesEnabled = [[dict numberForKey:PostRESTKeyLikesEnabled] boolValue];
    self.organizationID = [dict numberForKeyPath:PostRESTKeyOrganizationID] ?: @0;
    self.canSubscribeComments = [[dict numberForKey:PostRESTKeyCanSubscribeComments] boolValue];
    self.isSubscribedComments = [[dict numberForKey:PostRESTKeyIsSubscribedComments] boolValue];
    self.receivesCommentNotifications = [[dict numberForKey:POSTRESTKeyReceivesCommentNotifications] boolValue];

    if ([dict numberForKey:PostRESTKeyIsSeen]) {
        self.isSeen = [[dict numberForKey:PostRESTKeyIsSeen] boolValue];
        self.isSeenSupported = YES;
    } else {
        self.isSeen = YES;
        self.isSeenSupported = NO;
    }

    // Construct a title if necessary.
    if ([self.postTitle length] == 0 && [self.summary length] > 0) {
        self.postTitle = [self titleFromSummary:self.summary];
    }

    NSDictionary *tags = [self primaryAndSecondaryTagsFromPostDictionary:dict];
    if (tags) {
        self.primaryTag = [tags stringForKey:TagKeyPrimary];
        self.primaryTagSlug = [tags stringForKey:TagKeyPrimarySlug];
        self.secondaryTag = [tags stringForKey:TagKeySecondary];
        self.secondaryTagSlug = [tags stringForKey:TagKeySecondarySlug];
    }

    self.isExternal = [[dict numberForKey:PostRESTKeyIsExternal] boolValue];
    self.isJetpack = [[dict numberForKey:PostRESTKeyIsJetpack] boolValue];
    self.wordCount = [dict numberForKey:PostRESTKeyWordCount];
    self.readingTime = [self readingTimeForWordCount:self.wordCount];

    NSDictionary *railcar = [dict dictionaryForKey:PostRESTKeyRailcar];
    if (railcar) {
        NSError *error;
        NSData *railcarData = [NSJSONSerialization dataWithJSONObject:railcar options:NSJSONWritingPrettyPrinted error:&error];
        self.railcar = [[NSString alloc] initWithData:railcarData encoding:NSUTF8StringEncoding];
    }

    if ([dict arrayForKeyPath:@"discover_metadata.discover_fp_post_formats"]) {
        self.sourceAttribution = [self sourceAttributionFromDictionary:[dict dictionaryForKey:PostRESTKeyDiscoverMetadata]];
    }

    RemoteReaderCrossPostMeta *crossPostMeta = [self crossPostMetaFromPostDictionary:dict];
    if (crossPostMeta) {
        self.crossPostMeta = crossPostMeta;
    }

    return self;
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
            if (url) {
                meta.siteURL = [NSString stringWithFormat:@"%@://%@", url.scheme, url.host];
                meta.postURL = [NSString stringWithFormat:@"%@%@", meta.siteURL, url.path];
                if ([url.fragment hasPrefix:CrossPostMetaCommentPrefix]) {
                    meta.commentURL = [url absoluteString];
                }
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
        NSRange ampRng = [img rangeOfString:@"&" options:NSLiteralSearch range:NSMakeRange(location, [img length] - location)];
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

 @param dict A dictionary representing a post object from the REST API
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

    // Date tagged on is returned by read/tags/%s/posts endpoints.
    NSString *taggedDate = [dict stringForKey:PostRESTKeyTaggedOn];
    if (taggedDate != nil) {
        sortDate = taggedDate;
    }

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
    // Editorial trumps all
    NSString *featuredImage = [self editorialImageFromPostDictionary:dict];

    // Second option is the user specified featured image
    if ([featuredImage length] == 0) {
        featuredImage = [self userSpecifiedFeaturedImageFromPostDictionary:dict];
    }

    // If that's not present look for an image in featured media
    if ([featuredImage length] == 0) {
        featuredImage = [self featuredMediaImageFromPostDictionary:dict];
    }

    // As a last resource lets look for a suitable image in the post content
    if ([featuredImage length] == 0) {
        featuredImage = [self suitableImageFromPostContent:dict];
    }

    featuredImage = [self sanitizeFeaturedImageString:featuredImage];

    return featuredImage;
}

- (NSString *)editorialImageFromPostDictionary:(NSDictionary *)dict {
    return [dict stringForKeyPath:@"editorial.image"];
}

- (NSString *)userSpecifiedFeaturedImageFromPostDictionary:(NSDictionary *)dict {
    return [dict stringForKey:PostRESTKeyFeaturedImage];
}

- (NSString *)featuredMediaImageFromPostDictionary:(NSDictionary *)dict {
    NSDictionary *featuredMedia = [dict dictionaryForKey:PostRESTKeyFeaturedMedia];
    if ([[featuredMedia stringForKey:@"type"] isEqualToString:@"image"]) {
        return [featuredMedia stringForKey:@"uri"];
    }
    return nil;
}

- (NSString *)suitableImageFromPostContent:(NSDictionary *)dict {
    NSString *content = [dict stringForKey:PostRESTKeyContent];
    NSString *imageToDisplay = [DisplayableImageHelper searchPostContentForImageToDisplay:content];
    return [self stringOrEmptyString:imageToDisplay];
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

    return content;
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

- (BOOL)siteIsAtomicFromPostDictionary:(NSDictionary *)dict
{
    NSNumber *isAtomic = [dict numberForKey:PostRESTKeySiteIsAtomic];

    return [isAtomic boolValue];
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
 Formats a post's summary.  The excerpts provided by the REST API contain HTML and have some extra content appened to the end.
 HTML is stripped and the extra bit is removed.

 @param summary The summary to format.
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
    return [string summarized];
}

/**
 Transforms the specified string to plain text.  HTML markup is removed and HTML entities are decoded.

 @param string The string to transform.
 @return The transformed string.
 */
- (NSString *)makePlainText:(NSString *)string
{
    return [string summarized];
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
