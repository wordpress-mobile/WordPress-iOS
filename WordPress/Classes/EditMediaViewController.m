//
//  EditMediaViewController.m
//  WordPress
//
//  Created by DX074-XL on 2013-09-05.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "EditMediaViewController.h"
#import "Media.h"
#import "WPImageSource.h"
#import "WPKeyboardToolbar.h"
#import "WPKeyboardToolbarWithoutGradient.h"
#import "WPStyleGuide.h"
#import "WPLoadingView.h"
#import <objc/runtime.h>
#import "UIImage+ImageEffects.h"
#import "UIImage+Resize.h"
#import <MediaPlayer/MediaPlayer.h>

@interface BlurView : UIView
@property (nonatomic, strong) UIToolbar *toolbar;
@end

static NSUInteger const AlertDiscardChanges = 500;

@interface UITextView (Placeholder) <UITextViewDelegate>

@property (nonatomic, weak) NSString *placeholder;

- (NSString*)enteredText;

@end

@interface EditMediaViewController () <WPKeyboardToolbarDelegate, UIGestureRecognizerDelegate, UIAlertViewDelegate, UITextViewDelegate, UITextFieldDelegate>

@property (nonatomic, strong) Media *media;
@property (nonatomic, assign) BOOL isShowingEditFields;
@property (nonatomic, strong) WPLoadingView *loadingView;
@property (nonatomic, weak) UIImageView *arrow;
@property (nonatomic, assign) CGFloat currentKeyboardHeight;
@property (nonatomic, strong) MPMoviePlayerController *videoPlayer;

@property (weak, nonatomic) IBOutlet UIView *editFieldsContainer;
@property (weak, nonatomic) IBOutlet UIScrollView *editFieldsScrollView;
@property (weak, nonatomic) IBOutlet UIScrollView *imageScrollView;
@property (weak, nonatomic) IBOutlet UIView *editContainerView;
@property (weak, nonatomic) IBOutlet UIImageView *mediaImageview;
@property (weak, nonatomic) IBOutlet UITextField *titleTextfield;
@property (weak, nonatomic) IBOutlet UITextField *captionTextfield;
@property (weak, nonatomic) IBOutlet UITextView *descriptionTextview;
@property (weak, nonatomic) IBOutlet UILabel *createdDateLabel;
@property (weak, nonatomic) IBOutlet UILabel *dimensionsLabel;
@property (weak, nonatomic) IBOutlet UIButton *editingBar;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *captionLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;


@end

