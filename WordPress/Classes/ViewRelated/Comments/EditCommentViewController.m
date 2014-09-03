#import "EditCommentViewController.h"
#import "CommentViewController.h"
#import "CommentService.h"
#import "ContextManager.h"
#import "IOS7CorrectedTextView.h"



@interface EditCommentViewController() <UIActionSheetDelegate>

@property (nonatomic,   weak) IBOutlet IOS7CorrectedTextView    *textView;
@property (nonatomic, strong) NSString                          *pristineText;
@property (nonatomic, assign) CGRect                            keyboardFrame;

- (void)handleKeyboardDidShow:(NSNotification *)notification;
- (void)handleKeyboardWillHide:(NSNotification *)notification;

@end


@implementation EditCommentViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Edit Comment", @"");
    
    self.textView.font = [WPStyleGuide regularTextFont];
    
    [self showCancelBarButton];
    [self showSaveBarButton];
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(handleKeyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    [nc addObserver:self selector:@selector(handleKeyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.textView.text  = self.content;
    self.pristineText   = self.content;
    
    [self.textView becomeFirstResponder];
    [self enableSaveIfNeeded];
}


#pragma mark - View Helpers

- (void)showCancelBarButton
{
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil)
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:self
                                                                            action:@selector(btnCancelPressed)];
}

- (void)showDoneBarButton
{
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", @"")
                                                                             style:[WPStyleGuide barButtonStyleForDone]
                                                                            target:self
                                                                            action:@selector(btnDonePressed)];
}

- (void)showSaveBarButton
{
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Save", @"Save button label (saving content, ex: Post, Page, Comment).")
                                                                              style:[WPStyleGuide barButtonStyleForDone]
                                                                             target:self
                                                                             action:@selector(btnSavePressed)];
}

- (void)setInterfaceEnabled:(BOOL)enabled
{
    self.textView.editable                          = enabled;
    self.navigationItem.rightBarButtonItem.enabled  = enabled;
    self.navigationItem.leftBarButtonItem.enabled   = enabled;
    _interfaceEnabled                               = enabled;
}

- (BOOL)hasChanges
{
    return ![self.textView.text isEqualToString:self.pristineText];
}

- (void)enableSaveIfNeeded
{
    self.navigationItem.rightBarButtonItem.enabled = self.hasChanges;
}


#pragma mark - KeyboardNotification Methods

- (void)handleKeyboardDidShow:(NSNotification *)notification
{
    NSTimeInterval animationDuration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];
    
    _keyboardFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    _keyboardFrame = [self.view convertRect:_keyboardFrame fromView:self.view.window];
    
    [UIView animateWithDuration:animationDuration animations:^{
        CGRect frm = self.textView.frame;
        frm.size.height = CGRectGetMinY(_keyboardFrame);
        self.textView.frame = frm;
    }];
}

- (void)handleKeyboardWillHide:(NSNotification *)notification
{
    NSTimeInterval animationDuration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];
    
    [UIView animateWithDuration:animationDuration animations:^{
        CGRect frm = self.textView.frame;
        frm.size.height = CGRectGetMaxY(self.view.bounds);
        self.textView.frame = frm;
    }];
}


#pragma mark - Text View Delegate Methods

- (void)textViewDidBeginEditing:(UITextView *)aTextView
{
    if (IS_IPAD == NO) {
        [self showDoneBarButton];
    }
}

- (void)textViewDidChange:(UITextView *)textView
{
    [self enableSaveIfNeeded];
}

- (void)textViewDidEndEditing:(UITextView *)aTextView
{
    if (IS_IPAD == NO) {
        [self showCancelBarButton];
    }
}


#pragma mark - UIActionSheet delegate methods

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == actionSheet.destructiveButtonIndex) {
        [self finishWithoutUpdates];
    }
}


#pragma mark - Button Delegates

- (void)btnCancelPressed
{
    if (self.hasChanges == NO) {
        [self finishWithoutUpdates];
        return;
    }

    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"You have unsaved changes.", @"")
                                                             delegate:self
                                                    cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
                                               destructiveButtonTitle:NSLocalizedString(@"Discard", @"")
                                                    otherButtonTitles:nil];
    
    actionSheet.delegate = self;
    actionSheet.actionSheetStyle = UIActionSheetStyleAutomatic;
    [actionSheet showInView:self.view];
}

- (void)btnDonePressed
{
    [self.textView resignFirstResponder];
}

- (void)btnSavePressed
{
    self.interfaceEnabled   = NO;
    [self.textView resignFirstResponder];
    [self finishWithUpdates];
}


#pragma mark - Helper Methods

- (void)finishWithUpdates
{
    if ([self.delegate respondsToSelector:@selector(editCommentViewController:didUpdateContent:)]) {
        [self.delegate editCommentViewController:self didUpdateContent:self.textView.text];
    }
}

- (void)finishWithoutUpdates
{
    if ([self.delegate respondsToSelector:@selector(editCommentViewControllerFinished:)]) {
        [self.delegate editCommentViewControllerFinished:self];
    }
}


#pragma mark - Static Helpers

+ (instancetype)newEditCommentViewController
{
    return [[[self class] alloc] initWithNibName:NSStringFromClass([self class]) bundle:nil];
}

@end
