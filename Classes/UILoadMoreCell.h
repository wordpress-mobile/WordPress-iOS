#import <UIKit/UIKit.h>

// cell identifier for this custom cell
extern NSString *kCellLoadMore_ID;

@interface UILoadMoreCell : UITableViewCell {
    IBOutlet UIActivityIndicatorView *spinner;
    IBOutlet UILabel *mainLabel;
    IBOutlet UILabel *subtitleLabel;
	
	NSString *postType;
	int postCount;
}

+ (UILoadMoreCell *) createNewLoadMoreCellFromNib;

@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *spinner;
@property (nonatomic, retain) IBOutlet UILabel *mainLabel;
@property (nonatomic, retain) IBOutlet UILabel *subtitleLabel;
@property (nonatomic, retain) NSString *postType;
@property (nonatomic, assign) int postCount;

@end