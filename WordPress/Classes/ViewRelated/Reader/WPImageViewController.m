#import "WPImageViewController.h"
#import "WordPress-Swift.h"
@import Gridicons;

static CGFloat const MaximumZoomScale = 4.0;
static CGFloat const MinimumZoomScale = 0.1;

@interface WPImageViewController ()<UIScrollViewDelegate, FlingableViewHandlerDelegate>

@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) Media *media;
@property (nonatomic, strong) PHAsset *asset;
@property (nonatomic, strong) id<WPMediaAsset> mediaAsset;
@property (nonatomic, strong) NSData *data;
@property (nonatomic) BOOL isExternal;

@property (nonatomic, assign) BOOL isLoadingImage;
@property (nonatomic, assign) BOOL isFirstLayout;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) CachedAnimatedImageView *imageView;
@property (nonatomic, strong) ImageLoader *imageLoader;
@property (nonatomic, assign) BOOL shouldHideStatusBar;
@property (nonatomic, strong) CircularProgressView *activityIndicatorView;

@property (nonatomic) FlingableViewHandler *flingableViewHandler;
@property (nonatomic, strong) UITapGestureRecognizer *singleTapGesture;
@property (nonatomic, strong) UITapGestureRecognizer *doubleTapGesture;

@end

@implementation WPImageViewController

#pragma mark - LifeCycle Methods

- (instancetype)initWithImage:(UIImage *)image
{
    return [self initWithImage:image andURL:nil];
}

- (instancetype)initWithURL:(NSURL *)url
{
    return [self initWithImage:nil andURL:url];
}

- (instancetype)initWithMedia:(Media *)media
{
    return [self initWithImage:nil andMedia:media];
}