@implementation EditMediaViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id)initWithMedia:(Media*)media {
    self = [super init];
    if (self) {
        _media = media;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _isShowingEditFields = NO;
    
    self.title = @"Edit Media";
    
    _editFieldsScrollView.contentSize = CGSizeMake(_editFieldsScrollView.frame.size.width, CGRectGetMaxY(_editFieldsContainer.frame));
    [_editFieldsScrollView addSubview:_editFieldsContainer];
    
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageDoubleTapped:)];
    doubleTap.delegate = self;
    doubleTap.numberOfTapsRequired = 2;
    [_mediaImageview addGestureRecognizer:doubleTap];
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageTapped:)];
    singleTap.delegate = self;
    singleTap.numberOfTapsRequired = 1;
    [singleTap requireGestureRecognizerToFail:doubleTap];
    [_mediaImageview addGestureRecognizer:singleTap];
    
    UIPanGestureRecognizer *panRecogniser = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(editingBarPanned:)];
    panRecogniser.delegate = self;
    [_editingBar addGestureRecognizer:panRecogniser];
    
    UIImageView *arrow = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon_white_arrow_up"]];
    _arrow = arrow;
    _arrow.center = self.editingBar.center;
    _arrow.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [self.editingBar addSubview:_arrow];
    [_editingBar addTarget:self action:@selector(barTapped:) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Save", @"") style:UIBarButtonItemStyleBordered target:self action:@selector(savePressed)];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", @"") style:UIBarButtonItemStylePlain target:self action:@selector(cancelButtonPressed)];
    
    self.titleLabel.font = [WPStyleGuide tableviewSectionHeaderFont];
    self.captionLabel.font = self.titleLabel.font;
    self.descriptionLabel.font = self.titleLabel.font;
    
    self.titleTextfield.font = [WPStyleGuide regularTextFont];
    self.captionTextfield.font = self.titleTextfield.font;
    self.descriptionTextview.font = self.titleTextfield.font;
    self.createdDateLabel.font = self.titleTextfield.font;
    self.dimensionsLabel.font = self.titleTextfield.font;
    
    self.titleTextfield.delegate = self;
    self.captionTextfield.delegate = self;
    self.descriptionTextview.delegate = self;
    
    self.imageScrollView.minimumZoomScale = 0.5f;
    self.imageScrollView.maximumZoomScale = 6.0f;
    self.imageScrollView.delegate = self;
    
    UIColor *color = [UIColor colorWithWhite:1.0f alpha:0.5f];
    _titleTextfield.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Title" attributes:@{NSForegroundColorAttributeName: color}];
    _captionTextfield.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Caption" attributes:@{NSForegroundColorAttributeName: color}];
    
    //Align the textview text with all the textfields
    _descriptionTextview.contentInset = UIEdgeInsetsMake(0, -4, 0, 0);
    
    [self applyLayoutForMedia];
    [self applyLayout];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    BlurView *blur = [[BlurView alloc] initWithFrame:_editContainerView.bounds];
    blur.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [_editContainerView insertSubview:blur atIndex:0];
    
    _mediaImageview.userInteractionEnabled = false;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (_videoPlayer && !_videoPlayer.fullscreen) {
        [_videoPlayer stop];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if ([_media.mediaType isEqualToString:@"image"]) {
        [self loadMediaImage];
    } else {
        [self setupVideoPlayer];
    }
}

- (void)viewDidLayoutSubviews {
    [self layoutEditOverlay];
}

- (void)layoutEditOverlay {
    BOOL isLandscape = UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation);
    CGPoint containerOrigin, scrollViewOrigin;
    CGSize containerSize, scrollViewSize;

    // Editing slides out from the right
    if (IS_IPAD && isLandscape) {
        _editingBar.frame = CGRectMake(0, 0, 44, self.view.bounds.size.height);
        CGFloat closedXoffset = self.view.bounds.size.width - _editingBar.frame.size.width;
        CGFloat openedXoffset = self.view.bounds.size.width - _editContainerView.frame.size.width;
        CGFloat currentXoffset = _isShowingEditFields ? openedXoffset : closedXoffset;
        containerSize = CGSizeMake(320 + _editingBar.frame.size.width, self.view.bounds.size.height);
        containerOrigin = CGPointMake(currentXoffset, 0);
        scrollViewSize = CGSizeMake(320 + 10, self.view.bounds.size.height);
        scrollViewOrigin = CGPointMake(_editingBar.frame.size.width - 10, _editingBar.frame.size.width);
    
        _arrow.transform = CGAffineTransformMakeRotation(3*M_PI/2);
        
    } else {
        // Editing slides from the bottom
        _editingBar.frame = CGRectMake(0, 0, self.view.bounds.size.width, 44);
        CGFloat closedYOffset = self.view.bounds.size.height - _editingBar.frame.size.height;
        CGFloat openedYOffset = isLandscape ? 0 : self.view.bounds.size.height - _editContainerView.frame.size.height;
        CGFloat currentYOffset = _isShowingEditFields ? openedYOffset : closedYOffset;
        CGFloat scrollViewHeight = isLandscape ? self.view.bounds.size.height - _editingBar.frame.size.height : _editContainerView.frame.size.height - _editingBar.frame.size.height;
        // In iOS 6 viewDidLayoutSubviews is called after the keyboardWillShowNotification
        if (!IS_IOS7) {
            scrollViewHeight -= _currentKeyboardHeight;
        }
        containerSize = CGSizeMake(self.view.bounds.size.width, 370);
        containerOrigin = CGPointMake(0, currentYOffset);
        scrollViewSize = CGSizeMake(containerSize.width, scrollViewHeight);
        scrollViewOrigin = CGPointMake(0, _editingBar.frame.size.height);
        _arrow.transform = CGAffineTransformMakeRotation(0);
    }
    
    _editContainerView.frame = (CGRect) {
        .origin = containerOrigin,
        .size = containerSize
    };
    _editFieldsScrollView.frame = (CGRect) {
        .origin = scrollViewOrigin,
        .size = scrollViewSize
    };
    
    _arrow.center = _editingBar.center;
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
}

