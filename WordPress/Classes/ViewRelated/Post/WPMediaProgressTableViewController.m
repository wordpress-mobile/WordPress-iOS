#import "WPMediaProgressTableViewController.h"
#import "WPProgressTableViewCell.h"

static NSString * const WPProgressCellIdentifier = @"WPProgressCellIdentifier";
static CGFloat const WPProgressCellHeight = 74.0f;

@interface WPMediaProgressTableViewController ()

@property (nonatomic, strong) NSProgress * masterProgress;
@property (nonatomic, strong) NSArray * childrenProgress;

@end

@implementation WPMediaProgressTableViewController

- (instancetype)initWithMasterProgress:(NSProgress *)masterProgress
             childrenProgress:(NSArray *)childrenProgress
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        _masterProgress = masterProgress;
        _childrenProgress = childrenProgress;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.rowHeight = WPProgressCellHeight;
    if (IS_IPHONE) {
        // Remove one-pixel gap resulting from a top-aligned grouped table view
        UIEdgeInsets tableInset = [self.tableView contentInset];
        tableInset.top = -1;
        self.tableView.contentInset = tableInset;
        
        UIBarButtonItem *doneButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", @"Label for the button to close a view.")
                                                                           style:UIBarButtonItemStylePlain
                                                                          target:self
                                                                          action:@selector(doneButtonTapped:)];
        
        self.navigationItem.leftBarButtonItem = doneButtonItem;
    }
    
    // Cancel button
    UIBarButtonItem *cancelButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel All", @"Label for the button to cancel all progress.")
                                                                         style:UIBarButtonItemStylePlain
                                                                        target:self
                                                                        action:@selector(cancelButtonTapped:)];
    
    self.navigationItem.rightBarButtonItem = cancelButtonItem;
    
    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
    
    [self.tableView registerClass:[WPProgressTableViewCell class] forCellReuseIdentifier:NSStringFromClass([WPProgressTableViewCell class])];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return self.childrenProgress.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WPProgressTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([WPProgressTableViewCell class]) forIndexPath:indexPath];
    
    // Configure the cell...
    [cell setProgress:self.childrenProgress[indexPath.row]];
    [WPStyleGuide configureTableViewCell:cell];
    
    return cell;
}

#pragma mark - Actions

- (IBAction)doneButtonTapped:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)cancelButtonTapped:(id)sender
{
    [self.masterProgress cancel];
}

@end
