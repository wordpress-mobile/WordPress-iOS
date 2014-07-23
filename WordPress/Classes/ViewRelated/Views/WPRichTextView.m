#import "WPRichTextView.h"
#import <DTCoreText/DTCoreText.h>
#import "DTTiledLayerWithoutFade.h"
#import "DTAttributedTextContentView.h"
#import "WPTableImageSource.h"
#import "WPRichTextImageControl.h"
#import "WPRichTextVideoControl.h"
#import "UIImage+Util.h"
#import "VideoThumbnailServiceRemote.h"

static NSUInteger const WPRichTextViewMediaBatchSize = 5;
static NSTimeInterval const WPRichTextMinimumIntervalBetweenMediaRefreshes = 2;

@interface WPRichTextView()<DTAttributedTextContentViewDelegate, WPTableImageSourceDelegate>

@property (nonatomic, strong) DTAttributedTextContentView *textContentView;
@property (nonatomic, assign) BOOL willRefreshMediaLayout;
@property (nonatomic, strong) NSMutableArray *mediaArray;
@property (nonatomic, strong) NSMutableArray *mediaIndexPathsPendingDownload;
@property (nonatomic, strong) NSMutableArray *mediaIndexPathsNeedingLayout;
@property (nonatomic, strong) WPTableImageSource *imageSource;
@property (nonatomic, strong) NSDate *dateOfLastMediaRefresh;
@end

@implementation WPRichTextView

#pragma mark - LifeCycle Methods

+ (void)initialize {
    // DTCoreText will cache font descriptors on a background thread. However, because the font cache
    // updated synchronously, the detail view controller ends up waiting for the fonts to load anyway
    // (at least for the first time). We'll have DTCoreText prime its font cache here so things are ready
    // for the detail view, and avoid a perceived lag.
    [DTCoreTextFontDescriptor fontDescriptorWithFontAttributes:nil];
}

- (void)dealloc
{
    self.delegate = nil;
    self.textContentView.delegate = nil;

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


#pragma mark - Private Methods

/**
 Sets up the autolayout constraints for subviews.
 */
- (void)configureConstraints
{
    NSDictionary *views = NSDictionaryOfVariableBindings(_textContentView);
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[_textContentView]|"
                                                                 options:0
                                                                 metrics:nil
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_textContentView]|"
                                                                 options:0
                                                                 metrics:nil
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

    return _imageSource;
}

- (WPRichTextImageControl *)imageControlForAttachment:(DTImageTextAttachment *)imageAttachment
{
    WPRichTextImageControl *imageControl = [[WPRichTextImageControl alloc] initWithFrame:CGRectZero];

    if ([imageAttachment.image isKindOfClass:[UIImage class]]) {
        [imageControl.imageView setImage:imageAttachment.image];
    }

    CGSize size = [self displaySizeForImage:imageControl.imageView.image];
    imageControl.frame = CGRectMake(0.0, 0.0, size.width, size.height);

    return imageControl;
}


#pragma mark - Event Handlers

- (void)linkAction:(DTLinkButton *)sender
{
    if ([self.delegate respondsToSelector:@selector(richTextView:didReceiveLinkAction:)]) {
        [self.delegate richTextView:self didReceiveLinkAction:sender.URL];
    }
}

- (void)imageLinkAction:(WPRichTextImageControl *)sender
{
    if ([self.delegate respondsToSelector:@selector(richTextView:didReceiveImageLinkAction:)]) {
        [self.delegate richTextView:self didReceiveImageLinkAction:sender];
    }
}

- (void)videoLinkAction:(WPRichTextVideoControl *)sender
{
    if ([self.delegate respondsToSelector:@selector(richTextView:didReceiveVideoLinkAction:)]) {
        [self.delegate richTextView:self didReceiveVideoLinkAction:sender];
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

- (CGSize)displaySizeForImage:(UIImage *)image
{
    if (!image) {
        return CGSizeMake(1.0, 1.0);
    }

    CGFloat width = image.size.width;
    CGFloat height = image.size.height;
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
        WPRichTextImageControl *imageControl = [self.mediaArray objectAtIndex:index];
        [arr addObject:imageControl];
    }
    [self refreshLayoutForMediaInArray:arr];
}

- (void)refreshLayoutForMediaInArray:(NSArray *)images
{
    BOOL frameChanged = NO;

    for (WPRichTextImageControl *imageControl in images) {
        if ([self updateLayoutForMediaItem:imageControl]) {
            frameChanged = YES;
        }
    }

    if (frameChanged) {
        [self relayoutTextContentView];
    }
}

- (BOOL)updateLayoutForMediaItem:(WPRichTextImageControl *)imageControl
{
    BOOL frameChanged = NO;
    NSURL *url = imageControl.contentURL;

    CGSize originalSize = imageControl.frame.size;
    CGSize displaySize = [self displaySizeForImage:imageControl.imageView.image];

    frameChanged = !CGSizeEqualToSize(originalSize, displaySize);

    NSPredicate *pred = [NSPredicate predicateWithFormat:@"contentURL == %@", url];

    // update all attachments that matchin this URL (possibly multiple images with same size)
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
    [self checkPendingImageDownloads];
}

- (void)tableImageSource:(WPTableImageSource *)tableImageSource imageReady:(UIImage *)image forIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger index = [indexPath indexAtPosition:0];
    if (index >= [self.mediaArray count]) {
        return;
    }
    WPRichTextImageControl *imageControl = [self.mediaArray objectAtIndex:index];
    [imageControl.imageView setImage:image];

    [self.mediaIndexPathsPendingDownload removeObject:indexPath];
    [self.mediaIndexPathsNeedingLayout addObject:indexPath];
    [self checkPendingImageDownloads];
}