- (void)imageTapped:(UIGestureRecognizer*)sender {
    if (_isShowingEditFields) {
        [self toggleEditBar];
    }
}

- (void)imageDoubleTapped:(UIGestureRecognizer*)sender {
    if (_imageScrollView.zoomScale != 1) {
        [UIView animateWithDuration:0.3 animations:^{
            [_imageScrollView setZoomScale:1];
        }];
    } else {
        [UIView animateWithDuration:0.3 animations:^{
            [_imageScrollView setZoomScale:2.0f];
        }];
    }
}

- (void)editingBarPanned:(UIPanGestureRecognizer*)sender {
    BOOL isLandscape = UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation);
    CGFloat translation = (IS_IPAD && isLandscape) ? [sender translationInView:self.view].x : [sender translationInView:self.view].y;
    CGFloat maxOffset = (IS_IPAD && isLandscape) ? self.view.frame.size.width - _editingBar.frame.size.width : self.view.frame.size.height - _editingBar.frame.size.height;
    CGFloat minOffset = isLandscape ? 0 : self.view.bounds.size.height - _editContainerView.frame.size.height;
    minOffset = (IS_IPAD && isLandscape) ? self.view.bounds.size.width - _editContainerView.frame.size.width : minOffset;
    static CGFloat threshold = 50.0f;
    static CGFloat currentOrigin;

    switch (sender.state) {
        case UIGestureRecognizerStateBegan:
            currentOrigin = IS_IPAD && isLandscape ? _editContainerView.frame.origin.x: _editContainerView.frame.origin.y;
            break;
        case UIGestureRecognizerStateChanged:
            if ((currentOrigin + translation) >= minOffset &&
                (currentOrigin + translation) <= maxOffset) {
                CGPoint originChange;
                if (IS_IPAD && isLandscape) {
                    originChange = CGPointMake(currentOrigin + translation, 0);
                } else {
                    originChange = CGPointMake(0, currentOrigin + translation);
                }
                _editContainerView.frame = (CGRect) {
                    .origin = originChange,
                    .size = _editContainerView.frame.size
                };
            }
            break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
            // Toggle editing when within threshold
            if ((currentOrigin + translation) <= (minOffset + threshold) ||
                (currentOrigin + translation) >= (maxOffset - threshold)) {
                _isShowingEditFields = !((currentOrigin + translation) <= (minOffset + threshold));

            // Toggle if we're moving fast enough
            } else {
                CGFloat velocity = (IS_IPAD && isLandscape) ? [sender velocityInView:self.view].x : [sender velocityInView:self.view].y;
                _isShowingEditFields = velocity > 10.0f;
            }
            
            [self toggleEditBar];
            
        default:;
    }
}

- (void)barTapped:(id)sender {
    [self toggleEditBar];
}


- (void)toggleEditBar {
    _isShowingEditFields = !_isShowingEditFields;
    
    if (!_isShowingEditFields) {
        [[self currentFirstResponder] resignFirstResponder];
    }
    
    [UIView animateWithDuration:0.3f animations:^{
        [self layoutEditOverlay];
    } completion:nil];
}

