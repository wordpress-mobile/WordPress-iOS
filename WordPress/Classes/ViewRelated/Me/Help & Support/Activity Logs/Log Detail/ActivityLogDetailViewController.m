#import "ActivityLogDetailViewController.h"

#import "WordPress-Swift.h"

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

    UITextView *textView = [[UITextView alloc] init];
    textView.editable = NO;
    textView.text = self.logText;
    textView.font = [WPStyleGuide subtitleFont];
    textView.textColor = [UIColor murielText];
    textView.backgroundColor = [UIColor murielListBackground];
    textView.textAlignment = NSTextAlignmentLeft; // Logs aren't RTL friendly
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

    UIBarButtonItem *shareButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                                 target:self
                                                                                 action:@selector(showShareOptions:)];
    self.navigationItem.rightBarButtonItem = shareButton;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self.textView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
}

- (void)showShareOptions:(id)sender
{
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[self.logText]
                                                                                         applicationActivities:nil];
    activityViewController.modalPresentationStyle = UIModalPresentationPopover;
    activityViewController.popoverPresentationController.barButtonItem = sender;

    activityViewController.excludedActivityTypes = [self assembleExcludedSupportTypes];

    [self presentViewController:activityViewController animated:YES completion:nil];
}

/**
 Returns a collection of activity types currently supported by `UIActivityViewController`.
 Were we using Swift 4.2, it might be possible to replace this with `CaseIterable`.

 @return a collection of all supported activity types
 */
- (NSArray<UIActivityType> *)allActivityTypes {
    NSArray<UIActivityType> *systemActivityTypes = @[
                                                     UIActivityTypePostToFacebook,
                                                     UIActivityTypePostToTwitter,
                                                     UIActivityTypePostToWeibo,
                                                     UIActivityTypeMessage,
                                                     UIActivityTypeMail,
                                                     UIActivityTypePrint,
                                                     UIActivityTypeCopyToPasteboard,
                                                     UIActivityTypeAssignToContact,
                                                     UIActivityTypeSaveToCameraRoll,
                                                     UIActivityTypeAddToReadingList,
                                                     UIActivityTypePostToFlickr,
                                                     UIActivityTypePostToVimeo,
                                                     UIActivityTypePostToTencentWeibo,
                                                     UIActivityTypeAirDrop,
                                                     UIActivityTypeOpenInIBooks,
                                                     ];

    NSMutableArray<UIActivityType> *activityTypes = [NSMutableArray arrayWithArray:systemActivityTypes];

    [activityTypes addObject:UIActivityTypeMarkupAsPDF];
    [activityTypes addObject:[SharePost activityType]];

    return activityTypes;
}

/**
 Specifies the activity types that should be excluded when the view controller is presented.

 @return in practice, this will return all but `UIActivityTypeCopyToPasteboard` & `UIActivityTypeMail`.
 */
- (NSArray<UIActivityType> *)assembleExcludedSupportTypes {
    NSMutableSet<UIActivityType> *activityTypes = [NSMutableSet setWithArray:[self allActivityTypes]];

    NSArray<UIActivityType> *supportedActivityTypes = @[
                                                        UIActivityTypeCopyToPasteboard,
                                                        UIActivityTypeMail
                                                        ];
    NSSet<UIActivityType> *supportedActivityTypeSet = [NSSet setWithArray:supportedActivityTypes];
    [activityTypes minusSet:supportedActivityTypeSet];

    return [activityTypes allObjects];
}

@end
