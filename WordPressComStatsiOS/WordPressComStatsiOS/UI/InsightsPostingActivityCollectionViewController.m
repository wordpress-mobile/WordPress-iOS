#import "InsightsPostingActivityCollectionViewController.h"
#import "InsightsPostingActivityCollectionViewCell.h"
#import "InsightsContributionGraphHeaderView.h"
#import "InsightsContributionGraphFooterView.h"

static NSString *const PostActivityCollectionCellIdentifier = @"PostActivityCollectionViewCell";
static NSString *const PostActivityCollectionHeaderIdentifier = @"PostingActivityCollectionHeaderView";
static NSString *const PostActivityCollectionFooterIdentifier = @"PostingActivityCollectionFooterView";

@interface InsightsPostingActivityCollectionViewController ()

@end

@implementation InsightsPostingActivityCollectionViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Make the header sticky
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout*)self.collectionViewLayout;
    layout.sectionHeadersPinToVisibleBounds = YES;
    layout.sectionFootersPinToVisibleBounds = YES;
    layout.minimumInteritemSpacing = 1;
    layout.minimumLineSpacing = 1;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return 12;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    InsightsPostingActivityCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:PostActivityCollectionCellIdentifier
                                                                                                forIndexPath:indexPath];    
    NSInteger monthIndex = (-1*indexPath.item);
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDate *graphMonth = [gregorian dateByAddingUnit:NSCalendarUnitMonth value:monthIndex toDate:[NSDate date] options:0];
    cell.contributionGraph.monthForGraph = graphMonth;
    StatsStreak *streakForGraphMonth = [self.streakData copy];
    [streakForGraphMonth pruneItemsOutsideOfMonth:graphMonth];
    cell.contributionGraph.graphData = streakForGraphMonth;

    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
           viewForSupplementaryElementOfKind:(NSString *)kind
                                 atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionReusableView *reusableview = nil;
    
    if (kind == UICollectionElementKindSectionHeader) {
        reusableview = [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                          withReuseIdentifier:PostActivityCollectionHeaderIdentifier
                                                                 forIndexPath:indexPath];
    } else if (kind == UICollectionElementKindSectionFooter) {
        reusableview = [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                          withReuseIdentifier:PostActivityCollectionFooterIdentifier
                                                                 forIndexPath:indexPath];
    }
    return reusableview;
}

@end
