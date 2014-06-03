#import "StatsTitleCountItem.h"
#import "WPTableViewCell.h"

@interface StatsTwoColumnCell : WPTableViewCell

@property (nonatomic, assign) BOOL linkEnabled;

+ (CGFloat)heightForRow;

- (void)insertData:(StatsTitleCountItem *)cellData;
- (void)setLeft:(NSString *)left withImageUrl:(NSURL *)imageUrl right:(NSString *)right titleCell:(BOOL)titleCell;

@end
