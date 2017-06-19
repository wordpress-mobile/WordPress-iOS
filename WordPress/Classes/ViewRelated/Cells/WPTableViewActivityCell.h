#import <UIKit/UIKit.h>
#import <WordPressShared/WPTableViewCell.h>

@interface WPTableViewActivityCell : WPTableViewCell {
}

@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *spinner;
@property (nonatomic, strong) IBOutlet UIView *viewForBackground;

@end
