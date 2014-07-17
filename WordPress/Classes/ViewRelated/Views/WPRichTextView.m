#import "WPRichTextView.h"
#import <DTCoreText/DTCoreText.h>
#import "DTTiledLayerWithoutFade.h"
#import "DTAttributedTextContentView.h"
#import "ReaderMediaQueue.h"
#import "ReaderMediaView.h"
#import "ReaderImageView.h"
#import "ReaderVideoView.h"
#import "UIImage+Util.h"


@interface WPRichTextView()<DTAttributedTextContentViewDelegate, ReaderMediaQueueDelegate>

@property (nonatomic, strong) DTAttributedTextContentView *textContentView;
@property (nonatomic, assign) BOOL willRefreshMediaLayout;
@property (nonatomic, strong) NSMutableArray *mediaArray;
@property (nonatomic, strong) ReaderMediaQueue *mediaQueue;

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
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _mediaArray = [NSMutableArray array];
        _mediaQueue = [[ReaderMediaQueue alloc] initWithDelegate:self];
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


#pragma mark - Event Handlers

- (void)linkAction:(DTLinkButton *)sender
{
    if ([self.delegate respondsToSelector:@selector(richTextView:didReceiveLinkAction:)]) {
        [self.delegate richTextView:self didReceiveLinkAction:sender.URL];
    }
}

- (void)imageLinkAction:(ReaderImageView *)sender
{
    if ([self.delegate respondsToSelector:@selector(richTextView:didReceiveImageLinkAction:)]) {
        [self.delegate richTextView:self didReceiveImageLinkAction:sender];
    }
}

- (void)videoLinkAction:(ReaderVideoView *)sender
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

- (void)handleMediaViewLoaded:(ReaderMediaView *)mediaView
{
    BOOL frameChanged = [self updateMediaLayout:mediaView];
    if (frameChanged) {
        [self relayoutTextContentView];
    }
}

- (BOOL)updateMediaLayout:(ReaderMediaView *)imageView
{
    BOOL frameChanged = NO;
    NSURL *url = imageView.contentURL;

    CGSize originalSize = imageView.frame.size;
    CGSize imageSize = imageView.image.size;

    if (imageView.image) {
        CGFloat ratio = imageSize.width / imageSize.height;
        CGFloat width = self.frame.size.width;
        CGFloat availableWidth = width - (self.textContentView.edgeInsets.left + self.textContentView.edgeInsets.right);

        imageSize.width = availableWidth;
        imageSize.height = roundf(width / ratio) + imageView.edgeInsets.top;
    } else {
        imageSize = CGSizeMake(0.0f, 0.0f);
    }

    // Widths should always match
    if (imageSize.height != originalSize.height) {
        frameChanged = YES;
    }

    NSPredicate *pred = [NSPredicate predicateWithFormat:@"contentURL == %@", url];

    // update all attachments that matchin this URL (possibly multiple images with same size)
    for (DTTextAttachment *attachment in [self.textContentView.layoutFrame textAttachmentsWithPredicate:pred]) {
        attachment.originalSize = originalSize;
        attachment.displaySize = imageSize;
    }

    return frameChanged;
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

        if ([self.delegate respondsToSelector:@selector(richTextViewDidLoadAllMedia:)]) {
            [self.delegate richTextViewDidLoadAllMedia:self]; // So the delegate can correct its size.
        }
    });
}

- (void)refreshMediaLayout
{
    [self refreshMediaLayoutInArray:self.mediaArray];
}

- (void)refreshMediaLayoutInArray:(NSArray *)mediaArray
{
    BOOL frameChanged = NO;

    for (ReaderMediaView *mediaView in mediaArray) {
        if ([self updateMediaLayout:mediaView]) {
            frameChanged = YES;
        }
    }
    if (frameChanged) {
        [self relayoutTextContentView];
    }
}

- (void)relayoutTextContentView
{
    // need to reset the layouter because otherwise we get the old framesetter or
    self.textContentView.layouter = nil;

    // layout might have changed due to image sizes
    [self.textContentView relayoutText];
    [self invalidateIntrinsicContentSize];
}


#pragma mark - ReaderMediaQueueDelegate methods

