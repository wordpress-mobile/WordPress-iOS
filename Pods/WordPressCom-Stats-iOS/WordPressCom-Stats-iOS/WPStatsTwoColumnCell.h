#import <UIKit/UIKit.h>
#import "WPStatsTitleCountItem.h"
#import "WPTableViewCell.h"


@interface WPStatsTwoColumnCell : WPTableViewCell

@property (nonatomic, assign) BOOL linkEnabled;

+ (CGFloat)heightForRow;

- (void)insertData:(WPStatsTitleCountItem *)cellData;
- (void)setLeft:(NSString *)left withImageUrl:(NSURL *)imageUrl right:(NSString *)right titleCell:(BOOL)titleCell;

@end
