#import "WPRichTextView.h"
#import <DTCoreText/DTCoreText.h>
#import "DTTiledLayerWithoutFade.h"
#import "DTAttributedTextContentView.h"
#import "WPTableImageSource.h"
#import "UIImage+Util.h"
#import "WordPress-Swift.h"

static NSTimeInterval const WPRichTextMinimumIntervalBetweenMediaRefreshes = 2;
static CGSize const WPRichTextMinimumSize = {1, 1};
static CGFloat WPRichTextDefaultEmbedRatio = 1.778;
static NSInteger const WPRichTextImageQuality = 65;

@interface WPRichTextView()<DTAttributedTextContentViewDelegate, WPTableImageSourceDelegate>

@property (nonatomic, strong) DTAttributedTextContentView *textContentView;
@property (nonatomic, assign) BOOL willRefreshMediaLayout;
@property (nonatomic, strong) NSMutableArray *mediaArray;
@property (nonatomic, strong) NSMutableArray *mediaIndexPathsPendingDownload;
@property (nonatomic, strong) NSMutableArray *mediaIndexPathsNeedingLayout;
@property (nonatomic, strong) WPTableImageSource *imageSource;
@property (nonatomic, strong) NSDate *dateOfLastMediaRefresh;
@property (nonatomic) BOOL needsCheckPendingDownloadsAfterDelay;
@property (nonatomic, strong, readwrite) NSAttributedString *attributedString;
@property (nonatomic) BOOL shouldPreventPendingMediaLayout;

@end

@implementation WPRichTextView

#pragma mark - LifeCycle Methods

+ (void)initialize
{
    // DTCoreText will cache font descriptors on a background thread. However, because the font cache
    // updated synchronously, the detail view controller ends up waiting for the fonts to load anyway
    // (at least for the first time). We'll have DTCoreText prime its font cache here so things are ready
    // for the detail view, and avoid a perceived lag.
    [DTCoreTextFontDescriptor fontDescriptorWithFontAttributes:nil];
}

+ (NSDictionary *)defaultDTCoreTextOptions
{
    NSString *defaultStyles = @"blockquote {background-color: #EEEEEE; width: 100%; display: block; padding: 8px 5px 10px 0;}";
    DTCSSStylesheet *cssStylesheet = [[DTCSSStylesheet alloc] initWithStyleBlock:defaultStyles];
    return @{
             DTDefaultFontFamily:@"Open Sans",
             DTDefaultLineHeightMultiplier:(IS_IPAD ? @1.6 : @1.4),
             DTDefaultFontSize:(IS_IPAD ? @18 : @16),
             DTDefaultTextColor:[WPStyleGuide littleEddieGrey],
             DTDefaultLinkColor:[WPStyleGuide baseLighterBlue],
             DTDefaultLinkHighlightColor:[WPStyleGuide midnightBlue],
             DTDefaultLinkDecoration:@NO,
             DTDefaultStyleSheet:cssStylesheet
             };
}

- (void)dealloc
{
    _delegate = nil;
    _textContentView.delegate = nil;

    // Avoids lazy init.
    if (_imageSource) {
        _imageSource.delegate = nil;
    }
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _mediaArray = [NSMutableArray array];
        _mediaIndexPathsNeedingLayout = [NSMutableArray array];
        _mediaIndexPathsPendingDownload = [NSMutableArray array];
        _textOptions = [[self class] defaultDTCoreTextOptions];
        _textContentView = [self buildTextContentView];
        [self addSubview:self.textContentView];
        [self configureConstraints];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.textContentView.layouter = nil;
    [self.textContentView relayoutText];
}


#pragma mark - Public methods

- (CGSize)intrinsicContentSize
{
    CGSize size = self.textContentView.intrinsicContentSize;
    return size;
}

- (CGSize)sizeThatFits:(CGSize)sizeToFit
{
    CGSize size = [self.textContentView suggestedFrameSizeToFitEntireStringConstraintedToWidth:sizeToFit.width];
    return size;
}

