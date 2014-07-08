#import "WPStatsCollectionViewFlowLayout.h"

NSString * const WPStatsCollectionElementKindGraphBackground = @"WPStatsCollectionElementKindGraphBackground";

@implementation WPStatsCollectionViewFlowLayout

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSMutableArray *allAttributes = [NSMutableArray arrayWithArray:[super layoutAttributesForElementsInRect:rect]];
    
    // Assumption is background supplementary view is always visible; may not be the case in the future
    UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:WPStatsCollectionElementKindGraphBackground
                                                                                                                  withIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
    attributes.frame = self.collectionView.bounds;
    attributes.zIndex = -1;
    [allAttributes addObject:attributes];
    
    return [NSArray arrayWithArray:allAttributes];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [super layoutAttributesForItemAtIndexPath:indexPath];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if ([kind isEqualToString:WPStatsCollectionElementKindGraphBackground]) {
        return nil;
    }
    
    UICollectionViewLayoutAttributes *layoutAttributes = [super layoutAttributesForDecorationViewOfKind:kind atIndexPath:indexPath];
    
    return layoutAttributes;
}

@end
