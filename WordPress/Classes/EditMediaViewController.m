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

@interface EditMediaViewController () <WPKeyboardToolbarDelegate>

@property (nonatomic, strong) Media *media;
@property (nonatomic, assign) BOOL isEditing;

@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UITextView *titleTextview;
@property (weak, nonatomic) IBOutlet UIImageView *mediaImageview;
@property (weak, nonatomic) IBOutlet UITextView *captionTextview;
@property (weak, nonatomic) IBOutlet UITextView *descriptionTextview;
@property (weak, nonatomic) IBOutlet UILabel *captionTitle;
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
    
    [self.view addSubview:_contentView];
    ((UIScrollView*)self.view).contentSize = CGSizeMake(self.view.frame.size.width, _contentView.frame.size.height);
    
    self.titleTextview.font = [WPStyleGuide regularTextFont];
    self.captionTextview.font = self.titleTextview.font;
    self.descriptionTextview.font = self.titleTextview.font;
    self.captionTitle.font = self.titleTextview.font;
    self.descriptionLabel.font = self.titleTextview.font;
    
    self.titleTextview.textColor = [WPStyleGuide allTAllShadeGrey];
    self.captionTextview.textColor = self.titleTextview.textColor;
    self.descriptionTextview.textColor = self.descriptionTextview.textColor;
    self.captionTitle.textColor = [WPStyleGuide littleEddieGrey];
    self.descriptionLabel.textColor = self.captionTitle.textColor;
    
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
    [self.captionTextview setText:_media.caption];
    [self.descriptionTextview setText:_media.desc];
    
    // TODO Show a friendly 'no image' placeholder while loading (perhaps with an indicator) and for failure
    [[WPImageSource sharedSource] downloadImageForURL:[NSURL URLWithString:_media.remoteURL] withSuccess:^(UIImage *image) {
        _mediaImageview.image = image;
    } failure:^(NSError *error) {
        WPFLog(@"Failed to download image for %@: %@", _media, error);
    }];
}

- (void)applyLayoutForEditingState
{
    //Turn Save Button into Edit Button
    
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
    
    [UIView animateWithDuration:animationDuration delay:0 options:UIViewAnimationOptionBeginFromCurrentState|curve animations:^{
        ((UIScrollView*)self.view).contentInset = UIEdgeInsetsMake(0, 0, height, 0);
        ((UIScrollView*)self.view).contentOffset = CGPointMake(0, MAX(0, CGRectGetMinY(firstResponder.frame) - 50));
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
    for (UIView *v in self.contentView.subviews) {
        if (v.isFirstResponder) {
            return v;
        }
    }
    return nil;
}

@end