- (void)checkPendingImageDownloads
{
    if (!self.dateOfLastMediaRefresh) {
        self.dateOfLastMediaRefresh = [NSDate date];
    }

    NSUInteger count = [self.mediaIndexPathsPendingDownload count];
    NSTimeInterval intervalSinceLastRefresh = fabs([self.dateOfLastMediaRefresh timeIntervalSinceNow]);

    if (intervalSinceLastRefresh < WPRichTextMinimumIntervalBetweenMediaRefreshes && count > 0) {
        return;
    }

    [self refreshLayoutForMediaAtIndexPaths:self.mediaIndexPathsNeedingLayout];
    [self.mediaIndexPathsNeedingLayout removeAllObjects];
    self.dateOfLastMediaRefresh = [NSDate date];

    if ([self.delegate respondsToSelector:@selector(richTextViewDidLoadMediaBatch:)]) {
        [self.delegate richTextViewDidLoadMediaBatch:self];
    }
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
        return nil;
    }

    // DTAttributedTextContentView will perform its first render pass with the original width and height (if specified) of the image.
    // However, we don't want gaps in the text while waiting for an image to load so we reset the starting frame.
    // Refresh the layout after a brief delay so that the desired image frame is used while the image is still loading.
    [self refreshLayoutAfterDelay];

    if ([attachment isKindOfClass:[DTImageTextAttachment class]]) {

        DTImageTextAttachment *imageAttachment = (DTImageTextAttachment *)attachment;
        WPRichTextImageControl *imageControl = [self imageControlForAttachment:imageAttachment];
        imageControl.contentURL = attachment.contentURL;
        imageControl.linkURL = attachment.hyperLinkURL;
        [imageControl addTarget:self action:@selector(imageLinkAction:) forControlEvents:UIControlEventTouchUpInside];

        [self.mediaArray addObject:imageControl];

        if (!imageControl.imageView.image) {
            NSUInteger index = [self.mediaArray count] - 1;
            NSIndexPath *indexPath = [NSIndexPath indexPathWithIndex:index];

            [self.mediaIndexPathsPendingDownload addObject:indexPath];
            [self.imageSource fetchImageForURL:imageControl.contentURL
                                      withSize:[self maxImageDisplaySize]
                                     indexPath:indexPath
                                     isPrivate:self.privateContent];
        }

        return imageControl;

    } else {

        WPRichTextVideoControl *videoControl = [[WPRichTextVideoControl alloc] initWithFrame:CGRectMake(0.0, 0.0, 1.0, 1.0)];

        if ([attachment isKindOfClass:[DTVideoTextAttachment class]]) {
            videoControl.isHTMLContent = NO;
        } else if ([attachment isKindOfClass:[DTIframeTextAttachment class]]) {
            videoControl.isHTMLContent = YES;
        } else if ([attachment isKindOfClass:[DTObjectTextAttachment class]]) {
            videoControl.isHTMLContent = YES;
        } else {
            return nil; // Can't handle whatever this is :P
        }

        videoControl.contentURL = attachment.contentURL;
        [videoControl addTarget:self action:@selector(videoLinkAction:) forControlEvents:UIControlEventTouchUpInside];

        [self.mediaArray addObject:videoControl];
        NSUInteger index = [self.mediaArray count] - 1;
        NSIndexPath *indexPath = [NSIndexPath indexPathWithIndex:index];

        VideoThumbnailServiceRemote *service = [[VideoThumbnailServiceRemote alloc] init];
        [service getThumbnailForVideoAtURL:videoControl.contentURL
                                   success:^(NSURL *thumbnailURL, NSString *title) {
                                       videoControl.title = title;
                                       [self.mediaIndexPathsPendingDownload addObject:indexPath];
                                       [self.imageSource fetchImageForURL:thumbnailURL
                                                                 withSize:[self maxImageDisplaySize]
                                                                indexPath:indexPath
                                                                isPrivate:NO];
                                   }
                                   failure:^(NSError *error) {
                                       DDLogError(@"Error retriving video thumbnail: %@", error);
                                       CGFloat side = 200.0;
                                       UIImage *blankImage = [UIImage imageWithColor:[UIColor blackColor] havingSize:CGSizeMake(side, side)];
                                       videoControl.imageView.image = blankImage;
                                       [self updateLayoutForMediaItem:videoControl];
                                   }];

        return videoControl;
    }
}

@end
