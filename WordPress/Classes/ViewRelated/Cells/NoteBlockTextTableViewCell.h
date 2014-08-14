#import <UIKit/UIKit.h>
#import "NoteBlockTableViewCell.h"
#import <DTCoreText/DTCoreText.h>



@interface NoteBlockTextTableViewCell : NoteBlockTableViewCell

@property (nonatomic, strong) NSAttributedString         *attributedText;
@property (nonatomic,   copy) NotificationUrlHandler     onUrlClick;

// Helpers: Override if needed
- (NSInteger)numberOfLines;
- (CGFloat)labelPreferredMaxLayoutWidth;

@end
