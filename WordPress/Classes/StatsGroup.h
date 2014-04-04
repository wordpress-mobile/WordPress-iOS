#import <Foundation/Foundation.h>
#import "StatsTitleCountItem.h"

@interface StatsGroup : StatsTitleCountItem

@property (nonatomic, strong) NSString *groupName;
@property (nonatomic, strong) NSURL *iconUrl;
@property (nonatomic, strong) NSArray *children;

+ (NSArray *)groupsFromData:(NSArray *)groups;

@end
