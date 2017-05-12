#import "WPStatsGraphViewController.h"
#import "WPStatsGraphLegendView.h"
#import "WPStatsGraphBarCell.h"
#import "WPStatsCollectionViewFlowLayout.h"
#import "WPStatsGraphBackgroundView.h"
#import "WPStyleGuide+Stats.h"
#import "UIViewController+SizeClass.h"

@interface WPStatsGraphViewController () <UICollectionViewDelegateFlowLayout>
{
    NSUInteger _selectedBarIndex;
}

@property (nonatomic, weak) WPStatsCollectionViewFlowLayout *flowLayout;
@property (nonatomic, assign) CGFloat maximumY;
@property (nonatomic, assign) NSUInteger numberOfXValues;
@property (nonatomic, assign) NSUInteger numberOfYValues;

@property (nonatomic, strong) StatsVisits *visits;
@property (nonatomic, strong) NSArray<StatsSummary *> *statsData;
@property (nonatomic, assign) StatsSummaryType currentSummaryType;
@property (nonatomic, strong) NSDate *selectedDate;

@end

static NSString *const CategoryBarCell = @"CategoryBarCell";
static NSString *const LegendView = @"LegendView";
static NSString *const FooterView = @"FooterView";
static NSString *const GraphBackgroundView = @"GraphBackgroundView";
static NSInteger const RecommendedYAxisTicks = 2;

@implementation WPStatsGraphViewController

- (instancetype)init
{
    WPStatsCollectionViewFlowLayout *layout = [[WPStatsCollectionViewFlowLayout alloc] init];
    self = [super initWithCollectionViewLayout:layout];
    if (self) {
        _flowLayout = layout;
        _numberOfYValues = 2;
        _maximumY = 0;
        _allowDeselection = YES;
        _currentSummaryType = StatsSummaryTypeViews;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.collectionView registerClass:[WPStatsGraphBarCell class] forCellWithReuseIdentifier:CategoryBarCell];
    [self.collectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:FooterView];
    [self.collectionView registerClass:[WPStatsGraphBackgroundView class] forSupplementaryViewOfKind:WPStatsCollectionElementKindGraphBackground withReuseIdentifier:GraphBackgroundView];

    self.collectionView.backgroundColor = [UIColor lightGrayColor];
    
    self.flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    self.collectionView.allowsMultipleSelection = YES;
    self.collectionView.showsHorizontalScrollIndicator = NO;
    self.collectionView.showsVerticalScrollIndicator = NO;
    self.collectionView.scrollEnabled = NO;
    self.collectionView.contentInset = UIEdgeInsetsMake(0.0f, 15.0f, 10.0f, 40.0f);
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        // Forces data to be re-analyzed and drawn
        [self setVisits:self.visits forSummaryType:self.currentSummaryType withSelectedDate:self.selectedDate];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
    }];
}

#pragma mark - UICollectionViewDelegate methods

- (BOOL)collectionView:(UICollectionView *)collectionView shouldDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    return self.allowDeselection;
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.graphDelegate respondsToSelector:@selector(statsGraphViewController:shouldSelectDate:)]) {
        StatsSummary *summary = (StatsSummary *)self.statsData[(NSUInteger)indexPath.row];
        return [self.graphDelegate statsGraphViewController:self shouldSelectDate:summary.date];
    }
    
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *selectedIndexPaths = [collectionView indexPathsForSelectedItems];
    [selectedIndexPaths enumerateObjectsUsingBlock:^(NSIndexPath *selectedIndexPath, NSUInteger idx, BOOL *stop) {
        if (!([selectedIndexPath compare:indexPath] == NSOrderedSame)) {
            [collectionView deselectItemAtIndexPath:selectedIndexPath animated:YES];
        }
    }];
    
    if ([self.graphDelegate respondsToSelector:@selector(statsGraphViewController:didSelectDate:)]) {
        StatsSummary *summary = (StatsSummary *)self.statsData[(NSUInteger)indexPath.row];
        [self.graphDelegate statsGraphViewController:self didSelectDate:summary.date];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[collectionView indexPathsForSelectedItems] count] == 0
        && [self.graphDelegate respondsToSelector:@selector(statsGraphViewControllerDidDeselectAllBars:)]) {
        [self.graphDelegate statsGraphViewControllerDidDeselectAllBars:self];
    }
}

#pragma mark - UICollectionViewDataSource methods

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return (NSInteger)self.statsData.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    WPStatsGraphBarCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CategoryBarCell forIndexPath:indexPath];
    NSArray *barData = [self barDataForIndexPath:indexPath];
    
    cell.maximumY = self.maximumY;
    cell.numberOfYValues = self.numberOfYValues;
    
    [cell setCategoryBars:barData];
    cell.barName = [self.statsData[(NSUInteger)indexPath.row] label];
    [cell finishedSettingProperties];
    
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if ([kind isEqualToString:WPStatsCollectionElementKindGraphBackground]) {
        WPStatsGraphBackgroundView *background = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:GraphBackgroundView forIndexPath:indexPath];
        background.maximumYValue = (NSUInteger)self.maximumY;
        background.numberOfXValues = self.numberOfXValues;
        background.numberOfYValues = self.numberOfYValues;
        
        return background;
    }
    
    return nil;
}

