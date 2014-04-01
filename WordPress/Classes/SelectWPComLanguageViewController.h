#import <UIKit/UIKit.h>

typedef void(^SelectWPComLanguageViewControllerBlock)(NSDictionary *);

@interface SelectWPComLanguageViewController : UITableViewController

@property (nonatomic, assign) NSInteger currentlySelectedLanguageId;
@property (nonatomic, copy) SelectWPComLanguageViewControllerBlock didSelectLanguage;

@end