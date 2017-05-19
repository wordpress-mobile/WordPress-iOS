#import <Foundation/Foundation.h>
#import "StatsItem.h"
#import "StatsSection.h"

@interface StatsGroup : NSObject

@property (nonatomic, assign, readonly) StatsSection statsSection;
@property (nonatomic, assign, readonly) StatsSubSection statsSubSection;
@property (nonatomic, copy, readonly) NSString *groupTitle;
@property (nonatomic, copy, readonly) NSString *titlePrimary;
@property (nonatomic, copy, readonly) NSString *titleSecondary;

@property (nonatomic, strong) NSArray *items; // StatsItem
@property (nonatomic, assign) BOOL moreItemsExist;
@property (nonatomic, strong) NSURL *iconUrl;
@property (nonatomic, copy)   NSString *totalCount;

@property (nonatomic, assign, getter=isExpanded) BOOL expanded;
@property (nonatomic, assign) BOOL errorWhileRetrieving;
@property (nonatomic, readonly) NSUInteger numberOfRows;
@property (nonatomic, assign) NSUInteger offsetRows;

- (instancetype)initWithStatsSection:(StatsSection)statsSection andStatsSubSection:(StatsSubSection)statsSubSection;

- (StatsItem *)statsItemForTableViewRow:(NSInteger)row;

@end