- (UIEdgeInsets)edgeInsets
{
    return self.textContentView.edgeInsets;
}

- (void)setEdgeInsets:(UIEdgeInsets)edgeInsets
{
    self.textContentView.edgeInsets = edgeInsets;
    [self relayoutTextContentView];
}

- (NSAttributedString *)attributedString
{
    return self.textContentView.attributedString;
}

- (void)setAttributedString:(NSAttributedString *)attributedString
{
    self.textContentView.attributedString = attributedString;
    [self relayoutTextContentView];
}

- (void)setContent:(NSString *)content
{
    if ([content isEqualToString:_content]) {
        return;
    }
    _content = content;

    NSData *data = [_content dataUsingEncoding:NSUTF8StringEncoding];
    self.attributedString = [[NSAttributedString alloc] initWithHTMLData:data
                                                                 options:self.textOptions
                                                      documentAttributes:nil];
}

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    [super setBackgroundColor:backgroundColor];
    self.textContentView.backgroundColor = backgroundColor;
}


#pragma mark - Private Methods

/**
 Sets up the autolayout constraints for subviews.
 */
- (void)configureConstraints
{
    NSDictionary *views = NSDictionaryOfVariableBindings(_textContentView);
    NSDictionary *metrics = @{
        @"minWidth"  : @(WPRichTextMinimumSize.width),
        @"minHeight" : @(WPRichTextMinimumSize.height)
    };
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[_textContentView(>=minWidth)]|"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_textContentView(>=minHeight)]|"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];
    [self setNeedsUpdateConstraints];
}

- (DTAttributedTextContentView *)buildTextContentView
{
    [DTAttributedTextContentView setLayerClass:[DTTiledLayerWithoutFade class]];

    // Needs an initial frame
    DTAttributedTextContentView *textContentView = [[DTAttributedTextContentView alloc] initWithFrame:self.bounds];
    textContentView.translatesAutoresizingMaskIntoConstraints = NO;
    textContentView.delegate = self;
    textContentView.backgroundColor = [UIColor whiteColor];
    textContentView.shouldDrawImages = NO;
    textContentView.shouldDrawLinks = NO;
    textContentView.relayoutMask = DTAttributedTextContentViewRelayoutOnWidthChanged | DTAttributedTextContentViewRelayoutOnHeightChanged;

    return textContentView;
}

- (WPTableImageSource *)imageSource
{
    if (_imageSource) {
        return _imageSource;
    }

    self.imageSource = [[WPTableImageSource alloc] initWithMaxSize:[self maxImageDisplaySize]];
    _imageSource.forceLargerSizeWhenFetching = NO;
    _imageSource.delegate = self;
    _imageSource.photonQuality = WPRichTextImageQuality;

    return _imageSource;
}


#pragma mark - Event Handlers

- (void)linkAction:(DTLinkButton *)sender
{
    if ([self.delegate respondsToSelector:@selector(richTextView:didReceiveLinkAction:)]) {
        [self.delegate richTextView:self didReceiveLinkAction:sender.URL];
    }
}

- (void)imageLinkAction:(WPRichTextImage *)sender
{
    if ([self.delegate respondsToSelector:@selector(richTextView:didReceiveImageLinkAction:)]) {
        [self.delegate richTextView:self didReceiveImageLinkAction:sender];
    }
}


#pragma mark - DTAttributedTextContentView Layout Wrangling

- (void)attributedTextContentView:(DTAttributedTextContentView *)attributedTextContentView
               didDrawLayoutFrame:(DTCoreTextLayoutFrame *)layoutFrame
                        inContext:(CGContextRef)context
{
    // DTCoreText was performing this call in BG. Let's make sure UIKit gets handled on the main thread!
    dispatch_async(dispatch_get_main_queue(), ^{
        [self invalidateIntrinsicContentSize];
    });
}

