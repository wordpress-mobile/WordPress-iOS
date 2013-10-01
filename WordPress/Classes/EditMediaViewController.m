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
@property (nonatomic, strong) UITapGestureRecognizer *tapImageRecognizer;

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
    
    self.tapImageRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageTapped:)];
    _tapImageRecognizer.delegate = self;
    [_mediaImageview addGestureRecognizer:_tapImageRecognizer];
    
    UIImageView *arrow = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon_white_arrow_up"]];
    arrow.center = self.editingBar.center;
    arrow.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [self.editingBar addSubview:arrow];
    [_editingBar addTarget:self action:@selector(barTapped:) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Save", @"") style:UIBarButtonItemStyleBordered target:self action:@selector(savePressed)];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", @"") style:UIBarButtonItemStylePlain target:self action:@selector(cancelButtonPressed)];
    
    self.titleTextfield.font = [WPStyleGuide regularTextFont];
    self.captionTextfield.font = self.titleTextfield.font;
    self.descriptionTextview.font = self.titleTextfield.font;
    self.createdDateLabel.font = self.titleTextfield.font;
    self.dimensionsLabel.font = self.titleTextfield.font;
    
    self.titleTextfield.delegate = self;
    self.captionTextfield.delegate = self;
    self.descriptionTextview.delegate = self;
    
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
    blur.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [_editContainerView insertSubview:blur atIndex:0];
}

- (void)viewDidLayoutSubviews {
    [self layoutEditOverlay];
}

- (void)layoutEditOverlay {
    BOOL isLandscape = UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation);
    CGFloat closedYOffset = self.view.bounds.size.height - _editingBar.frame.size.height;
    CGFloat openedYOffset = isLandscape ? 0 : self.view.bounds.size.height - _editContainerView.frame.size.height;
    CGFloat currentYOffset = _isShowingEditFields ? openedYOffset : closedYOffset;
    CGFloat scrollViewHeight = isLandscape ? self.view.bounds.size.height - _editingBar.frame.size.height : _editContainerView.frame.size.height - _editingBar.frame.size.height;
    
    _editContainerView.frame = (CGRect) {
        .origin = CGPointMake(0, currentYOffset),
        .size = _editContainerView.frame.size
    };
    _editFieldsScrollView.frame = (CGRect) {
        .origin = _editFieldsScrollView.frame.origin,
        .size = CGSizeMake(_editContainerView.frame.size.width, scrollViewHeight)
    };
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

- (void)imageTapped:(id)sender {
    if (_isShowingEditFields) {
        [self toggleEditBar];
    }
}

- (void)barTapped:(id)sender {
    [self toggleEditBar];
}


- (void)toggleEditBar {
    _isShowingEditFields = !_isShowingEditFields;
    
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
    
    if ([_media.mediaType isEqualToString:@"image"]) {
        [self loadMediaImage];
    }
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
        return;
    }
    
    UIActivityIndicatorView *loading = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    loading.center = CGPointMake(_mediaImageview.bounds.size.width/2, _mediaImageview.bounds.size.height/2);
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
    NSValue *keyboardFrame = [sender userInfo][UIKeyboardFrameEndUserInfoKey];
    CGFloat animationDuration = [[sender userInfo][UIKeyboardAnimationDurationUserInfoKey] floatValue];
    UIViewAnimationCurve curve = [[sender userInfo][UIKeyboardAnimationCurveUserInfoKey] integerValue];
    
    CGFloat height = CGRectGetMaxY(_editFieldsScrollView.frame) - CGRectGetMinY([keyboardFrame CGRectValue]);
    
    if (UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation])) {
        [self.navigationController setNavigationBarHidden:YES animated:YES];
    }
    
    [UIView animateWithDuration:animationDuration delay:0 options:UIViewAnimationOptionBeginFromCurrentState|curve animations:^{
        _editContainerView.frame = (CGRect) {
            .origin = CGPointMake(_editContainerView.frame.origin.x, 0),
            .size = _editContainerView.frame.size
        };
        _editFieldsScrollView.frame = (CGRect) {
            .origin = _editFieldsScrollView.frame.origin,
            .size = CGSizeMake(_editFieldsScrollView.frame.size.width, height)
        };
    } completion:nil];
}

- (void)keyboardWillHide:(NSNotification*)sender {
    CGFloat animationDuration = [[sender userInfo]
                                 [UIKeyboardAnimationDurationUserInfoKey] floatValue];
    UIViewAnimationCurve curve = [[sender userInfo][UIKeyboardAnimationCurveUserInfoKey] integerValue];
    [UIView animateWithDuration:animationDuration delay:0 options:UIViewAnimationOptionBeginFromCurrentState|curve animations:^{
        _editFieldsScrollView.frame = (CGRect) {
            .origin = _editFieldsScrollView.frame.origin,
            .size = CGSizeMake(_editFieldsScrollView.frame.size.width, _editContainerView.frame.size.height - _editingBar.frame.size.height)
        };
        _editContainerView.frame = (CGRect) {
            .origin = CGPointMake(_editContainerView.frame.origin.x, self.view.bounds.size.height - (_editFieldsScrollView.frame.size.height + _editingBar.frame.size.height)),
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
    _editFieldsScrollView.contentOffset = CGPointMake(0, CGRectGetMinY(textView.frame));
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    [textView textViewDidEndEditing:textView];
    if (textView == _descriptionTextview) {
        _media.desc = textView.enteredText;
    }
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