- (instancetype)initWithAsset:(PHAsset *)asset
{
    self = [super init];
    if (self) {
        _asset = asset;
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithGifData:(NSData *)data
{
    self = [super init];
    if (self) {
        _data = data;
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithImage:(UIImage *)image andURL:(NSURL *)url
{
    self = [super init];
    if (self) {
        _image = [image copy];
        _url = url;
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithImage:(UIImage *)image andMedia:(Media *)media
{
    self = [super init];
    if (self) {
        _image = [image copy];
        _media = media;
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithExternalMediaURL:(NSURL *)url
{
    self = [super init];
    if (self) {
        _image = nil;
        _url = url;
        _isExternal = YES;
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithExternalMediaURL:(NSURL *)url andAsset:(id<WPMediaAsset>)asset
{
    self = [super init];
    if (self) {
        _image = nil;
        _url = url;
        _mediaAsset = asset;
        _isExternal = YES;
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    _shouldDismissWithGestures = YES;
    _isFirstLayout = YES;
}

- (void)setIsLoadingImage:(BOOL)isLoadingImage
{
    _isLoadingImage = isLoadingImage;

    if (isLoadingImage) {
        [self.activityIndicatorView startAnimating];
    } else {
        [self.activityIndicatorView stopAnimating];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor blackColor];
    CGRect frame = self.view.frame;
    frame = CGRectMake(0.0f, 0.0f, frame.size.width, frame.size.height);

    [self setupScrollView:frame];
    [self setupImageViewWidth:frame];
    [self setupImageLoader];

    self.doubleTapGesture = [self setupTapGestureWithNumberOfTaps:2 onView:self.imageView];
    self.singleTapGesture = [self setupTapGestureWithNumberOfTaps:1 onView:self.scrollView];
    [self.singleTapGesture requireGestureRecognizerToFail:self.doubleTapGesture];

    [self setupFlingableView];
    [self setupActivityIndicator];
    [self layoutActivityIndicator];

    [self setupAccessibility];

    [self loadImage];
}

- (void)setupActivityIndicator
{
    self.activityIndicatorView = [[CircularProgressView alloc] initWithStyle:CircularProgressViewStyleWhite];
    AccessoryView *errorView = [[AccessoryView alloc] init];
    errorView.imageView.image = [Gridicon iconOfType:GridiconTypeNoticeOutline];
    errorView.label.text = NSLocalizedString(@"Error", @"Generic error.");
    self.activityIndicatorView.errorView = errorView;
}

- (void)layoutActivityIndicator
{
    self.activityIndicatorView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.activityIndicatorView];
    NSArray *constraints = @[
                             [self.activityIndicatorView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
                             [self.activityIndicatorView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor]
                             ];

    [NSLayoutConstraint activateConstraints:constraints];
}

- (void)setupFlingableView
{
    self.flingableViewHandler = [[FlingableViewHandler alloc] initWithTargetView:self.scrollView];
    self.flingableViewHandler.delegate = self;
    self.flingableViewHandler.isActive = self.shouldDismissWithGestures;
}

- (UITapGestureRecognizer *)setupTapGestureWithNumberOfTaps:(NSInteger)taps onView:(UIView*)view
{
    UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                              action:@selector(handleTapGesture:)];
    [gesture setNumberOfTapsRequired:taps];
    [view addGestureRecognizer:gesture];
    return gesture;
}

- (void)setupScrollView:(CGRect)frame {
    self.scrollView = [[UIScrollView alloc] initWithFrame:frame];
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.scrollView.maximumZoomScale = MaximumZoomScale;
    self.scrollView.minimumZoomScale = MinimumZoomScale;
    self.scrollView.scrollsToTop = NO;
    self.scrollView.delegate = self;
    [self.view addSubview:self.scrollView];
}

- (void)setupImageViewWidth:(CGRect)frame
{
    self.imageView = [[CachedAnimatedImageView alloc] initWithFrame:frame];
    self.imageView.gifStrategy = GIFStrategyLargeGIFs;
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.imageView.shouldShowLoadingIndicator = NO;
    self.imageView.userInteractionEnabled = YES;
    [self.scrollView addSubview:self.imageView];
}

- (void)setupImageLoader
{
    self.imageLoader = [[ImageLoader alloc] initWithImageView:self.imageView gifStrategy:GIFStrategyLargeGIFs];
}

- (void)loadImage
{
    if (self.isLoadingImage) {
        return;
    }

    if (self.image != nil) {
        [self updateImageView];
    } else if (self.url && self.isExternal) {
        [self loadImageFromExternalURL];
    } else if (self.url) {
        [self loadImageFromURL];
    } else if (self.media) {
        [self loadImageFromMedia];
    } else if (self.asset) {
        [self loadImageFromPHAsset];
    } else if (self.data) {
        [self loadImageFromGifData];
    }
}

- (void)updateImageView
{
    self.imageView.image = self.image;
    [self.imageView sizeToFit];
    self.scrollView.contentSize = self.imageView.image.size;
    [self centerImage];
}

- (void)loadImageFromURL
{
    self.isLoadingImage = YES;
    __weak __typeof__(self) weakSelf = self;
    [_imageView downloadImageUsingRequest:[NSURLRequest requestWithURL:self.url]
                      placeholderImage:self.image
                               success:^(UIImage *image) {
                                   weakSelf.image = image;
                                   [weakSelf updateImageView];
                                   weakSelf.isLoadingImage = NO;
                               } failure:^(NSError *error) {
                                   DDLogError(@"Error loading image: %@", error);
                                   [weakSelf.activityIndicatorView showError];
                               }];
}

- (void)loadImageFromMedia
{
    self.imageView.image = self.image;
    self.isLoadingImage = YES;
    __weak __typeof__(self) weakSelf = self;
    [self.imageLoader loadImageFromMedia:self.media preferredSize:CGSizeZero placeholder:self.image success:^{
        weakSelf.isLoadingImage = NO;
        weakSelf.image = weakSelf.imageView.image;
        [weakSelf updateImageView];
    } error:^(NSError * _Nullable error) {
        [weakSelf.activityIndicatorView showError];
        DDLogError(@"Error loading image: %@", error);
    }];
}

- (void)loadImageFromPHAsset
{
    self.imageView.image = self.image;
    self.isLoadingImage = YES;
    __weak __typeof__(self) weakSelf = self;
    [self.imageLoader loadImageFromPHAsset:self.asset preferredSize:CGSizeZero placeholder:self.image success:^{
        weakSelf.isLoadingImage = NO;
        weakSelf.image = weakSelf.imageView.image;
        [weakSelf updateImageView];
    } error:^(NSError * _Nullable error) {
        [weakSelf.activityIndicatorView showError];
        DDLogError(@"Error loading image: %@", error);
    }];
}

- (void)loadImageFromGifData
{
    self.isLoadingImage = YES;

    __weak __typeof__(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.image = [[UIImage alloc] initWithData: self.data];
        [weakSelf updateImageView];
    });
    [self.imageView setAnimatedImage:self.data success:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.isLoadingImage = NO;
        });
    }];
}

- (void)loadImageFromExternalURL
{
    self.isLoadingImage = YES;

    __weak __typeof__(self) weakSelf = self;
    [self.imageLoader loadImageWithURL:self.url
                               success:^{
                                   weakSelf.isLoadingImage = NO;
                                   weakSelf.image = weakSelf.imageView.image;
                                   [weakSelf updateImageView];
                               } error:^(NSError * _Nullable error) {
                                   [weakSelf.activityIndicatorView showError];
                                   DDLogError(@"Error loading image: %@", error);
                               }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self hideBars:YES animated:animated];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    if (self.isFirstLayout) {
        [self centerImage];
        self.isFirstLayout = NO;
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self hideBars:NO animated:animated];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [self centerImage];
}

- (BOOL)prefersHomeIndicatorAutoHidden
{
    return self.shouldHideStatusBar;
}

#pragma mark - Instance Methods

- (id<WPMediaAsset>)mediaAsset
{
    if (_mediaAsset) {
        return _mediaAsset;
    }

    if (self.asset) {
        return self.asset;
    }
    if (self.media) {
        return self.media;
    }

    return nil;
}

- (void)setShouldDismissWithGestures:(BOOL)shouldDismissWithGestures
{
    _shouldDismissWithGestures = shouldDismissWithGestures;
    self.flingableViewHandler.isActive = shouldDismissWithGestures;
}

- (void)hideBars:(BOOL)hide animated:(BOOL)animated
{
    self.shouldHideStatusBar = hide;

    // Force an update of the status bar appearance and visiblity
    if (animated) {
        [UIView animateWithDuration:0.3
                         animations:^{
                             [self setNeedsStatusBarAppearanceUpdate];
                             [self setNeedsUpdateOfHomeIndicatorAutoHidden];
                         }];
    } else {
        [self setNeedsStatusBarAppearanceUpdate];

        [self setNeedsUpdateOfHomeIndicatorAutoHidden];
    }
}

- (void)centerImage
{
    CGFloat scaleWidth = CGRectGetWidth(self.scrollView.frame) / self.imageView.image.size.width;
    CGFloat scaleHeight = CGRectGetHeight(self.scrollView.frame) / self.imageView.image.size.height;

    self.scrollView.minimumZoomScale = MIN(scaleWidth, scaleHeight);
    self.scrollView.zoomScale = self.scrollView.minimumZoomScale;

    [self scrollViewDidZoom:self.scrollView];
}

- (void)handleTapGesture:(UITapGestureRecognizer *)tapGesture
{
    if ([tapGesture isEqual:self.singleTapGesture]) {
        [self handleImageTappedWith:tapGesture];
    } else if ([tapGesture isEqual:self.doubleTapGesture]) {
        [self handleImageDoubleTappedWidth:tapGesture];
    }
}

- (void)handleImageTappedWith:(UITapGestureRecognizer *)tgr
{
    if (self.shouldDismissWithGestures) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)handleImageDoubleTappedWidth:(UITapGestureRecognizer *)tgr
{
    if (self.scrollView.zoomScale > self.scrollView.minimumZoomScale) {
        [self.scrollView setZoomScale:self.scrollView.minimumZoomScale animated:YES];
        return;
    }

    CGPoint point = [tgr locationInView:self.imageView];
    CGSize size = self.scrollView.frame.size;

    CGFloat w = size.width / self.scrollView.maximumZoomScale;
    CGFloat h = size.height / self.scrollView.maximumZoomScale;
    CGFloat x = point.x - (w / 2.0f);
    CGFloat y = point.y - (h / 2.0f);

    CGRect rect = CGRectMake(x, y, w, h);
    [self.scrollView zoomToRect:rect animated:YES];
}

#pragma mark - UIScrollView Delegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    if (self.imageView.image) {
        return self.imageView;
    }
    return nil;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    CGSize size = scrollView.frame.size;
    CGRect frame = self.imageView.frame;

    if (frame.size.width < size.width) {
        frame.origin.x = (size.width - frame.size.width) / 2;
    } else {
        frame.origin.x = 0;
    }

    if (frame.size.height < size.height) {
        frame.origin.y = (size.height - frame.size.height) / 2;
    } else {
        frame.origin.y = 0;
    }

    self.imageView.frame = frame;

    [self updateFlingableViewHandlerActiveState];
}

- (void)updateFlingableViewHandlerActiveState
{
    if (!self.shouldDismissWithGestures) {
        return;
    }
    BOOL isScrollViewZoomedOut = (self.scrollView.zoomScale == self.scrollView.minimumZoomScale);

    self.flingableViewHandler.isActive = isScrollViewZoomedOut;
}

#pragma mark - Status bar management

- (BOOL)prefersStatusBarHidden
{
    return self.shouldHideStatusBar;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation
{
    return UIStatusBarAnimationFade;
}

#pragma mark - Static Helpers

+ (BOOL)isUrlSupported:(NSURL *)url
{
    // Safeguard
    if (!url) {
        return NO;
    }

    // We only support: PNG + JPG + JPEG + GIF
    NSString *absoluteURL = url.absoluteString;

    NSArray *types = @[@".png", @".jpg", @".gif", @".jpeg"];
    for (NSString *type in types) {
        if (NSNotFound != [[absoluteURL lowercaseString] rangeOfString:type].location) {
            return YES;
        }
    }

    return NO;
}

#pragma mark - FlingableViewHandlerDelegate

- (void)flingableViewHandlerDidBeginRecognizingGesture:(FlingableViewHandler *)handler
{
    self.scrollView.multipleTouchEnabled = NO;
}

- (void)flingableViewHandlerDidEndRecognizingGesture:(FlingableViewHandler *)handler {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self dismissViewControllerAnimated:YES completion:nil];
    });
}

- (void)flingableViewHandlerWasCancelled:(FlingableViewHandler *)handler
{
    self.scrollView.multipleTouchEnabled = YES;
}

#pragma mark - Accessibility

- (void)setupAccessibility
{
    self.imageView.isAccessibilityElement = YES;
    self.imageView.accessibilityTraits = UIAccessibilityTraitImage;
}

- (BOOL)accessibilityPerformEscape
{
    // Dismiss when self receives the VoiceOver escape gesture (Z). This does not seem to happen
    // automatically if self is presented modally by itself (i.e. not inside a
    // UINavigationController).
    [self dismissViewControllerAnimated:YES completion:nil];
    return YES;
}

@end
