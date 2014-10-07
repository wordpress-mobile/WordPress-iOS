#import <UIKit/UIKit.h>

@interface SuggestionsTableView : UITableView <UITableViewDataSource>

-(id)initWithWidth:(CGFloat)width andSiteID:(NSNumber *)siteID;
-(void)filterSuggestionsForKeyPress:(NSString *)keypress inWord:(NSString *)word;

@end