- (void)applyLayoutForMedia
{
    
    [self.titleTextfield setText:_media.title];
    [self.titleTextfield setPlaceholder:NSLocalizedString(@"Title", @"")];
    
    [self.captionTextfield setText:_media.caption];
    [self.captionTextfield setPlaceholder:NSLocalizedString(@"Caption", @"")];
    
    [self.descriptionTextview setText:_media.desc];
    [self.descriptionTextview setPlaceholder:NSLocalizedString(@"Description", @"")];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    NSString *stringFromDate = [dateFormatter stringFromDate:_media.creationDate];
    [self.createdDateLabel setText: [NSString stringWithFormat:@"Created %@", stringFromDate]];
    
    [self.dimensionsLabel setText:[NSString stringWithFormat:@"%@x%@ px", _media.width, _media.height]];
    
    _mediaImageview.image = [UIImage imageNamed:[@"media_" stringByAppendingString:_media.mediaType]];
    
    if ([_media.mediaType isEqualToString:@"movie"]) {
        self.title = NSLocalizedString(@"Video", @"");
    }
}

- (void)setupVideoPlayer {
    NSURL *videoPath;
    if (_media.localURL) {
        videoPath = [NSURL fileURLWithPath:_media.localURL];
    } else {
        videoPath = [NSURL URLWithString:_media.remoteURL];
    }
    
    MPMoviePlayerController *videoPlayer = [[MPMoviePlayerController alloc] initWithContentURL:videoPath];
    _videoPlayer = videoPlayer;
    _videoPlayer.view.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height - _editingBar.frame.size.height);
    _videoPlayer.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view insertSubview:videoPlayer.view belowSubview:_editContainerView];
    _videoPlayer.movieSourceType = MPMovieSourceTypeFile;
    _videoPlayer.shouldAutoplay = false;
    [_videoPlayer prepareToPlay];
}

- (NSString *)saveFullsizeImageToDisk:(UIImage*)image imageName:(NSString *)imageName {
    NSString *docsDirectory = (NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true))[0];
    NSData *imageData = UIImageJPEGRepresentation(image, 1);
    NSString *path = [docsDirectory stringByAppendingPathComponent:imageName];
    BOOL success = [[NSFileManager defaultManager] createFileAtPath:path contents:imageData attributes:nil];
    if (success) {
        return path;
    }
    return nil;
}

- (void)loadMediaImage {
    if (_media.localURL && [[NSFileManager defaultManager] fileExistsAtPath:_media.localURL isDirectory:0]) {
        _mediaImageview.contentMode = UIViewContentModeScaleAspectFit;
        _mediaImageview.image = [[UIImage alloc] initWithContentsOfFile:_media.localURL];
        _mediaImageview.userInteractionEnabled = true;
        return;
    }
    
    UIActivityIndicatorView *loading = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    loading.center = self.view.center;
    loading.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin
    | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    loading.tag = 1337;
    [_mediaImageview addSubview:loading];
    [loading startAnimating];
    
    if (_media.remoteURL) {
        [[WPImageSource sharedSource] downloadImageForURL:[NSURL URLWithString:_media.remoteURL] withSuccess:^(UIImage *image) {
            _mediaImageview.contentMode = UIViewContentModeScaleAspectFit;
            _mediaImageview.image = image;
            NSString *localPath = [self saveFullsizeImageToDisk:image imageName:_media.filename];
            _media.localURL = localPath;
            _mediaImageview.userInteractionEnabled = true;
            [[_mediaImageview viewWithTag:1337] removeFromSuperview];
        } failure:^(NSError *error) {
            WPFLog(@"Failed to download image for %@: %@", _media, error);
            [[_mediaImageview viewWithTag:1337] removeFromSuperview];
        }];
    }
}

