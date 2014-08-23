#import <Foundation/Foundation.h>
#import "WPStatsTitleCountItem.h"

@interface WPStatsGroup : WPStatsTitleCountItem

@property (nonatomic, strong) NSString *groupName;
@property (nonatomic, strong) NSURL *iconUrl;
@property (nonatomic, strong) NSArray *children;

+ (NSArray *)groupsFromData:(NSArray *)groups;

@end
