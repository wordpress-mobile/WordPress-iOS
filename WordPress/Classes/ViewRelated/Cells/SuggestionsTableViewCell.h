#import <UIKit/UIKit.h>
#import "WPTableViewCell.h"

@interface SuggestionsTableViewCell : WPTableViewCell
@property (weak, nonatomic) IBOutlet UILabel *username;
@property (weak, nonatomic) IBOutlet UILabel *displayName;
@property (weak, nonatomic) IBOutlet UIImageView *avatar;

@end