- (void)applyLayout
{
    self.descriptionTextview.editable = YES;
    
    // Add toolbar for editing
    CGRect frame = CGRectMake(0, 0, self.view.frame.size.width, WPKT_HEIGHT_PORTRAIT);
    WPKeyboardToolbarBase *editorToolbar;
    if (IS_IOS7) {
        editorToolbar = [[WPKeyboardToolbarWithoutGradient alloc] initDoneWithFrame:frame];
    } else {
        editorToolbar = [[WPKeyboardToolbar alloc] initDoneWithFrame:frame];
        _editContainerView.frame = (CGRect) {
            .origin = CGPointMake(_editContainerView.frame.origin.x, _editContainerView.frame.origin.y - 90.0f),
            .size = _editContainerView.frame.size
        };
    }
    editorToolbar.delegate = self;
    self.titleTextfield.inputAccessoryView = editorToolbar;
    self.captionTextfield.inputAccessoryView = editorToolbar;
    self.descriptionTextview.inputAccessoryView = editorToolbar;
}

#pragma mark - Keyboard Management

- (void)keyboardWillShow:(NSNotification*)sender {
    BOOL isLandscape = UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation);
    NSValue *keyboardFrame = [sender userInfo][UIKeyboardFrameBeginUserInfoKey];
    CGFloat animationDuration = [[sender userInfo][UIKeyboardAnimationDurationUserInfoKey] floatValue];
    UIViewAnimationCurve curve = [[sender userInfo][UIKeyboardAnimationCurveUserInfoKey] integerValue];
    CGFloat keyboardHeight = isLandscape ? [keyboardFrame CGRectValue].size.width : [keyboardFrame CGRectValue].size.height;
    _currentKeyboardHeight = keyboardHeight;
    
    if (UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation) && !IS_IPAD) {
        [self.navigationController setNavigationBarHidden:YES animated:YES];
    }
    
    CGFloat visibleHeight = self.view.bounds.size.height - keyboardHeight;
    if (isLandscape && !IS_IPAD) {
        visibleHeight += _editingBar.frame.size.height;
    }
    CGFloat yOffset = (IS_IPAD && !isLandscape) ? (_editContainerView.frame.origin.y - keyboardHeight) : 0;
    CGFloat scrollViewHeight = (IS_IPAD && !isLandscape) ? _editFieldsScrollView.frame.size.height : visibleHeight;
    
    [UIView animateWithDuration:animationDuration delay:0 options:UIViewAnimationOptionBeginFromCurrentState|curve animations:^{
        _editContainerView.frame = (CGRect) {
            .origin = CGPointMake(_editContainerView.frame.origin.x, yOffset),
            .size = _editContainerView.frame.size
        };
        _editFieldsScrollView.frame = (CGRect) {
            .origin = _editFieldsScrollView.frame.origin,
            .size = CGSizeMake(_editFieldsScrollView.frame.size.width, scrollViewHeight)
        };
    } completion:nil];
}

- (void)keyboardWillHide:(NSNotification*)sender {
    BOOL isLandscape = UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation);
    _currentKeyboardHeight = 0;
    CGFloat animationDuration = [[sender userInfo]
                                 [UIKeyboardAnimationDurationUserInfoKey] floatValue];
    UIViewAnimationCurve curve = [[sender userInfo][UIKeyboardAnimationCurveUserInfoKey] integerValue];
    [UIView animateWithDuration:animationDuration delay:0 options:UIViewAnimationOptionBeginFromCurrentState|curve animations:^{
        _editFieldsScrollView.frame = (CGRect) {
            .origin = _editFieldsScrollView.frame.origin,
            .size = CGSizeMake(_editFieldsScrollView.frame.size.width, _editContainerView.frame.size.height - ((IS_IPAD && isLandscape) ? _editingBar.frame.size.width : _editingBar.frame.size.height))
        };
        _editContainerView.frame = (CGRect) {
            .origin = CGPointMake(_editContainerView.frame.origin.x, self.view.bounds.size.height - (_editFieldsScrollView.frame.size.height + ((IS_IPAD && isLandscape) ? _editingBar.frame.size.width : _editingBar.frame.size.height))),
            .size = _editContainerView.frame.size
        };
        
        if (self.navigationController.navigationBarHidden) {
            [self.navigationController setNavigationBarHidden:NO animated:YES];
        }

    } completion:nil];
}

