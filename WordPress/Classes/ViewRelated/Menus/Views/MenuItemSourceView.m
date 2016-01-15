#import "MenuItemSourceView.h"
#import "MenuItemSourceTextBar.h"
#import "MenusDesign.h"

@interface MenuItemSourceView () <MenuItemSourceTextBarDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;

@end

@implementation MenuItemSourceView

- (id)init
{
    self = [super init];
    if(self) {
        
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.backgroundColor = [UIColor whiteColor];
        _sourceOptions = [NSMutableArray array];
        {
            UIScrollView *scrollView = [[UIScrollView alloc] init];
            scrollView.translatesAutoresizingMaskIntoConstraints = NO;
            scrollView.backgroundColor = [UIColor whiteColor];
            [self addSubview:scrollView];
            
            [NSLayoutConstraint activateConstraints:@[
                                                      [scrollView.topAnchor constraintEqualToAnchor:self.topAnchor],
                                                      [scrollView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
                                                      [scrollView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
                                                      [scrollView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor]
                                                      ]];
            self.scrollView = scrollView;
        }
     
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
            
            [self.scrollView addSubview:stackView];
            
            [NSLayoutConstraint activateConstraints:@[
                                                      [stackView.topAnchor constraintEqualToAnchor:self.scrollView.topAnchor],
                                                      [stackView.leadingAnchor constraintEqualToAnchor:self.scrollView.leadingAnchor],
                                                      [stackView.trailingAnchor constraintEqualToAnchor:self.scrollView.trailingAnchor],
                                                      [stackView.bottomAnchor constraintEqualToAnchor:self.scrollView.bottomAnchor],
                                                      [stackView.centerXAnchor constraintEqualToAnchor:self.scrollView.centerXAnchor]
                                                      ]];
            self.stackView = stackView;
        }
        {
            UITableView *tableView = [[UITableView alloc] init];
            tableView.translatesAutoresizingMaskIntoConstraints = NO;
            
            [self addSubview:tableView];
            
            NSLayoutConstraint *top = [tableView.topAnchor constraintEqualToAnchor:self.stackView.bottomAnchor];
            top.priority = UILayoutPriorityDefaultHigh;
            [NSLayoutConstraint activateConstraints:@[
                                                      top,
                                                      [tableView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
                                                      [tableView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
                                                      [tableView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor]
                                                      ]];
            
            self.tableView = tableView;
        }
    }
    
    return self;
}

- (BOOL)resignFirstResponder
{
    if([self.searchBar isFirstResponder]) {
        return [self.searchBar resignFirstResponder];
    }
    return [super resignFirstResponder];
}

- (void)insertSearchBarIfNeeded
{
    if(self.searchBar) {
        return;
    }
    
    MenuItemSourceTextBar *searchBar = [[MenuItemSourceTextBar alloc] initAsSearchBar];
    searchBar.translatesAutoresizingMaskIntoConstraints = NO;
    searchBar.delegate = self;
    [self.stackView addArrangedSubview:searchBar];
    
    NSLayoutConstraint *heightConstraint = [searchBar.heightAnchor constraintEqualToConstant:48.0];
    heightConstraint.priority = UILayoutPriorityDefaultHigh;
    heightConstraint.active = YES;
    
    [searchBar setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisVertical];
    _searchBar = searchBar;
}

- (void)insertSourceOption:(MenuItemSourceOption *)option
{
    [self.sourceOptions addObject:option];
    
    MenuItemSourceOptionView *optionView = [[MenuItemSourceOptionView alloc] init];
    optionView.sourceOption = option;
    [optionView setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisVertical];
    [self.stackView addArrangedSubview:optionView];
}

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
