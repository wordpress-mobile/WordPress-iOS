#import <UIKit/UIKit.h>

@interface InlineComposeToolbarView : UIView

@property (nonatomic, weak) IBOutlet UIView *composerContainerView;
@property (nonatomic) UIColor *borderColor UI_APPEARANCE_SELECTOR;

@end
