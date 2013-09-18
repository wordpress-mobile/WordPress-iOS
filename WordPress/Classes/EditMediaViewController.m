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

static NSUInteger const AlertDiscardChanges = 500;

@interface UITextView (Placeholder) <UITextViewDelegate>

@property (nonatomic, weak) NSString *placeholder;

- (NSString*)enteredText;

@end

@interface EditMediaViewController () <WPKeyboardToolbarDelegate, UIGestureRecognizerDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) Media *media;
@property (nonatomic, assign) BOOL isEditing;
@property (nonatomic, strong) WPLoadingView *loadingView;
@property (strong, nonatomic) UITapGestureRecognizer *tapImageRecognizer;

@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UIImageView *mediaImageview;
@property (weak, nonatomic) IBOutlet UITextView *titleTextview;
@property (weak, nonatomic) IBOutlet UITextView *captionTextview;
@property (weak, nonatomic) IBOutlet UITextView *descriptionTextview;
@property (weak, nonatomic) IBOutlet UILabel *createdDateLabel;


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

- (id)initWithMedia:(Media*)media showEditMode:(BOOL)isEditing {
    self = [super init];
    if (self) {
        _media = media;
        _isEditing = isEditing;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tapImageRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageTapped:)];
    _tapImageRecognizer.delegate = self;
    [_mediaImageview addGestureRecognizer:_tapImageRecognizer];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Edit", @"") style:UIBarButtonItemStyleBordered target:self action:@selector(editPressed)];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", @"") style:UIBarButtonItemStylePlain target:self action:@selector(cancelButtonPressed)];
    
    [self.view addSubview:_contentView];
    ((UIScrollView*)self.view).contentSize = CGSizeMake(self.view.frame.size.width, _contentView.frame.size.height);
    
    self.titleTextview.font = [WPStyleGuide regularTextFont];
    self.captionTextview.font = self.titleTextview.font;
    self.descriptionTextview.font = self.titleTextview.font;
    self.createdDateLabel.font = self.titleTextview.font;
    
    self.titleTextview.textColor = [WPStyleGuide allTAllShadeGrey];
    self.captionTextview.textColor = self.titleTextview.textColor;
    self.descriptionTextview.textColor = self.titleTextview.textColor;
    self.createdDateLabel.textColor = [WPStyleGuide whisperGrey];
    
    _containerView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleBottomMargin;
    
    [self applyLayoutForMedia];
    if (_isEditing) {
        [self applyLayoutForEditingState];
    }
    
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
    
}

- (void)applyLayoutForMedia
{
    [self.titleTextview setText:_media.title];
    [self.titleTextview setPlaceholder:NSLocalizedString(@"Title", @"")];
    
    [self.captionTextview setText:_media.caption];
    [self.captionTextview setPlaceholder:NSLocalizedString(@"Caption", @"")];
    
    [self.descriptionTextview setText:_media.desc];
    [self.descriptionTextview setPlaceholder:NSLocalizedString(@"Description", @"")];
    
    NSLog(@"Creation Date: %@", _media.creationDate);
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    NSString *stringFromDate = [dateFormatter stringFromDate:_media.creationDate];
    [self.createdDateLabel setText: [NSString stringWithFormat:@"Created Date: %@", stringFromDate]];
    
    [self loadMediaImage];
}

- (NSString *)saveFullsizeImageToDisk:(UIImage*)image imageName:(NSString *)imageName {
    NSString *docsDirectory = (NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true))[0];
    NSString *mediaDirectoryPath = [docsDirectory stringByAppendingPathComponent:@"Media"];
    BOOL directory;
    if (![[NSFileManager defaultManager] fileExistsAtPath:mediaDirectoryPath isDirectory:&directory] && !directory) {
        NSError *error;
        [[NSFileManager defaultManager] createDirectoryAtPath:mediaDirectoryPath withIntermediateDirectories:false attributes:nil error:&error];
        if (error) {
            WPFLog(@"Unable to create directory for fullsize media images %@",error);
        }
    }
    NSData *imageData = UIImageJPEGRepresentation(image, 1);
    NSString *path = [mediaDirectoryPath stringByAppendingPathComponent:imageName];
    BOOL success = [[NSFileManager defaultManager] createFileAtPath:path contents:imageData attributes:nil];
    if (success) {
        return path;
    }
    return nil;
}

- (void)loadMediaImage {
    if (_media.localURL) {
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
            _mediaImageview.image = image;
            NSString *localPath = [self saveFullsizeImageToDisk:image imageName:_media.mediaID.stringValue];
            _media.localURL = localPath;
            [[_mediaImageview viewWithTag:1337] removeFromSuperview];
        } failure:^(NSError *error) {
            WPFLog(@"Failed to download image for %@: %@", _media, error);
            [[_mediaImageview viewWithTag:1337] removeFromSuperview];
            if ([_media.mediaType isEqualToString:@"movie"]) {
                [_mediaImageview setImage:[UIImage imageNamed:@"media_movieclip"]];
            } else {
                [_mediaImageview setImage:[UIImage imageNamed:@"media_image_placeholder"]];
            }
        }];
    } else {
        [[_mediaImageview viewWithTag:1337] removeFromSuperview];
        if ([_media.mediaType isEqualToString:@"movie"]) {
            [_mediaImageview setImage:[UIImage imageNamed:@"media_movieclip"]];
        } else {
            [_mediaImageview setImage:[UIImage imageNamed:@"media_image_placeholder"]];
        }
    }
}

- (void)applyLayoutForEditingState
{
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Save", @"") style:UIBarButtonItemStyleBordered target:self action:@selector(savePressed)];
    
    self.titleTextview.editable = YES;
    self.captionTextview.editable = YES;
    self.descriptionTextview.editable = YES;
    
    // Add toolbar for editing
    CGRect frame = CGRectMake(0, 0, self.view.frame.size.width, WPKT_HEIGHT_PORTRAIT);
    WPKeyboardToolbarBase *editorToolbar;
    if (IS_IOS7) {
        editorToolbar = [[WPKeyboardToolbarWithoutGradient alloc] initDoneWithFrame:frame];
    } else {
        editorToolbar = [[WPKeyboardToolbar alloc] initDoneWithFrame:frame];
    }
    editorToolbar.delegate = self;
    self.titleTextview.inputAccessoryView = editorToolbar;
    self.captionTextview.inputAccessoryView = editorToolbar;
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

- (void)editPressed {
    [self applyLayoutForEditingState];
}

- (void)savePressed {
    self.media.title = [self.titleTextview enteredText];
    self.media.caption = [self.captionTextview enteredText];
    self.media.desc = [self.descriptionTextview enteredText];
    
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
    UIAlertView *discardAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Discard Changes", @"") message:NSLocalizedString(@"Are you sure you would like to discard your changes?", @"") delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Discard", nil];
    discardAlert.tag = AlertDiscardChanges;
    [discardAlert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == AlertDiscardChanges) {
        if (buttonIndex == 1) {
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
    }
}

- (void)setPlaceholder:(NSString *)placeholder {
    self.delegate = self;
    objc_setAssociatedObject(self, "placeholder", placeholder, OBJC_ASSOCIATION_RETAIN);
    if (!self.text || [self.text isEqualToString:@""]) {
        self.text = placeholder;
    }
}

- (NSString *)enteredText {
    return [self.text isEqualToString:self.placeholder] ? @"" : self.text;
}

- (NSString *)placeholder {
    return objc_getAssociatedObject(self, "placeholder");
}

@end