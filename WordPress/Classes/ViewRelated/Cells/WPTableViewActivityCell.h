#import <UIKit/UIKit.h>
#import <WordPressUIKit/WPTableViewCell.h>

@interface WPTableViewActivityCell : WPTableViewCell {
}

@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *spinner;
@property (nonatomic, strong) IBOutlet UIView *viewForBackground;

@end
