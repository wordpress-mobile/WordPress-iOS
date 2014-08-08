#import "WPStatsGraphViewController.h"
#import "WPStatsGraphLegendView.h"
#import "WPStatsGraphBarCell.h"
#import <WPStyleGuide.h>
#import "WPStatsCollectionViewFlowLayout.h"
#import "WPStatsGraphBackgroundView.h"
#import "WPStyleGuide+Stats.h"

@interface WPStatsGraphViewController () <UICollectionViewDelegateFlowLayout>

@property (nonatomic, weak) WPStatsCollectionViewFlowLayout *flowLayout;
@property (nonatomic, assign) CGFloat maximumY;
@property (nonatomic, assign) NSUInteger numberOfXValues;
@property (nonatomic, assign) NSUInteger numberOfYValues;

@end

static NSString *const CategoryBarCell = @"CategoryBarCell";
static NSString *const LegendView = @"LegendView";
static NSString *const FooterView = @"FooterView";
static NSString *const GraphBackgroundView = @"GraphBackgroundView";

@implementation WPStatsGraphViewController

- (instancetype)init
{
    WPStatsCollectionViewFlowLayout *layout = [[WPStatsCollectionViewFlowLayout alloc] init];
    self = [super initWithCollectionViewLayout:layout];
    if (self) {
        _flowLayout = layout;
        _numberOfYValues = 7;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.collectionView.backgroundColor = [UIColor lightGrayColor];
    
    self.flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    self.collectionView.allowsMultipleSelection = YES;
    self.collectionView.showsHorizontalScrollIndicator = NO;
    self.collectionView.showsVerticalScrollIndicator = NO;
    self.collectionView.scrollEnabled = NO;
    self.collectionView.contentInset = UIEdgeInsetsMake(0.0f, 40.0f, 0.0f, 15.0f);
    
    [self.collectionView registerClass:[WPStatsGraphBarCell class] forCellWithReuseIdentifier:CategoryBarCell];
    [self.collectionView registerClass:[WPStatsGraphLegendView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:LegendView];
    [self.collectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:FooterView];
    [self.collectionView registerClass:[WPStatsGraphBackgroundView class] forSupplementaryViewOfKind:WPStatsCollectionElementKindGraphBackground withReuseIdentifier:GraphBackgroundView];
    
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    
    [self.collectionView performBatchUpdates:nil completion:nil];
    
    if ([[self.collectionView indexPathsForSelectedItems] count] > 0) {
        NSIndexPath *indexPath = [self.collectionView indexPathsForSelectedItems][0];
        [self collectionView:self.collectionView didSelectItemAtIndexPath:indexPath];
    }
}

#pragma mark - UICollectionViewDelegate methods

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *selectedIndexPaths = [collectionView indexPathsForSelectedItems];
    [selectedIndexPaths enumerateObjectsUsingBlock:^(NSIndexPath *selectedIndexPath, NSUInteger idx, BOOL *stop) {
        if (!([selectedIndexPath compare:indexPath] == NSOrderedSame)) {
            [collectionView deselectItemAtIndexPath:selectedIndexPath animated:YES];
        }
    }];
    
    if ([self.graphDelegate respondsToSelector:@selector(statsGraphViewController:didSelectData:withXLocation:)]) {
        UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
        CGFloat x = cell.center.x + collectionView.contentInset.left;
        [self.graphDelegate statsGraphViewController:self didSelectData:[self barDataForIndexPath:indexPath] withXLocation:x];
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
    return [[self.viewsVisitors viewsVisitorsForUnit:self.currentUnit][StatsViewsCategory] count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    WPStatsGraphBarCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CategoryBarCell forIndexPath:indexPath];
    NSArray *barData = [self barDataForIndexPath:indexPath];
    
    cell.maximumY = self.maximumY;
    cell.numberOfYValues = self.numberOfYValues;
    
    [cell setCategoryBars:barData];
    // TODO :: Name is the same for all points - should put this somewhere better
    [cell setBarName:[self.viewsVisitors viewsVisitorsForUnit:self.currentUnit][StatsViewsCategory][indexPath.row][@"name"]];
    [cell finishedSettingProperties];
    
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        WPStatsGraphLegendView *legend = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:LegendView forIndexPath:indexPath];
        [legend addCategory:NSLocalizedString(@"Views", @"Views Category in Site Stats") withColor:[WPStyleGuide statsLighterBlue]];
        [legend addCategory:NSLocalizedString(@"Visitors", @"Visitors Category in Site Stats") withColor:[WPStyleGuide statsDarkerBlue]];
        [legend finishedAddingCategories];

        return legend;
    } else if ([kind isEqualToString:WPStatsCollectionElementKindGraphBackground]) {
        WPStatsGraphBackgroundView *background = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:GraphBackgroundView forIndexPath:indexPath];
        background.maximumYValue = self.maximumY;
        background.numberOfXValues = self.numberOfXValues;
        background.numberOfYValues = self.numberOfYValues;
        
        return background;
    }
    
    return nil;
}

#pragma mark - UICollectionViewDelegateFlowLayout methods

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat width = 30.0f;
    CGFloat height = CGRectGetHeight(collectionView.frame) - 25.0;
    
    CGSize size = CGSizeMake(width, height);
    
    return size;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    return CGSizeMake(CGRectGetWidth(collectionView.frame), 25.0);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    CGFloat spacing = floorf((CGRectGetWidth(collectionView.frame) - 55 - (30.0 * self.numberOfXValues)) / self.numberOfXValues);
    
    return spacing;
}

#pragma mark - Property methods

- (void)setViewsVisitors:(WPStatsViewsVisitors *)viewsVisitors
{
    _viewsVisitors = viewsVisitors;
    [self calculateMaximumYValue];
}

- (void)setCurrentUnit:(WPStatsViewsVisitorsUnit)currentUnit
{
    _currentUnit = currentUnit;
    [self calculateMaximumYValue];
}

#pragma mark - Private methods

- (void)calculateMaximumYValue
{
    NSDictionary *categoryData = [self.viewsVisitors viewsVisitorsForUnit:self.currentUnit];
    CGFloat maximumY = 0.0f;

    for (NSDictionary *dict in categoryData[StatsViewsCategory]) {
        NSNumber *number = dict[@"count"];
        if (maximumY < [number floatValue]) {
            maximumY = [number floatValue];
        }
    }
    for (NSDictionary *dict in categoryData[StatsVisitorsCategory]) {
        NSNumber *number = dict[@"count"];
        if (maximumY < [number floatValue]) {
            maximumY = [number floatValue];
        }
    }
    
    self.maximumY = maximumY;
    
    NSUInteger countViews = [categoryData[StatsViewsCategory] count];
    NSUInteger countVisitors = [categoryData[StatsVisitorsCategory] count];
    self.numberOfXValues = MAX(countViews, countVisitors);
}

- (NSArray *)barDataForIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *categoryData = [self.viewsVisitors viewsVisitorsForUnit:self.currentUnit];
    
    return @[@{ @"color" : [WPStyleGuide textFieldPlaceholderGrey],
                @"selectedColor" : [WPStyleGuide statsLighterOrange],
                @"value" : categoryData[StatsViewsCategory][indexPath.row][StatsPointCountKey],
                @"name" : StatsViewsCategory
                },
             @{ @"color" : [WPStyleGuide littleEddieGrey],
                @"selectedColor" : [WPStyleGuide jazzyOrange],
                @"value" : categoryData[StatsVisitorsCategory][indexPath.row][StatsPointCountKey],
                @"name" : StatsVisitorsCategory
                }
             ];
}

@end
