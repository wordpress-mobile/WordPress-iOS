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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark - WPEditorViewControllerDelegate

- (BOOL)editorShouldBeginEditing:(WPEditorViewController *)editorController
{
    NSLog(@"Editor should begin editing?");
    return YES;
}

- (void)editorDidPressSettings:(WPEditorViewController *)editorController
{
    NSLog(@"Pressed Settings!");
}

- (void)editorDidPressMedia:(WPEditorViewController *)editorController
{
    NSLog(@"Pressed Media!");
}

- (void)editorDidPressPreview:(WPEditorViewController *)editorController
{
    NSLog(@"Pressed Preview!");
}

- (void)editorTitleDidChange:(WPEditorViewController *)editorController
{
    NSLog(@"Editor title changed: %@", self.titleText);
}

- (void)editorTextDidChange:(WPEditorViewController *)editorController
{
    NSLog(@"Editor body text changed: %@", self.bodyText);
}

@end
