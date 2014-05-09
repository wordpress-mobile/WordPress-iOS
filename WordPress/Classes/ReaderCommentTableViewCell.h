#import <UIKit/UIKit.h>
#import "ReaderTableViewCell.h"
#import "ReaderComment.h"
#import "WPTableViewCell.h"

@class ReaderCommentTableViewCell;

@protocol ReaderCommentTableViewCellDelegate <NSObject>

- (void)readerCommentTableViewCell:(ReaderCommentTableViewCell *)cell didTapURL:(NSURL *)url;
- (void)readerCommentTableViewCellDidTapReply:(ReaderCommentTableViewCell *)cell;

@end

@interface ReaderCommentTableViewCell : WPTableViewCell

@property (nonatomic, weak) id<ReaderCommentTableViewCellDelegate>delegate;

+ (NSAttributedString *)convertHTMLToAttributedString:(NSString *)html withOptions:(NSDictionary *)options;

+ (CGFloat)heightForComment:(ReaderComment *)comment
					  width:(CGFloat)width
				 tableStyle:(UITableViewStyle)tableStyle
			  accessoryType:(UITableViewCellAccessoryType *)accessoryType;

- (void)configureCell:(ReaderComment *)comment;

@end
