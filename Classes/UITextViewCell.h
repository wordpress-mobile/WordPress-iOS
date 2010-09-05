#import <UIKit/UIKit.h>

// cell identifier for this custom cell
extern NSString *kCellTextView_ID;

@interface UITextViewCell : UITableViewCell {
    IBOutlet UITextView *textView;
}

+ (UITextViewCell *) createNewTextCellFromNib;

@property (nonatomic, retain) UITextView *textView;

@end