// Relayout the textContentView after a brief delay.  Used to make sure there are no
// gaps in text due to outdated media frames.
- (void)refreshLayoutAfterDelay
{
    if (self.willRefreshMediaLayout) {
        return;
    }
    self.willRefreshMediaLayout = YES;

    // The first time we're called we're in the middle of updating layout. Refreshing at
    // this point has no effect.  Dispatch async will let us refresh layout in a new loop
    // and correctly update.
    dispatch_async(dispatch_get_main_queue(), ^{
        [self refreshMediaLayout];

        if ([self.delegate respondsToSelector:@selector(richTextViewDidLoadMediaBatch:)]) {
            [self.delegate richTextViewDidLoadMediaBatch:self]; // So the delegate can correct its size.
        }
    });
}

- (void)refreshMediaLayout
{
    [self refreshLayoutForMediaInArray:self.mediaArray];
}

- (CGSize)maxImageDisplaySize
{
    CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
    CGFloat insets = self.edgeInsets.left + self.edgeInsets.right;
    CGFloat side = MAX(CGRectGetWidth(screenRect) - insets, CGRectGetHeight(screenRect) - insets);
    return CGSizeMake(side, side);
}

- (CGSize)displaySizeForMedia:(id<WPRichTextMediaAttachment>)media
{
    CGSize size = [media contentSize];
    if (CGSizeEqualToSize(size, CGSizeMake(1.0, 1.0))) {
        return size;
    }

    // Images get special treatment cos we do not want them to scale.
    if ([media isKindOfClass:[WPRichTextImage class]]) {
        return [self displaySizeForImage:size];
    }

    return [self displaySizeForEmbed:(WPRichTextEmbed *)media];
}

- (CGSize)displaySizeForEmbed:(WPRichTextEmbed *)embed
{
    // If we know the content ratio, use the view's width and compute the height.
    // Otherwise use a defaut ratio of 16:9 (1.778)
    CGFloat ratio = [embed contentRatio];
    if (ratio == 0.0) {
        ratio = WPRichTextDefaultEmbedRatio;
    }

    CGFloat width = CGRectGetWidth(self.bounds) - (self.edgeInsets.left + self.edgeInsets.right);
    CGFloat height = ceilf(width / ratio);

    if (embed.fixedHeight > 0) {
        height = embed.fixedHeight;
    }

    return CGSizeMake(width, height);
}

- (CGSize)displaySizeForImage:(CGSize)size
{
    CGFloat width = size.width;
    CGFloat height = size.height;
    CGFloat ratio = width / height;

    CGFloat maxWidth = CGRectGetWidth(self.bounds) - (self.edgeInsets.left + self.edgeInsets.right);
    CGFloat lineHeight = 16.0; // row height

    // If the width is greater than current max width, shrink it down.
    if (width > maxWidth) {
        width = maxWidth;
        height = width / ratio;
    }

    // if our height is less than line height, render within a text run.
    if (height < lineHeight) {
        return CGSizeMake(width, height);
    }

    // We want the image to be centered, so return its natural height but the max width
    return CGSizeMake(maxWidth, height);
}

- (void)refreshLayoutForMediaAtIndexPaths:(NSArray *)indexPaths
{
    NSMutableArray *arr = [NSMutableArray array];
    for (NSIndexPath *indexPath in indexPaths) {
        NSUInteger index = [indexPath indexAtPosition:0];
        if (index >= [self.mediaArray count]) {
            continue;
        }
        [arr addObject:self.mediaArray[index]];
    }
    [self refreshLayoutForMediaInArray:arr];
}

- (void)refreshLayoutForMediaInArray:(NSArray *)media
{
    BOOL frameChanged = NO;

    for (id<WPRichTextMediaAttachment>item in media) {
        if ([self updateLayoutForMediaItem:item]) {
            frameChanged = YES;
        }
    }

    if (frameChanged) {
        [self relayoutTextContentView];
    }
}

