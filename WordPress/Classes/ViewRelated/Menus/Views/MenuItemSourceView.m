#import "MenuItemSourceView.h"
#import "MenuItemSourceTextBar.h"
#import "MenusDesign.h"

@interface MenuItemSourceView () <MenuItemSourceTextBarDelegate>

@end

@implementation MenuItemSourceView

- (id)init
{
    self = [super init];
    if(self) {
     
        {
            UIStackView *stackView = [[UIStackView alloc] init];
            stackView.translatesAutoresizingMaskIntoConstraints = NO;
            stackView.distribution = UIStackViewDistributionFill;
            stackView.alignment = UIStackViewAlignmentFill;
            stackView.axis = UILayoutConstraintAxisVertical;
            stackView.spacing = MenusDesignDefaultContentSpacing / 2.0;
            
            UIEdgeInsets margins = UIEdgeInsetsZero;
            margins.top = stackView.spacing;
            margins.left = MenusDesignDefaultContentSpacing;
            margins.right = MenusDesignDefaultContentSpacing;
            margins.bottom = stackView.spacing;
            stackView.layoutMargins = margins;
            stackView.layoutMarginsRelativeArrangement = YES;
            
            [self addSubview:stackView];
            
            [NSLayoutConstraint activateConstraints:@[
                                                      [stackView.topAnchor constraintEqualToAnchor:self.topAnchor],
                                                      [stackView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
                                                      [stackView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
                                                      [stackView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor]
                                                      ]];
            self.stackView = stackView;
        }
    }
    
    return self;
}

- (BOOL)resignFirstResponder
{
    [self.searchBar resignFirstResponder];
    return [super resignFirstResponder];
}

- (void)insertSearchBarIfNeeded
{
    if(self.searchBar) {
        return;
    }
    
    MenuItemSourceTextBar *searchBar = [[MenuItemSourceTextBar alloc] init];
    searchBar.translatesAutoresizingMaskIntoConstraints = NO;
    searchBar.delegate = self;
    [self.stackView addArrangedSubview:searchBar];
    
    NSLayoutConstraint *heightConstraint = [searchBar.heightAnchor constraintEqualToConstant:48.0];
    heightConstraint.priority = UILayoutPriorityDefaultHigh;
    heightConstraint.active = YES;
    
    [searchBar setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisVertical];
    _searchBar = searchBar;
}

/*
- (void)reloadResults
{
    for(UIView *view in self.resultViews) {
        [self.stackView removeArrangedSubview:view];
        [view removeFromSuperview];
    }
    
    self.resultViews = [NSMutableArray arrayWithCapacity:self.results.count];
    for(MenuItemSourceResult *result in self.results) {
        
        MenuItemSourceResultView *view = [[MenuItemSourceResultView alloc] init];
        view.result = result;
        [view setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisVertical];
        
        [self.stackView addArrangedSubview:view];
        [self.resultViews addObject:view];
    }
}
*/

#pragma mark - delegate

- (void)tellDelegateDidBeginEditingWithKeyBoard
{
    [self.delegate sourceViewDidBeginEditingWithKeyBoard:self];
}

- (void)tellDelegateDidEndEditingWithKeyBoard
{
    [self.delegate sourceViewDidEndEditingWithKeyboard:self];
}

#pragma mark - MenuItemSourceTextBarDelegate

- (void)sourceTextBarDidBeginEditing:(MenuItemSourceTextBar *)textBar
{
    [self tellDelegateDidBeginEditingWithKeyBoard];
}

- (void)sourceTextBarDidEndEditing:(MenuItemSourceTextBar *)textBar
{
    [self tellDelegateDidEndEditingWithKeyBoard];
}

- (void)sourceTextBar:(MenuItemSourceTextBar *)textBar didUpdateWithText:(NSString *)text
{
    
}

@end
