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

@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UIImageView *mediaImageview;
@property (weak, nonatomic) IBOutlet UITextField *titleTextfield;
@property (weak, nonatomic) IBOutlet UITextField *captionTextfield;
@property (weak, nonatomic) IBOutlet UITextView *descriptionTextview;
@property (weak, nonatomic) IBOutlet UILabel *createdDateLabel;
@property (weak, nonatomic) IBOutlet UILabel *dimensionsLabel;
@property (weak, nonatomic) IBOutlet UIButton *editingBar;
@property (weak, nonatomic) IBOutlet UIImageView *blurringImageView;

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
    
    self.tapImageRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageTapped:)];
    _tapImageRecognizer.delegate = self;
    [_mediaImageview addGestureRecognizer:_tapImageRecognizer];
    
    UIImageView *arrow = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon_white_arrow_up"]];
    arrow.center = self.editingBar.center;
    [self.editingBar addSubview:arrow];
    [_editingBar addTarget:self action:@selector(barTapped:) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Save", @"") style:UIBarButtonItemStyleBordered target:self action:@selector(savePressed)];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", @"") style:UIBarButtonItemStylePlain target:self action:@selector(cancelButtonPressed)];
    
    [self.view addSubview:_contentView];
    
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
    
    _containerView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleBottomMargin;
    
    [self applyLayoutForMedia];
    [self applyLayout];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
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
- (UIImage*)imageToBlur {
    CGRect rect = _mediaImageview.frame;
    
    UIGraphicsBeginImageContextWithOptions(rect.size, YES, 0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [_mediaImageview.layer renderInContext:context];
    UIImage *capturedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    CGFloat scale = [[UIScreen mainScreen] scale];
    
    rect = CGRectMake(0, CGRectGetMinY(_containerView.frame)*scale, _containerView.frame.size.width*scale, _containerView.frame.size.height*scale);
    
    return [capturedImage croppedImage:rect];
}


- (void)toggleEditBar {
    if (_isShowingEditFields) {
        [UIView animateWithDuration:0.3f animations:^{
            _containerView.frame = (CGRect) {
                .origin = CGPointMake(0, CGRectGetMaxY(_contentView.frame) -CGRectGetHeight(_editingBar.frame)) ,
                .size = CGSizeMake(CGRectGetWidth(_containerView.frame), CGRectGetHeight(_containerView.frame))
            };
        } completion:^(BOOL finished) {
            _isShowingEditFields = NO;
            _blurringImageView.image = [[self imageToBlur] applyDarkEffect];
        }];
    } else {
        [UIView animateWithDuration:0.3f animations:^{
            _containerView.frame = (CGRect) {
                .origin = CGPointMake(0, CGRectGetMaxY(_contentView.frame) - CGRectGetHeight(_containerView.frame)),
                .size = CGSizeMake(CGRectGetWidth(_containerView.frame), CGRectGetHeight(_containerView.frame))
            };
        } completion:^(BOOL finished) {
            _blurringImageView.image = [[self imageToBlur] applyDarkEffect];
            _isShowingEditFields = YES;
        }];
    }
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
        _blurringImageView.image = [[self imageToBlur] applyDarkEffect];
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
            _blurringImageView.image = [[self imageToBlur] applyDarkEffect];
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
        _containerView.frame = (CGRect) {
            .origin = CGPointMake(_containerView.frame.origin.x, _containerView.frame.origin.y - 90.0f),
            .size = _containerView.frame.size
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
    CGFloat height = [keyboardFrame CGRectValue].size.height;
    CGFloat animationDuration = [[sender userInfo][UIKeyboardAnimationDurationUserInfoKey] floatValue];
    UIViewAnimationCurve curve = [[sender userInfo][UIKeyboardAnimationCurveUserInfoKey] integerValue];
    UIView *firstResponder = [self currentFirstResponder];
    
    CGFloat y = _containerView.frame.origin.y + firstResponder.frame.origin.y;
    
    [UIView animateWithDuration:animationDuration delay:0 options:UIViewAnimationOptionBeginFromCurrentState|curve animations:^{
        ((UIScrollView*)self.view).contentInset = UIEdgeInsetsMake(0, 0, height, 0);
        ((UIScrollView*)self.view).contentOffset = CGPointMake(0, MAX(0, y - 50));
    } completion:nil];
}

- (void)keyboardWillHide:(NSNotification*)sender {
    CGFloat animationDuration = [[sender userInfo][UIKeyboardAnimationDurationUserInfoKey] floatValue];
    UIViewAnimationCurve curve = [[sender userInfo][UIKeyboardAnimationCurveUserInfoKey] integerValue];
    [UIView animateWithDuration:animationDuration delay:0 options:UIViewAnimationOptionBeginFromCurrentState|curve animations:^{
        ((UIScrollView*)self.view).contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    } completion:nil];
}

- (void)keyboardToolbarButtonItemPressed:(WPKeyboardToolbarButtonItem *)buttonItem {
    if ([buttonItem.actionTag isEqualToString:@"done"]) {
        [[self currentFirstResponder] resignFirstResponder];
    }
}

- (UIView *)currentFirstResponder {
    for (UIView *v in self.containerView.subviews) {
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

-(void)textFieldDidEndEditing:(UITextField *)textField {
    if (textField == _titleTextfield) {
        _media.title = textField.text;
    } else if (textField == _captionTextfield) {
        _media.caption = textField.text;
    }
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    [textView textViewDidBeginEditing:textView];
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