- (BOOL)updateLayoutForMediaItem:(id<WPRichTextMediaAttachment>)media
{
    BOOL frameChanged = NO;
    NSURL *url = media.contentURL;

    CGSize originalSize = media.frame.size;
    CGSize displaySize = [self displaySizeForMedia:media];
    frameChanged = !CGSizeEqualToSize(originalSize, displaySize);

    // update all attachments that matchin this URL (possibly multiple images with same size)
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"contentURL == %@", url];
    for (DTTextAttachment *attachment in [self.textContentView.layoutFrame textAttachmentsWithPredicate:pred]) {
        attachment.originalSize = originalSize;
        attachment.displaySize = displaySize;
    }

    return frameChanged;
}

- (void)relayoutTextContentView
{
    // need to reset the layouter because otherwise we get the old framesetter or
    self.textContentView.layouter = nil;

    // layout might have changed due to image sizes
    [self.textContentView relayoutText];
    [self invalidateIntrinsicContentSize];
}


#pragma mark - WPTableImageSource Delegate Methods

- (void)tableImageSource:(WPTableImageSource *)tableImageSource imageFailedforIndexPath:(NSIndexPath *)indexPath error:(NSError *)error
{
    [self.mediaIndexPathsPendingDownload removeObject:indexPath];
    [self checkPendingMediaDownloads];
}

- (void)tableImageSource:(WPTableImageSource *)tableImageSource imageReady:(UIImage *)image forIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger index = [indexPath indexAtPosition:0];
    if (index >= [self.mediaArray count]) {
        return;
    }
    WPRichTextImage *imageControl = [self.mediaArray objectAtIndex:index];
    [imageControl.imageView setImage:image];

    [self.mediaIndexPathsPendingDownload removeObject:indexPath];
    [self.mediaIndexPathsNeedingLayout addObject:indexPath];
    [self checkPendingMediaDownloads];
}


- (void)preventPendingMediaLayout:(BOOL)prevent
{
    self.shouldPreventPendingMediaLayout = prevent;
    if (!prevent) {
        [self checkPendingMediaDownloads];
    }
}

#pragma mark - Pending Download / Layout 

- (void)checkPendingMediaDownloads
{
    if (self.shouldPreventPendingMediaLayout) {
        return;
    }

    if (!self.dateOfLastMediaRefresh) {
        self.dateOfLastMediaRefresh = [NSDate distantPast];
    }

    NSUInteger count = [self.mediaIndexPathsPendingDownload count];
    NSTimeInterval intervalSinceLastRefresh = fabs([self.dateOfLastMediaRefresh timeIntervalSinceNow]);

    if (intervalSinceLastRefresh < WPRichTextMinimumIntervalBetweenMediaRefreshes && count > 0) {
        // We can have a situation where a few downloads have completed, and one remaining within the alotted interval.
        // Its possible that the remaining download could take a significant amount of time to complete.
        // Rather than waiting a long time to refresh and display the images that are already downloaded
        // Check again after a brief delay.
        if (self.needsCheckPendingDownloadsAfterDelay) {
            return;
        }

        self.needsCheckPendingDownloadsAfterDelay = YES;

        // Note: There is a scenario where more than one block could be queued.
        // Keep this in mind when making future changes.
        dispatch_time_t when = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(WPRichTextMinimumIntervalBetweenMediaRefreshes * NSEC_PER_SEC));
        dispatch_after(when, dispatch_get_main_queue(), ^{
            [self checkPendingMediaDownloadsIfNeeded];
        });
        return;
    }
    self.needsCheckPendingDownloadsAfterDelay = NO;

    [self refreshLayoutForMediaAtIndexPaths:self.mediaIndexPathsNeedingLayout];
    [self.mediaIndexPathsNeedingLayout removeAllObjects];
    self.dateOfLastMediaRefresh = [NSDate date];

    if ([self.delegate respondsToSelector:@selector(richTextViewDidLoadMediaBatch:)]) {
        [self.delegate richTextViewDidLoadMediaBatch:self];
    }
}

- (void)checkPendingMediaDownloadsIfNeeded
{
    // If the flag is no longer set there is nothing to do.
    if (!self.needsCheckPendingDownloadsAfterDelay) {
        return;
    }
    [self checkPendingMediaDownloads];
}


