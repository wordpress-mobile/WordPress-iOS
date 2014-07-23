#import "WPTableViewControllerSubclass.h"
#import "AbstractPostsViewController.h"
#import "AbstractPostTableViewCell.h"
#import "WPContentViewBase.h"
#import "BasePost.h"

static CGFloat const APVCHeaderHeightPhone = 10.0;
static CGFloat const APVCEstimatedRowHeightIPhone = 400.0;
static CGFloat const APVCEstimatedRowHeightIPad = 600.0;

NSString * const FeaturedImageCellIdentifier = @"FeaturedImageCellIdentifier";
NSString * const NoFeaturedImageCellIdentifier = @"NoFeaturedImageCellIdentifier";

@interface AbstractPostsViewController ()

@property (nonatomic, strong) NSLayoutConstraint *cellForLayoutWidthConstraint;

@end

@implementation AbstractPostsViewController

- (void)dealloc
{
    self.featuredImageSource.delegate = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.tableView registerClass:[self cellClass] forCellReuseIdentifier:NoFeaturedImageCellIdentifier];
    [self.tableView registerClass:[self cellClass] forCellReuseIdentifier:FeaturedImageCellIdentifier];

    CGFloat maxWidth;
    if (IS_IPHONE) {
        maxWidth = MAX(CGRectGetWidth(self.tableView.bounds), CGRectGetHeight(self.tableView.bounds));
    } else {
        maxWidth = WPTableViewFixedWidth;
    }

    CGFloat maxHeight = maxWidth * WPContentViewMaxImageHeightPercentage;
    self.featuredImageSource = [[WPTableImageSource alloc] initWithMaxSize:CGSizeMake(maxWidth, maxHeight)];
    self.featuredImageSource.delegate = self;

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
    if (IS_IPHONE) {
        [self.cachedRowHeights removeAllObjects];
    }
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    BasePost *post = (BasePost *)[self.resultsController objectAtIndexPath:indexPath];
    if ([post respondsToSelector:@selector(featuredImageURLForDisplay)] && [post featuredImageURLForDisplay]) {
        cell = [tableView dequeueReusableCellWithIdentifier:FeaturedImageCellIdentifier];
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:NoFeaturedImageCellIdentifier];
    }

    if (self.tableView.isEditing) {
        cell.accessoryType = UITableViewCellAccessoryNone;
    } else {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }

    [self configureCell:cell atIndexPath:indexPath];

    return cell;
}

- (void)cacheHeight:(CGFloat)height forIndexPath:(NSIndexPath *)indexPath
{
    NSString *key = [NSString stringWithFormat:@"%i", indexPath.row];
    [self.cachedRowHeights setObject:@(height) forKey:key];
}

- (NSNumber *)cachedHeightForIndexPath:(NSIndexPath *)indexPath
{
    NSString *key = [NSString stringWithFormat:@"%i", indexPath.row];
    return [self.cachedRowHeights numberForKey:key];
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSNumber *height = [self cachedHeightForIndexPath:indexPath];
    if (height) {
        return [height floatValue];
    }
    return IS_IPAD ? APVCEstimatedRowHeightIPad : APVCEstimatedRowHeightIPhone;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSNumber *cachedHeight = [self cachedHeightForIndexPath:indexPath];
    if (cachedHeight) {
        return [cachedHeight floatValue];
    }

    [self configureCell:self.cellForLayout atIndexPath:indexPath];
    CGFloat width = IS_IPAD ? WPTableViewFixedWidth : CGRectGetWidth(self.tableView.bounds);
    CGSize size = [self.cellForLayout sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)];
    CGFloat height = ceil(size.height) + 1;

    [self cacheHeight:height forIndexPath:indexPath];
    return height;
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

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [super tableView:tableView willDisplayCell:cell forRowAtIndexPath:indexPath];
    // Preload here to avoid unnecessary preload calls when fetching cells for reasons other than for display.
    [self preloadImagesForCellsAfterIndexPath:indexPath];
}

#pragma mark - Subclass Methods

// Subclasses should override
- (Class)cellClass {
    return [AbstractPostTableViewCell class];
}

- (void)configureCell:(AbstractPostTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    // noop. Subclasses should override.
}

#pragma mark - Featured Image Management

- (CGSize)sizeForFeaturedImage
{
    CGSize imageSize = CGSizeZero;
    imageSize.width = IS_IPAD ? WPTableViewFixedWidth : CGRectGetWidth(self.tableView.bounds);
    imageSize.height = round(imageSize.width * WPContentViewMaxImageHeightPercentage);
    return imageSize;
}

- (void)preloadImagesForCellsAfterIndexPath:(NSIndexPath *)indexPath
{
    NSInteger numberToPreload = 2; // keep the number small else they compete and slow each other down.
    for (NSInteger i = 1; i <= numberToPreload; i++) {
        NSIndexPath *nextIndexPath = [NSIndexPath indexPathForRow:indexPath.row + i inSection:indexPath.section];
        if ([self.tableView numberOfRowsInSection:indexPath.section] > nextIndexPath.row) {
            BasePost *post = (BasePost *)[self.resultsController objectAtIndexPath:nextIndexPath];
            NSURL *imageURL = [post respondsToSelector:@selector(featuredImageURLForDisplay)] ? [post featuredImageURLForDisplay] : nil;
            if (!imageURL) {
                // No image to feature.
                continue;
            }

            UIImage *image = [self imageForURL:imageURL];
            if (image) {
                // already cached.
                continue;
            } else {
                BOOL isPrivate = NO;
                if ([post respondsToSelector:@selector(isPrivate)]) {
                    isPrivate = [post performSelector:@selector(isPrivate)];
                }
                [self.featuredImageSource fetchImageForURL:imageURL
                                                  withSize:[self sizeForFeaturedImage]
                                                 indexPath:nextIndexPath
                                                 isPrivate:isPrivate];
            }
        }
    }
}

- (UIImage *)imageForURL:(NSURL *)imageURL
{
    if (!imageURL) {
        return nil;
    }
    return [self.featuredImageSource imageForURL:imageURL withSize:[self sizeForFeaturedImage]];
}

- (void)setImageForPost:(BasePost *)post forCell:(AbstractPostTableViewCell *)cell indexPath:(NSIndexPath *)indexPath
{
    if ([cell isEqual:self.cellForLayout]) {
        return;
    }

    NSURL *imageURL = [post respondsToSelector:@selector(featuredImageURLForDisplay)] ? [post featuredImageURLForDisplay] : nil;
    if (!imageURL) {
        return;
    }
    UIImage *image = [self imageForURL:imageURL];
    if (image) {
        [cell.postView setFeaturedImage:image];
    } else {
        BOOL isPrivate = NO;
        if ([post respondsToSelector:@selector(isPrivate)]) {
            isPrivate = [post performSelector:@selector(isPrivate)];
        }
        [self.featuredImageSource fetchImageForURL:imageURL
                                          withSize:[self sizeForFeaturedImage]
                                         indexPath:indexPath
                                         isPrivate:isPrivate];
    }
}

#pragma mark - WPTableImageSourceDelegate

- (void)tableImageSource:(WPTableImageSource *)tableImageSource imageReady:(UIImage *)image forIndexPath:(NSIndexPath *)indexPath
{
    AbstractPostTableViewCell *cell = (AbstractPostTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];

    // Don't do anything if the cell is out of view or out of range
    // (this is a safety check in case the Reader doesn't properly kill image requests when changing topics)
    if (cell == nil) {
        return;
    }

    [cell.postView setFeaturedImage:image];
}

@end
