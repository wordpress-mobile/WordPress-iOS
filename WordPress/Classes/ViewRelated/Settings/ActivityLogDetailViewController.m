#import "ActivityLogDetailViewController.h"

@interface ActivityLogDetailViewController ()

@property (nonatomic, strong) NSString *logText;
@property (nonatomic, strong) NSString *logDate;
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) UIPopoverController *popover;

@end

@implementation ActivityLogDetailViewController

- (id)initWithLog:(NSString *)logText forDateString:(NSString *)logDate
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _logText = logText;
        _logDate = logDate;
        self.title = logDate;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.textView = [[UITextView alloc] initWithFrame:self.view.bounds];
    self.textView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.textView.editable = NO;
    self.textView.text = self.logText;
    self.textView.font = [WPStyleGuide subtitleFont];
    [self.view addSubview:self.textView];

    UIBarButtonItem *shareButton = nil;

    shareButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                target:self
                                                                action:@selector(showShareOptions:)];

    self.navigationItem.rightBarButtonItem = shareButton;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self.textView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    if (self.popover) {
        [self.popover dismissPopoverAnimated:animated];
        self.popover = nil;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)showShareOptions:(id)sender
{
    if (NSClassFromString(@"UIActivityViewController") != nil) {
        // If UIActivityViewController is available, use it (iOS 6+)
        UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[self.logText]
                                                                                             applicationActivities:nil];
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            if (self.popover && self.popover.isPopoverVisible) {
                [self.popover dismissPopoverAnimated:YES];
                self.popover = nil;
            } else {
                self.popover = [[UIPopoverController alloc] initWithContentViewController:activityViewController];
                [self.popover presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
            }
        } else {
            [self presentViewController:activityViewController animated:YES completion:nil];
        }
    } else {
        // Otherwise, flip back to an action sheet for < iOS 6
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Share", @"")
                                                                 delegate:self
                                                        cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:NSLocalizedString(@"Mail", @""), nil];

        [actionSheet showFromBarButtonItem:sender animated:YES];
    }

}
@end
