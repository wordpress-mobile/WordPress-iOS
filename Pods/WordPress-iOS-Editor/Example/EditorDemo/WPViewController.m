#import "WPViewController.h"

@interface WPViewController ()
@end

@implementation WPViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSString *path = [[NSBundle mainBundle] pathForResource:@"content" ofType:@"html"];
    NSString *htmlParam = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    [self setTitleText:@"I'm editing a post!"];
    [self setBodyText:htmlParam];
	self.delegate = self;
}

#pragma mark - WPEditorViewControllerDelegate

- (void)editorDidBeginEditing:(WPEditorViewController *)editorController
{
    NSLog(@"Editor did begin editing.");
}

- (void)editorDidEndEditing:(WPEditorViewController *)editorController
{
    NSLog(@"Editor did end editing.");
}

- (void)editorDidPressMedia:(WPEditorViewController *)editorController
{
    NSLog(@"Pressed Media!");
}

- (void)editorTitleDidChange:(WPEditorViewController *)editorController
{
    NSLog(@"Editor title changed: %@", self.titleText);
    NSString *s = editorController.bodyText;
    NSLog(@"%@", s);
}

- (void)editorTextDidChange:(WPEditorViewController *)editorController
{
    NSLog(@"Editor body text changed: %@", self.bodyText);
}

@end