- (void)keyboardToolbarButtonItemPressed:(WPKeyboardToolbarButtonItem *)buttonItem {
    if ([buttonItem.actionTag isEqualToString:@"done"]) {
        [[self currentFirstResponder] resignFirstResponder];
    }
}

- (UIView *)currentFirstResponder {
    for (UIView *v in _editFieldsContainer.subviews) {
        if (v.isFirstResponder) {
            return v;
        }
    }
    return nil;
}

- (void)savePressed {
    
    [self.view addSubview:self.loadingView];
    [self.loadingView show];
    
    dispatch_block_t success = ^{
        [self.navigationController popViewControllerAnimated:YES];
        [self.loadingView hide];
        [self.loadingView removeFromSuperview];
    };
    
    __block void (^failure)(NSError*) = ^(NSError *error) {
        if (error.code == 404) {
            // Server-side deleted
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failed to Save" message:NSLocalizedString(@"This image/video has been deleted on the blog, do you want to re-upload it or discard it?", @"") delegate:self cancelButtonTitle:nil otherButtonTitles:@"Discard", @"Upload", nil];
            [alert show];
        } else {
            [WPError showAlertWithError:error];
        }
        [self.loadingView hide];
        [self.loadingView removeFromSuperview];
    };
    
    // Media upload may have failed at some point, so we need to upload here
    if (!_media.mediaID) {
        [_media.managedObjectContext save:nil];
        [self.media uploadWithSuccess:success failure:failure];
        return;
    }
    
    // Block the user from escaping before it's done
    [self.media remoteUpdateWithSuccess:success failure:failure];
}

- (UIView *)loadingView {
    if (!_loadingView) {
        CGFloat side = 100.0f;
        WPLoadingView *loadingView = [[WPLoadingView alloc] initWithSide:side];
        loadingView.center = CGPointMake(self.view.center.x, self.view.center.y - side);
        _loadingView = loadingView;
    }
    return _loadingView;
}

- (void)cancelButtonPressed {
    __block BOOL hasDataChanges = false;
    if ([_media.managedObjectContext hasChanges]) {
        [[_media changedValues] enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
            if ([key isEqualToString:@"title"] || [key isEqualToString:@"caption"] || [key isEqualToString:@"desc"]) {
                hasDataChanges = true;
            }
        }];
    }

    if (hasDataChanges) {
        UIAlertView *discardAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Discard Changes", @"") message:NSLocalizedString(@"Are you sure you would like to discard your changes?", @"") delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Discard", nil];
        discardAlert.tag = AlertDiscardChanges;
        [discardAlert show];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == AlertDiscardChanges) {
        if (buttonIndex == 1) {
            [_media.managedObjectContext rollback];
            [self.navigationController popViewControllerAnimated:YES];
        }
    } else {
        NSManagedObjectContext *context = _media.managedObjectContext;
        if (buttonIndex == 0) {
            [context deleteObject:_media];
            [self.navigationController popViewControllerAnimated:YES];
        
        } else if (buttonIndex == 1) {
            if (_media.localURL) {
                [self.view addSubview:self.loadingView];
                [self.loadingView show];
                [self.media uploadWithSuccess:^{
                    [self.navigationController popViewControllerAnimated:YES];
                    [self.loadingView hide];
                    [self.loadingView removeFromSuperview];
                }failure:^(NSError *error) {
                    [WPError showAlertWithError:error];
                    [self.loadingView hide];
                    [self.loadingView removeFromSuperview];
                }];
            } else {
                // No localUrl implies that the image could not be downloaded
                // Upload will fail
                // TODO Tell user about this?
                [self.navigationController popViewControllerAnimated:YES];
            }
        }
        [context save:nil];
    }
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if (!IS_IPAD)
        _editFieldsScrollView.contentOffset = CGPointMake(0, CGRectGetMinY(textField.frame));
}