#pragma mark - UICollectionViewDelegateFlowLayout methods

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGRect rect = UIEdgeInsetsInsetRect(collectionView.bounds, collectionView.contentInset);
    CGFloat width = floor((CGRectGetWidth(rect) / self.numberOfXValues) - 5.0);
    CGFloat height = CGRectGetHeight(rect);

    CGSize size = CGSizeMake(width < 0 ? 0 : width, height < 0 ? 0 : height);
    
    return size;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    CGRect rect = UIEdgeInsetsInsetRect(collectionView.bounds, collectionView.contentInset);
    CGFloat width = floor((CGRectGetWidth(rect) / self.numberOfXValues) - 5.0);

    CGFloat spacing = floor((CGRectGetWidth(rect) - (width * self.numberOfXValues)) / self.numberOfXValues);

    return spacing < 0 ? 0 : spacing;
}

#pragma mark - Public class methods

- (void)selectGraphBarWithDate:(NSDate *)selectedDate
{
    self.selectedDate = selectedDate;
    
    for (StatsSummary *summary in self.statsData) {
        NSInteger index = (NSInteger)[self.statsData indexOfObject:summary];
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];

        if ([summary.date isEqualToDate:selectedDate]) {
            [self.collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
        } else {
            [self.collectionView deselectItemAtIndexPath:indexPath animated:NO];
        }
    }
}

- (void)doneSettingProperties
{
    [self calculateMaximumYValue];
}

- (void)setVisits:(StatsVisits *)visits forSummaryType:(StatsSummaryType)summaryType withSelectedDate:(NSDate *)selectedDate
{
    self.visits = visits;
    [self truncateDataIfNecessary];
    
    self.currentSummaryType = summaryType;

    [self doneSettingProperties];
    [self.collectionView reloadData];
    [self selectGraphBarWithDate:selectedDate];
}

#pragma mark - Private methods

- (void)truncateDataIfNecessary
{
    self.statsData = [self.visits.statsData copy];
    if (self.isViewHorizontallyCompact && self.visits.statsData.count > 7) {
        self.statsData = [self.visits.statsData subarrayWithRange:NSMakeRange(self.visits.statsData.count - 7, 7)];
    }
}

- (void)calculateMaximumYValue
{
    CGFloat maximumY = 0.0f;
    for (StatsSummary *summary in self.statsData) {
        NSNumber *value = [self valueForCurrentTypeFromSummary:summary];
        if (maximumY < value.floatValue) {
            maximumY = value.floatValue;
        }
    }
    
    // Y axis line markers and values
    // Round up and extend past max value to the next step
    NSUInteger yAxisTicks = RecommendedYAxisTicks;
    NSUInteger stepValue = 1;

    if (maximumY > 0) {
        CGFloat s = (CGFloat)maximumY/(CGFloat)yAxisTicks;
        long len = (long)(double)log10(s);
        long div = (long)(double)pow(10, len);
        stepValue = (NSUInteger)(ceil(s / div) * (CGFloat)div);

        // Adjust yAxisTicks to accomodate ticks and maximum without too much padding
        yAxisTicks = (NSUInteger)ceil( maximumY / stepValue );
        self.maximumY = stepValue * yAxisTicks;
        self.numberOfYValues = yAxisTicks;
    }
    
    self.numberOfXValues = self.statsData.count;
}

- (NSArray *)barDataForIndexPath:(NSIndexPath *)indexPath
{
    return @[@{ @"color" : [WPStyleGuide wordPressBlue],
                @"selectedColor" : [WPStyleGuide statsDarkerOrange],
                @"highlightedColor" : [WPStyleGuide statsMediumBlue],
                @"value" : [self valueForCurrentTypeFromSummary:self.statsData[(NSUInteger)indexPath.row]],
                @"name" : @"views"
                },
             ];
}

- (NSNumber *)valueForCurrentTypeFromSummary:(StatsSummary *)summary
{
    NSNumber *value = nil;
    switch (self.currentSummaryType) {
        case StatsSummaryTypeViews:
            value = @([summary.viewsValue integerValue]);
            break;
        case StatsSummaryTypeVisitors:
            value = @([summary.visitorsValue integerValue]);
            break;
        case StatsSummaryTypeComments:
            value = @([summary.commentsValue integerValue]);
            break;
        case StatsSummaryTypeLikes:
            value = @([summary.likesValue integerValue]);
            break;
    }

    return value;
}

@end
