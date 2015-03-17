#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, ReaderViewStyle) {
    ReaderViewStyleNormal,
    ReaderViewStyleSitePreview
};

@class ReaderTopic;

@interface ReaderPostsViewController : UITableViewController

@property (nonatomic, strong) ReaderTopic *readerTopic;
@property (nonatomic, assign) BOOL skipIpadTopPadding;
@property (nonatomic, assign) ReaderViewStyle readerViewStyle;
@property (nonatomic) BOOL isInReadItLaterMode;

- (void)setTableHeaderView:(UIView *)view;
- (void)readerTopicDidChange;
@end