-(void)textFieldDidEndEditing:(UITextField *)textField {
    if (textField == _titleTextfield) {
        _media.title = textField.text;
    } else if (textField == _captionTextfield) {
        _media.caption = textField.text;
    }
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    [textView textViewDidBeginEditing:textView];
    if (!IS_IPAD)
        _editFieldsScrollView.contentOffset = CGPointMake(0, CGRectGetMinY(textView.frame));
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    [textView textViewDidEndEditing:textView];
    if (textView == _descriptionTextview) {
        _media.desc = textView.enteredText;
    }
}

#pragma mark UIScrollView delegate

-(UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return _mediaImageview;
}

- (void)scrollViewDidZoom:(UIScrollView *)pScrollView {
	CGRect innerFrame = _mediaImageview.frame;
	CGRect scrollerBounds = pScrollView.bounds;
	
	if ((innerFrame.size.width < scrollerBounds.size.width) || (innerFrame.size.height < scrollerBounds.size.height))
	{
		CGFloat tempx = _mediaImageview.center.x - ( scrollerBounds.size.width / 2 );
		CGFloat tempy = _mediaImageview.center.y - ( scrollerBounds.size.height / 2 );
		CGPoint myScrollViewOffset = CGPointMake( tempx, tempy);
		
		pScrollView.contentOffset = myScrollViewOffset;
	}
	
	UIEdgeInsets anEdgeInset = { 0, 0, 0, 0};
	if(scrollerBounds.size.width > innerFrame.size.width)
	{
		anEdgeInset.left = (scrollerBounds.size.width - innerFrame.size.width) / 2;
		anEdgeInset.right = -anEdgeInset.left;
	}
	if(scrollerBounds.size.height > innerFrame.size.height)
	{
		anEdgeInset.top = (scrollerBounds.size.height - innerFrame.size.height) / 2;
		anEdgeInset.bottom = -anEdgeInset.top;
	}
	pScrollView.contentInset = anEdgeInset;
}

@end

@implementation UITextView (Placeholder)

- (void)textViewDidBeginEditing:(UITextView *)textView {
    if ([self.text isEqualToString:self.placeholder]) {
        self.text = nil;
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    if (!self.text || [self.text isEqualToString:@""]) {
        self.text = self.placeholder;
        self.alpha = 0.5f;
    } else {
        self.alpha = 1.0f;
    }
}

- (void)setPlaceholder:(NSString *)placeholder {
    objc_setAssociatedObject(self, "placeholder", placeholder, OBJC_ASSOCIATION_RETAIN);
    if (!self.text || [self.text isEqualToString:@""]) {
        self.text = placeholder;
        self.alpha = 0.5f;
    }
}

- (NSString *)enteredText {
    return [self.text isEqualToString:self.placeholder] ? @"" : self.text;
}

- (NSString *)placeholder {
    return objc_getAssociatedObject(self, "placeholder");
}

@end

@implementation BlurView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.clipsToBounds = YES;
        
        if (IS_IOS7) {
            if (!_toolbar) {
                _toolbar = [[UIToolbar alloc] initWithFrame:[self bounds]];
                _toolbar.barTintColor = [UIColor blackColor];
                [self.layer insertSublayer:_toolbar.layer atIndex:0];
            }
        } else {
            self.backgroundColor = [UIColor blackColor];
            self.alpha = 0.8;
        }

    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _toolbar.frame = self.bounds;
}

@end