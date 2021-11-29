#import "EditCommentViewController.h"
#import "CommentViewController.h"
#import "CommentService.h"
#import "ContextManager.h"

#import <WordPressUI/WordPressUI.h>
#import "WordPress-Swift.h"


#pragma mark ==========================================================================================
#pragma mark Private Methods
#pragma mark ==========================================================================================

@interface EditCommentViewController()
@property (readwrite, nonatomic, weak) IBOutlet UITextView *textView;
@property (readwrite, nonatomic, weak) IBOutlet UILabel *placeholderLabel;
@property (nonatomic, strong) NSString *pristineText;
@property (readwrite, nonatomic, assign) CGRect keyboardFrame;

- (void)handleKeyboardDidShow:(NSNotification *)notification;
- (void)handleKeyboardWillHide:(NSNotification *)notification;

@end


#pragma mark ==========================================================================================
#pragma mark EditCommentViewController
#pragma mark ==========================================================================================

@implementation EditCommentViewController

#pragma mark - Static Helpers

/// Tries to determine the correct nibName to use when init'ing
/// If the current class's nib doesn't exist, then we'll use the parent class
+ (NSString *)nibName
{
  Class current = [self class];

  //We use nib because the bundle won't look for xib's
  BOOL nibExists = [[NSBundle mainBundle] pathForResource:NSStringFromClass(current) ofType:@"nib"] ? YES : NO;

  if(!nibExists){
    current = [self superclass];
  }

  nibExists = [[NSBundle mainBundle] pathForResource:NSStringFromClass(current) ofType:@"nib"] ? YES : NO;

  if(!nibExists){
    return nil;
  }

  return NSStringFromClass(current);
}


+ (instancetype)newEditViewController
{
    NSString *xibName = [[self class] nibName];
    
    return [[[self class] alloc] initWithNibName:xibName bundle:nil];
}

#pragma mark - Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Edit Comment", @"");
    self.view.backgroundColor = [UIColor murielBasicBackground];
    self.textView.backgroundColor = [UIColor murielBasicBackground];
    self.textView.textColor = [UIColor murielText];
    self.placeholderLabel.textColor = [UIColor murielTextPlaceholder];
    
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

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // FIX FIX:
    // iOS 8+ is resigning first responder when the presentedViewController is effectively removed from screen.
    // This creates a UX glitch, as a side effect (two animations!!)
    [self.textView resignFirstResponder];
}

#pragma mark - Public
- (void)contentDidChange
{
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
    CGRect keyboardRect = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    self.keyboardFrame = keyboardRect;
    CGSize kbSize = keyboardRect.size;

    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
    self.textView.contentInset = contentInsets;
    self.textView.scrollIndicatorInsets = contentInsets;


    // Scroll the active text field into view.
    CGRect rect = [self.textView caretRectForPosition:self.textView.selectedTextRange.start];

    [self.textView scrollRectToVisible:rect animated:NO];
}

- (void)handleKeyboardWillHide:(NSNotification *)notification
{
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, 0, 0.0);
    self.textView.contentInset = contentInsets;
    self.textView.scrollIndicatorInsets = contentInsets;
    self.keyboardFrame = CGRectZero;
}

#pragma mark - Text View Delegate Methods

- (void)textViewDidChange:(UITextView *)textView
{
    [self contentDidChange];
}

#pragma mark - Button Delegates

- (void)btnCancelPressed
{
    if (self.hasChanges == NO) {
        [self finishWithoutUpdates];
        return;
    }
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"You have unsaved changes.", @"Show when clicking cancel on a comment text box and you didn't save your changes.")
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleActionSheet];
    [alertController addActionWithTitle:NSLocalizedString(@"Cancel", @"")
                                  style:UIAlertActionStyleCancel
                                handler:nil];
    [alertController addActionWithTitle:NSLocalizedString(@"Discard", @"")
                                  style:UIAlertActionStyleDestructive
                                handler:^(UIAlertAction *alertAction) {
                                    [self finishWithoutUpdates];
                                }];
    alertController.popoverPresentationController.barButtonItem = self.navigationItem.leftBarButtonItem;
    [self presentViewController:alertController animated:YES completion:nil];

}

- (void)btnSavePressed
{
    [self finishWithUpdates];
}


#pragma mark - Helper Methods

- (void)finishWithUpdates
{    
    if (self.onCompletion) {
        self.onCompletion(true, self.textView.text);
    }
}

- (void)finishWithoutUpdates
{
    if (self.onCompletion) {
        self.onCompletion(false, self.pristineText);
    }
}

@end