- (void)readerMediaQueue:(ReaderMediaQueue *)mediaQueue didLoadBatch:(NSArray *)batch
{
    [self refreshMediaLayoutInArray:batch];
    if ([self.delegate respondsToSelector:@selector(richTextViewDidLoadAllMedia:)]) {
        [self.delegate richTextViewDidLoadAllMedia:self];
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

    // The textContentView will render the first time with the original frame, and then update when media loads.
    // To avoid showing gaps in the layout due to the original attachment sizes, relayout the view after a brief delay.
    [self refreshLayoutAfterDelay];

    CGFloat width = CGRectGetWidth(self.textContentView.frame);
    CGFloat availableWidth = width - (self.textContentView.edgeInsets.left + self.textContentView.edgeInsets.right);

    // The ReaderImageView view will conform to the width constraints of the _textContentView. We want the image itself to run out to the edges,
    // so position it offset by the inverse of _textContentView's edgeInsets.
    // Remeber to add an extra 10px to the frame to preserve aspect ratio.
    UIEdgeInsets edgeInsets = self.textContentView.edgeInsets;
    edgeInsets.left = 0.0 - edgeInsets.left;
    edgeInsets.top = 0.0;
    edgeInsets.right = 0.0 - edgeInsets.right;
    edgeInsets.bottom = 0.0;

    if ([attachment isKindOfClass:[DTImageTextAttachment class]]) {

        DTImageTextAttachment *imageAttachment = (DTImageTextAttachment *)attachment;

        if ([imageAttachment.image isKindOfClass:[UIImage class]]) {
            UIImage *image = imageAttachment.image;

            CGFloat ratio = image.size.width / image.size.height;
            frame.size.width = availableWidth;
            frame.size.height = roundf(width / ratio);

            // offset the top edge inset keeping the image from bumping the text above it.
            frame.size.height += edgeInsets.top;
        } else {
            // minimal frame to suppress drawing context errors with 0 height or width.
            frame.size.width = 1.0;
            frame.size.height = 1.0;
        }

        ReaderImageView *imageView = [[ReaderImageView alloc] initWithFrame:frame];
        imageView.edgeInsets = edgeInsets;

        [_mediaArray addObject:imageView];
        imageView.linkURL = attachment.hyperLinkURL;
        [imageView addTarget:self action:@selector(imageLinkAction:) forControlEvents:UIControlEventTouchUpInside];

        if ([imageAttachment.image isKindOfClass:[UIImage class]]) {
            [imageView setImage:imageAttachment.image];
        } else {

            [self.mediaQueue enqueueMedia:imageView
                                  withURL:attachment.contentURL
                         placeholderImage:nil
                                     size:CGSizeMake(width, 0.0f) // Passing zero for height to get the correct aspect ratio
                                isPrivate:self.privateContent
                                  success:nil
                                  failure:nil];
        }

        return imageView;

    } else {

        ReaderVideoContentType videoType;

        if ([attachment isKindOfClass:[DTVideoTextAttachment class]]) {
            videoType = ReaderVideoContentTypeVideo;
        } else if ([attachment isKindOfClass:[DTIframeTextAttachment class]]) {
            videoType = ReaderVideoContentTypeIFrame;
        } else if ([attachment isKindOfClass:[DTObjectTextAttachment class]]) {
            videoType = ReaderVideoContentTypeEmbed;
        } else {
            return nil; // Can't handle whatever this is :P
        }

        // we won't show the vid until we've loaded its thumb.
        // minimal frame to suppress drawing context errors with 0 height or width.
        frame.size.width = 1.0;
        frame.size.height = 1.0;

        ReaderVideoView *videoView = [[ReaderVideoView alloc] initWithFrame:frame];
        videoView.edgeInsets = edgeInsets;

        [_mediaArray addObject:videoView];
        [videoView setContentURL:attachment.contentURL ofType:videoType success:^(id readerVideoView) {
            [self handleMediaViewLoaded:readerVideoView];
        } failure:^(id readerVideoView, NSError *error) {
            // if the image is 404, just show a black image.
            ReaderVideoView *videoView = (ReaderVideoView *)readerVideoView;
            videoView.image = [UIImage imageWithColor:[UIColor blackColor] havingSize:CGSizeMake(2.0f, 1.0f)];
            [self handleMediaViewLoaded:readerVideoView];
        }];
        
        [videoView addTarget:self action:@selector(videoLinkAction:) forControlEvents:UIControlEventTouchUpInside];
        
        return videoView;
    }
}

@end
