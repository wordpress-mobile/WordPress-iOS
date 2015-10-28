#import "MenusHeaderStackView.h"
#import "MenusSelectionStackView.h"
#import "Blog.h"

@interface MenusHeaderStackView ()

@property (nonatomic, weak) IBOutlet MenusSelectionStackView *locationsStackView;
@property (nonatomic, weak) IBOutlet MenusSelectionStackView *menusStackView;
@property (nonatomic, weak) IBOutlet UILabel *textLabel;

@end

@implementation MenusHeaderStackView

- (void)updateWithMenusForBlog:(Blog *)blog
{
    
}

@end
