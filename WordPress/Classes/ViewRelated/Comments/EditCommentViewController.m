#import "EditCommentViewController.h"
#import "CommentViewController.h"
#import "CommentService.h"
#import "ContextManager.h"
#import "IOS7CorrectedTextView.h"



@interface EditCommentViewController() <UIActionSheetDelegate>

@property (nonatomic,   weak) IBOutlet IOS7CorrectedTextView    *textView;
@property (nonatomic, strong) NSString                          *pristineText;
@property (nonatomic, assign) CGRect                            keyboardFrame;
@property (nonatomic, assign) BOOL                              interfaceEnabled;

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

    self.textView.text  = self.comment.content;
    self.pristineText   = self.textView.text;
    
    [self.textView becomeFirstResponder];
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

- (void)textViewDidEndEditing:(UITextView *)aTextView
{
    if (IS_IPAD == NO) {
        [self showCancelBarButton];
    }
}


#pragma mark - Helper Methods

- (void)dismissWithUpdates:(BOOL)hasUpdates
{    
    if ([self.delegate respondsToSelector:@selector(editCommentViewController:finishedWithUpdates:)]) {
        [self.delegate editCommentViewController:self finishedWithUpdates:hasUpdates];
    }
}


#pragma mark - UIActionSheet delegate methods

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        [self dismissWithUpdates:NO];
    }
}


#pragma mark - Button Delegates

- (void)btnCancelPressed
{
    if (self.hasChanges == NO) {
        [self dismissWithUpdates:NO];
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
    [self.textView resignFirstResponder];
    
    if (self.hasChanges == NO) {
        [self dismissWithUpdates:NO];
        return;
    }
    
    [self setInterfaceEnabled:NO];
    self.comment.content = self.textView.text;
    
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    CommentService *commentService  = [[CommentService alloc] initWithManagedObjectContext:context];
    
    [commentService uploadComment:self.comment success:^{
        [self dismissWithUpdates:YES];
    } failure:^(NSError *error) {
        NSString *message = NSLocalizedString(@"There has been an error. Please, try again later", @"Error displayed if a comment fails to get updated");
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                            message:message
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"Accept", nil)
                                                  otherButtonTitles:nil,
                                  nil];
        [alertView show];
        
        [self setInterfaceEnabled:YES];
    }];
}

@end
