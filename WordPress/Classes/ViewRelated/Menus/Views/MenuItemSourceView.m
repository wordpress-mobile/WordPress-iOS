#import "MenuItemSourceView.h"
#import "MenusDesign.h"

@interface MenuItemSourceView ()

@end

@implementation MenuItemSourceView

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.backgroundColor = [UIColor whiteColor];
    self.translatesAutoresizingMaskIntoConstraints = NO;
    
    {
        UIStackView *stackView = [[UIStackView alloc] init];
        stackView.translatesAutoresizingMaskIntoConstraints = NO;
        stackView.axis = UILayoutConstraintAxisVertical;
        stackView.distribution = UIStackViewDistributionFill;
        stackView.alignment = UIStackViewAlignmentFill;

        UIEdgeInsets margins = UIEdgeInsetsZero;
        margins.top = MenusDesignDefaultContentSpacing;
        margins.left = 40.0;
        margins.right = margins.left;
        margins.bottom = MenusDesignDefaultContentSpacing;
        stackView.layoutMargins = margins;
        stackView.layoutMarginsRelativeArrangement = YES;
        
        [self addSubview:stackView];
        [NSLayoutConstraint activateConstraints:@[
                                                  [stackView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
                                                  [stackView.topAnchor constraintEqualToAnchor:self.topAnchor],
                                                  [stackView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
                                                  [stackView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor]
                                                  ]];
        
        _stackView = stackView;
    }
}

@end
