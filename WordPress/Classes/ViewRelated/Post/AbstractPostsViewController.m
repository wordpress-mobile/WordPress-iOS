#import "AbstractPostsViewController.h"
#import "AbstractPostTableViewCell.h"

static CGFloat const APVCHeaderHeightPhone = 10.0;
static CGFloat const APVCEstimatedRowHeightIPhone = 400.0;
static CGFloat const APVCEstimatedRowHeightIPad = 600.0;

@interface AbstractPostsViewController ()

@property (nonatomic, strong) NSLayoutConstraint *cellForLayoutWidthConstraint;

@end

@implementation AbstractPostsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.tableView.estimatedRowHeight = IS_IPAD ? APVCEstimatedRowHeightIPad : APVCEstimatedRowHeightIPhone;

    [self configureCellSeparatorStyle];

    [self configureCellForLayout];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    CGFloat width;
    if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation)) {
        width = CGRectGetWidth(self.tableView.window.frame);
    } else {
        width = CGRectGetHeight(self.tableView.window.frame);
    }
    [self updateCellForLayoutWidthConstraint:width];
}

#pragma mark - Instance Methods

- (void)configureCellSeparatorStyle
{
    // Setting the separator style will cause the table view to redraw all its cells.
    // We want to avoid this when we first load the tableview as there is a performance
    // cost.  As a work around, unset the delegate and datasource, and restore them
    // after setting the style.
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
}

- (void)configureCellForLayout
{
    NSString *CellIdentifier = @"CellForLayoutIdentifier";
    [self.tableView registerClass:[self cellClass] forCellReuseIdentifier:CellIdentifier];
    self.cellForLayout = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    [self updateCellForLayoutWidthConstraint:CGRectGetWidth(self.tableView.bounds)];
}

- (void)updateCellForLayoutWidthConstraint:(CGFloat)width
{
    UIView *contentView = self.cellForLayout.contentView;
    if (self.cellForLayoutWidthConstraint) {
        [contentView removeConstraint:self.cellForLayoutWidthConstraint];
    }
    NSDictionary *views = NSDictionaryOfVariableBindings(contentView);
    NSDictionary *metrics = @{@"width":@(width)};
    self.cellForLayoutWidthConstraint = [[NSLayoutConstraint constraintsWithVisualFormat:@"[contentView(width)]"
                                                                                 options:0
                                                                                 metrics:metrics
                                                                                   views:views] firstObject];
    [contentView addConstraint:self.cellForLayoutWidthConstraint];
}

#pragma mark TableView Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self configureCell:self.cellForLayout atIndexPath:indexPath];
    CGFloat width = IS_IPAD ? WPTableViewFixedWidth : CGRectGetWidth(self.tableView.bounds);
    CGSize size = [self.cellForLayout sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)];
    return ceil(size.height + 1);
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return [[UIView alloc] initWithFrame:CGRectZero];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (IS_IPHONE) {
        return APVCHeaderHeightPhone;
    }
    return [super tableView:tableView heightForHeaderInSection:section];
}

#pragma mark - Subclass Methods

// Subclasses should override
- (Class)cellClass {
    return [AbstractPostTableViewCell class];
}

- (void)configureCell:(AbstractPostTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    // noop. Subclasses should override.
}

@end
