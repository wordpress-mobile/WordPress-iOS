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
#import <objc/runtime.h>

@interface UITextView (Placeholder) <UITextViewDelegate>

@property (nonatomic, weak) NSString *placeholder;

- (NSString*)enteredText;

@end

@interface EditMediaViewController () <WPKeyboardToolbarDelegate>

@property (nonatomic, strong) Media *media;
@property (nonatomic, assign) BOOL isEditing;
@property (nonatomic, weak) UIView *loadingView;

@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UIImageView *mediaImageview;
@property (weak, nonatomic) IBOutlet UITextView *titleTextview;
@property (weak, nonatomic) IBOutlet UITextView *captionTextview;
@property (weak, nonatomic) IBOutlet UITextView *descriptionTextview;

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
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Edit", @"") style:UIBarButtonItemStyleBordered target:self action:@selector(editPressed)];
    
    [self.view addSubview:_contentView];
    ((UIScrollView*)self.view).contentSize = CGSizeMake(self.view.frame.size.width, _contentView.frame.size.height);
    
    self.titleTextview.font = [WPStyleGuide regularTextFont];
    self.captionTextview.font = self.titleTextview.font;
    self.descriptionTextview.font = self.titleTextview.font;
    
    self.titleTextview.textColor = [WPStyleGuide allTAllShadeGrey];
    self.captionTextview.textColor = self.titleTextview.textColor;
    self.descriptionTextview.textColor = self.titleTextview.textColor;
    
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

- (void)applyLayoutForMedia
{
    [self.titleTextview setText:_media.title];
    [self.titleTextview setPlaceholder:NSLocalizedString(@"Title", @"")];
    
    [self.captionTextview setText:_media.caption];
    [self.captionTextview setPlaceholder:NSLocalizedString(@"Caption", @"")];
    
    [self.descriptionTextview setText:_media.desc];
    [self.descriptionTextview setPlaceholder:NSLocalizedString(@"Description", @"")];
    
    // TODO Show a friendly 'no image' placeholder while loading (perhaps with an indicator) and for failure
    [[WPImageSource sharedSource] downloadImageForURL:[NSURL URLWithString:_media.remoteURL] withSuccess:^(UIImage *image) {
        _mediaImageview.image = image;
    } failure:^(NSError *error) {
        WPFLog(@"Failed to download image for %@: %@", _media, error);
    }];
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
    
    // Block the user from escaping before it's done
    [self.media remoteUpdateWithSuccess:^{
        [self.navigationController popViewControllerAnimated:YES];
        [self.loadingView removeFromSuperview];
    } failure:^(NSError *error) {
        [WPError showAlertWithError:error];
        [self.loadingView removeFromSuperview];
    }];
}

- (UIView *)loadingView {
    CGFloat side = 100.0f;
    UIView *loadingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, side, side)];
    loadingView.layer.cornerRadius = 10.0f;
    loadingView.center = CGPointMake(self.view.center.x, self.view.center.y - side);
    loadingView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.8f];
    loadingView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin |
    UIViewAutoresizingFlexibleBottomMargin |
    UIViewAutoresizingFlexibleTopMargin |
    UIViewAutoresizingFlexibleRightMargin;
    
    UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    activityView.hidesWhenStopped = NO;
    activityView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin |
    UIViewAutoresizingFlexibleBottomMargin |
    UIViewAutoresizingFlexibleTopMargin |
    UIViewAutoresizingFlexibleRightMargin;
    [activityView startAnimating];
    
    CGRect frm = activityView.frame;
    frm.origin.x = (side / 2.0f) - (frm.size.width / 2.0f);
    frm.origin.y = (side / 2.0f) - (frm.size.height / 2.0f);
    activityView.frame = frm;
    [loadingView addSubview:activityView];
    _loadingView = loadingView;
    return _loadingView;
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