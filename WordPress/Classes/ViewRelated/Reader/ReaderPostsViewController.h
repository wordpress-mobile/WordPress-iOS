#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, ReaderViewStyle) {
    ReaderViewStyleNormal,
    ReaderViewStyleSitePreview
};

@class ReaderAbstractTopic;

@interface ReaderPostsViewController : UITableViewController

@property (nonatomic, strong) ReaderAbstractTopic *readerTopic;
@property (nonatomic, assign) BOOL skipIpadTopPadding;
@property (nonatomic, assign) ReaderViewStyle readerViewStyle;

- (void)setTableHeaderView:(UIView *)view;

@end
