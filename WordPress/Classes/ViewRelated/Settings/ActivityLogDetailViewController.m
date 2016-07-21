#import "ActivityLogDetailViewController.h"

@interface ActivityLogDetailViewController ()

@property (nonatomic, strong) NSString *logText;
@property (nonatomic, strong) NSString *logDate;
@property (nonatomic, strong) UITextView *textView;

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

    [WPStyleGuide configureColorsForView:self.view andTableView:nil];

    UITextView *textView = [[UITextView alloc] initWithFrame:self.view.bounds];
    textView.editable = NO;
    textView.text = self.logText;
    textView.font = [WPStyleGuide subtitleFont];
    textView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:textView];
    textView.translatesAutoresizingMaskIntoConstraints = NO;
    
    UILayoutGuide *readableGuide = self.view.readableContentGuide;
    [NSLayoutConstraint activateConstraints:@[
                                              [textView.leadingAnchor constraintEqualToAnchor:readableGuide.leadingAnchor],
                                              [textView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
                                              [textView.trailingAnchor constraintEqualToAnchor:readableGuide.trailingAnchor],
                                              [textView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
                                              ]];
    self.textView = textView;

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

}

- (void)showShareOptions:(id)sender
{
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[self.logText]
                                                                                         applicationActivities:nil];
    activityViewController.modalPresentationStyle = UIModalPresentationPopover;
    activityViewController.popoverPresentationController.barButtonItem = sender;
    [self presentViewController:activityViewController animated:YES completion:nil];
}
@end
