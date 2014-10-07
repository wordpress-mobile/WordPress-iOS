#import <UIKit/UIKit.h>

@interface SuggestionsTableView : UITableView <UITableViewDataSource>

- (id)initWithFrame:(CGRect)frame andSiteID:(NSNumber *)siteID;

@end
