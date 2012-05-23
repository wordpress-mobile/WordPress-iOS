/*
 This class contains the data necessary for collapsing/exanding a section in the panel sidebar.
 Based on example app from Apple at: 
 http://developer.apple.com/library/ios/#samplecode/TableViewUpdates/Introduction/Intro.html
*/

#import <Foundation/Foundation.h>

@class SidebarSectionHeaderView;
@class Blog;


@interface SectionInfo : NSObject 

@property (assign) BOOL open;
@property (strong) Blog* blog;
@property (strong) SidebarSectionHeaderView* headerView;

@property (nonatomic,strong,readonly) NSMutableArray *rowHeights;

- (NSUInteger)countOfRowHeights;
- (id)objectInRowHeightsAtIndex:(NSUInteger)idx;
- (void)insertObject:(id)anObject inRowHeightsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromRowHeightsAtIndex:(NSUInteger)idx;
- (void)replaceObjectInRowHeightsAtIndex:(NSUInteger)idx withObject:(id)anObject;
- (void)insertRowHeights:(NSArray *)rowHeightArray atIndexes:(NSIndexSet *)indexes;
- (void)removeRowHeightsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceRowHeightsAtIndexes:(NSIndexSet *)indexes withRowHeights:(NSArray *)rowHeightArray;

@end
