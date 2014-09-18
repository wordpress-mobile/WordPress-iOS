#import "EditCommentViewController.h"
#import "IOS7CorrectedTextView.h"



@interface EditCommentViewController ()

@property (nonatomic,   weak) IBOutlet IOS7CorrectedTextView *textView;

- (void)finishWithUpdates;
- (void)finishWithoutUpdates;

@end

