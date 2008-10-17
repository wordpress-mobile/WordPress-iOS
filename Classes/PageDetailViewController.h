#import <UIKit/UIKit.h>

@interface PageDetailViewController : UIViewController  {
	IBOutlet UITextView *textView;
	IBOutlet UITextField *titleTextField;
	
	IBOutlet UIView *contentView;
	IBOutlet UIView *subView;
	IBOutlet UITextField *statusTextField;
	IBOutlet UITextField *categoriesTextField;
	IBOutlet UILabel *statusLabel;
	IBOutlet UILabel *categoriesLabel;
	IBOutlet UILabel *titleLabel;
	IBOutlet UIView *textViewContentView;
	IBOutlet UITextField *textViewPlaceHolderField;
}

- (void)refreshUIForCurrentPage;

@end
