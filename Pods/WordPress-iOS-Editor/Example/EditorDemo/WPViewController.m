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
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Edit"
                                                                             style:UIBarButtonItemStyleBordered
                                                                            target:self
                                                                            action:@selector(editTouchedUpInside)];
}

#pragma mark - Navigation Bar

- (void)editTouchedUpInside
{
    if (self.isEditing) {
        [self stopEditing];
    } else {
        [self startEditing];
    }
}

#pragma mark - IBActions

- (IBAction)exit:(UIStoryboardSegue*)segue
{
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
