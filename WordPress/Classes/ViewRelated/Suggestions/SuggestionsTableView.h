#import <UIKit/UIKit.h>

@interface SuggestionsTableView : UITableView <UITableViewDataSource>

- (id)initWithWidth:(CGFloat)width andSiteID:(NSNumber *)siteID;
- (void)filterSuggestionsForText:(NSString *)text;

@end
