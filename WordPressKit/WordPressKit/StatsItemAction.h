#import <Foundation/Foundation.h>

@interface StatsItemAction : NSObject

@property (nonatomic, strong)   NSURL *url;
@property (nonatomic, copy)     NSString *label;
@property (nonatomic, strong)   NSURL *iconURL;
@property (nonatomic, assign)   BOOL defaultAction;

@end
