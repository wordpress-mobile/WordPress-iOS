#import "MenuItemTypeSelectionView.h"

@interface MenuItemTypeSelectionView ()

@property (nonatomic, strong) UIStackView *stackView;

@end

@implementation MenuItemTypeSelectionView

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.backgroundColor = [UIColor whiteColor];
    self.translatesAutoresizingMaskIntoConstraints = NO;
    
    {
        UIStackView *stackView = [[UIStackView alloc] init];
        
        
        
        [self addSubview:stackView];
        self.stackView = stackView;
    }
}

@end