#pragma mark - DTCoreAttributedTextContentView Delegate Methods

- (UIView *)attributedTextContentView:(DTAttributedTextContentView *)attributedTextContentView viewForAttributedString:(NSAttributedString *)string frame:(CGRect)frame
{
    NSDictionary *attributes = [string attributesAtIndex:0 effectiveRange:nil];

    NSURL *URL = [attributes objectForKey:DTLinkAttribute];
    NSString *identifier = [attributes objectForKey:DTGUIDAttribute];

    DTLinkButton *button = [[DTLinkButton alloc] initWithFrame:frame];
    button.URL = URL;
    button.minimumHitSize = CGSizeMake(25, 25); // adjusts it's bounds so that button is always large enough
    button.GUID = identifier;

    // get image with normal link text
    UIImage *normalImage = [attributedTextContentView contentImageWithBounds:frame options:DTCoreTextLayoutFrameDrawingDefault];
    [button setImage:normalImage forState:UIControlStateNormal];

    // get image for highlighted link text
    UIImage *highlightImage = [attributedTextContentView contentImageWithBounds:frame options:DTCoreTextLayoutFrameDrawingDrawLinksHighlighted];
    [button setImage:highlightImage forState:UIControlStateHighlighted];

    // use normal push action for opening URL
    [button addTarget:self action:@selector(linkAction:) forControlEvents:UIControlEventTouchUpInside];

    return button;
}

- (UIView *)attributedTextContentView:(DTAttributedTextContentView *)attributedTextContentView viewForAttachment:(DTTextAttachment *)attachment frame:(CGRect)frame
{
    if (!attachment.contentURL) {
        return [self imagePlaceholderForAttachment:attachment];
    }

    // DTAttributedTextContentView will perform its first render pass with the original width and height (if specified) of the image.
    // However, we don't want gaps in the text while waiting for an image to load so we reset the starting frame.
    // Refresh the layout after a brief delay so that the desired image frame is used while the image is still loading.
    [self refreshLayoutAfterDelay];

    if ([attachment isKindOfClass:[DTImageTextAttachment class]]) {
        return [self imageForAttachment:attachment];
    }

    if ([attachment isKindOfClass:[DTIframeTextAttachment class]]) {
        return [self mediaViewForIframeAttachment:attachment withFrame:frame];
    }

    if ([attachment isKindOfClass:[DTVideoTextAttachment class]]) {
        return [self mediaViewForVideoAttachment:attachment withFrame:frame];
    }

    if ([attachment isKindOfClass:[DTObjectTextAttachment class]]) {
        return [self mediaViewForObjectAttachment:attachment withFrame:frame];
    }

    return [self imagePlaceholderForAttachment:attachment];
}


#pragma mark - Attachment creation

- (WPRichTextImage *)imagePlaceholderForAttachment:(DTTextAttachment *)attachment
{
    WPRichTextImage *imageControl = [[WPRichTextImage alloc] initWithFrame:CGRectMake(0.0, 0.0, 1.0, 1.0)];
    [imageControl.imageView setImage:[UIImage imageWithColor:self.backgroundColor havingSize:CGSizeMake(1.0, 1.0)]];
    imageControl.contentURL = attachment.contentURL;
    [self.mediaArray addObject:imageControl];
    return imageControl;
}

- (WPRichTextImage *)imageForAttachment:(DTTextAttachment *)attachment
{
    DTImageTextAttachment *imageAttachment = (DTImageTextAttachment *)attachment;
    WPRichTextImage *imageControl = [[WPRichTextImage alloc] initWithFrame:CGRectZero];

    CGSize size;
    if ([imageAttachment.image isKindOfClass:[UIImage class]]) {
        [imageControl.imageView setImage:imageAttachment.image];
        size = [self displaySizeForImage:imageAttachment.image.size];
    } else {
        size = CGSizeMake(1.0, 1.0);
    }
    imageControl.frame = CGRectMake(0.0, 0.0, size.width, size.height);

    imageControl.contentURL = attachment.contentURL;
    imageControl.linkURL = attachment.hyperLinkURL;
    [imageControl addTarget:self action:@selector(imageLinkAction:) forControlEvents:UIControlEventTouchUpInside];

    [self.mediaArray addObject:imageControl];

    if (!imageControl.imageView.image) {
        NSUInteger index = [self.mediaArray indexOfObject:imageControl];
        NSIndexPath *indexPath = [NSIndexPath indexPathWithIndex:index];

        [self.mediaIndexPathsPendingDownload addObject:indexPath];
        [self.imageSource fetchImageForURL:imageControl.contentURL
                                  withSize:[self maxImageDisplaySize]
                                 indexPath:indexPath
                                 isPrivate:self.privateContent];
    }

    return imageControl;
}

