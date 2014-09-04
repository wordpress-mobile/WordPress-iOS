#import <UIKit/UIKit.h>
#import "WPTableViewCell.h"

@class Comment;
@class ReaderCommentTableViewCell;

@protocol ReaderCommentTableViewCellDelegate <NSObject>

- (void)readerCommentTableViewCell:(ReaderCommentTableViewCell *)cell didTapURL:(NSURL *)url;

@end

@interface ReaderCommentTableViewCell : WPTableViewCell

@property (nonatomic, weak) id<ReaderCommentTableViewCellDelegate>delegate;

+ (NSAttributedString *)convertHTMLToAttributedString:(NSString *)html withOptions:(NSDictionary *)options;

+ (CGFloat)heightForComment:(Comment *)comment
                      width:(CGFloat)width
                 tableStyle:(UITableViewStyle)tableStyle
              accessoryType:(UITableViewCellAccessoryType *)accessoryType;

- (void)configureCell:(Comment *)comment;

- (void)setAvatar:(UIImage *)image;

@end
