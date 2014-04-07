#import "WPContentView.h"
#import "WPContentViewProvider.h"

@class BasePost;

extern NSInteger const MaxNumberOfLinesForTitleForSummary;

@interface BasePostContentView : WPContentView

@property (assign) BOOL showFullContent;

+ (CGFloat)heightForContentViewProvider:(id<WPContentViewProvider>)provider withWidth:(CGFloat)width showFullContent:(BOOL)showFullContent;
+ (NSAttributedString *)titleAttributedStringForTitle:(NSString *)title showFullContent:(BOOL)showFullContent withWidth:(CGFloat) width;
+ (NSAttributedString *)summaryAttributedStringForString:(NSString *)string;

- (id)initWithFrame:(CGRect)frame showFullContent:(BOOL)showFullContent;
- (void)configurePost:(BasePost *)post withWidth:(CGFloat)width;
- (CGFloat)contentWidth;
- (CGFloat)innerContentWidth;

@end