- (WPRichTextEmbed *)mediaViewForIframeAttachment:(DTTextAttachment *)attachment withFrame:(CGRect)frame
{
    WPRichTextEmbed *embed = [self embedForAttachment:attachment withFrame:frame];
    [embed loadContentURL:attachment.contentURL];
    return embed;
}

- (UIView *)mediaViewForVideoAttachment:(DTTextAttachment *)attachment withFrame:(CGRect)frame
{
    // Get the raw html for the attachment.
    NSString *html = [self HTMLForAttachmentWithSrc:[attachment.contentURL absoluteString] andTag:@"video"];
    WPRichTextEmbed *embed = [self embedForAttachment:attachment withFrame:frame];
    [embed loadHTMLString:html];
    return embed;
}

- (UIView *)mediaViewForObjectAttachment:(DTTextAttachment *)attachment withFrame:(CGRect)frame
{
    NSString *html = [self HTMLForAttachmentWithSrc:[attachment.contentURL absoluteString] andTag:@"object"];
    WPRichTextEmbed *embed = [self embedForAttachment:attachment withFrame:frame];
    [embed loadHTMLString:html];
    return embed;
}

- (WPRichTextEmbed *)embedForAttachment:(DTTextAttachment *)attachment withFrame:(CGRect)frame
{
    WPRichTextEmbed *embed = [[WPRichTextEmbed alloc] initWithFrame:CGRectMake(0.0, 0.0, 1.0, 1.0)];
    embed.contentURL = attachment.contentURL;
    embed.attachmentSize = frame.size;
    embed.success = ^(WPRichTextEmbed *embedControl){
        NSInteger index = [self.mediaArray indexOfObject:embedControl];
        NSIndexPath *indexPath = [NSIndexPath indexPathWithIndex:index];
        [self.mediaIndexPathsNeedingLayout addObject:indexPath];
        [self checkPendingMediaDownloads];
    };
    [self.mediaArray addObject:embed];

    NSString *width = [attachment.attributes stringForKey:@"width"];
    NSString *height = [attachment.attributes stringForKey:@"height"];
    if ([width hasSuffix:@"%"] && ![height hasSuffix:@"%"]) {
        embed.fixedHeight = CGRectGetHeight(frame);
    }

    return embed;
}

- (NSString *)HTMLForAttachmentWithSrc:(NSString *)src andTag:(NSString *)tag
{
    NSString *rawContentString = self.content;

    NSRange rng = [rawContentString rangeOfString:src];
    if (rng.location == NSNotFound) {
        return @""; // Empty string to avoid swift optionals
    }

    NSRange starting = [rawContentString rangeOfString:[NSString stringWithFormat:@"<%@", tag]
                                               options:NSBackwardsSearch | NSCaseInsensitiveSearch
                                                 range:NSMakeRange(0, rng.location)];

    NSRange ending = [rawContentString rangeOfString:[NSString stringWithFormat:@"%@>", tag]
                                             options:NSCaseInsensitiveSearch
                                               range:NSMakeRange(rng.location, [rawContentString length] - rng.location)];

    NSInteger length = (ending.location + ending.length) - starting.location;
    NSRange tagRange = NSMakeRange(starting.location, length);
    NSString *html = [rawContentString substringWithRange:tagRange];

    return html;
}

@end
