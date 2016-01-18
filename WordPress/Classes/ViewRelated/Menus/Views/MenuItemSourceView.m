#import "MenuItemSourceView.h"
#import "MenuItemSourceTextBar.h"
#import "MenusDesign.h"

@interface MenuItemSourceView () <MenuItemSourceTextBarDelegate>

/* View used as the tableView.tableHeaderView container view for self.stackView.
 */
@property (nonatomic, strong) UIView *stackedTableHeaderView;

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
            UITableView *tableView = [[UITableView alloc] init];
            tableView.translatesAutoresizingMaskIntoConstraints = NO;
            tableView.dataSource = self;
            tableView.delegate = self;
            [self addSubview:tableView];
            
            [NSLayoutConstraint activateConstraints:@[
                                                      [tableView.topAnchor constraintEqualToAnchor:self.topAnchor],
                                                      [tableView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
                                                      [tableView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
                                                      [tableView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor]
                                                      ]];
            _tableView = tableView;
        }
        {
            // setup the tableHeaderView and keep translatesAutoresizingMaskIntoConstraints to default YES
            // this allows the tableView to handle sizing the view as any other tableHeaderView
            UIView *stackedTableHeaderView = [[UIView alloc] init];
            self.stackedTableHeaderView = stackedTableHeaderView;
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
            
            [self.stackedTableHeaderView addSubview:stackView];
            // setup the constraints for the stackView
            // constrain the horiztonal edges to sync the width to the stackedTableHeaderView
            // do not include a bottom constraint so the stackView can layout its intrinsic height
            [NSLayoutConstraint activateConstraints:@[
                                                      [stackView.topAnchor constraintEqualToAnchor:self.stackedTableHeaderView.topAnchor],
                                                      [stackView.leadingAnchor constraintEqualToAnchor:self.stackedTableHeaderView.leadingAnchor],
                                                      [stackView.trailingAnchor constraintEqualToAnchor:self.stackedTableHeaderView.trailingAnchor]
                                                      ]];
            _stackView = stackView;
        }
    }
    
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if(!self.tableView.tableHeaderView) {
        // set the tableHeaderView after we have called layoutSubviews the first time
        self.tableView.tableHeaderView = self.stackedTableHeaderView;
    }

    // set the stackedTableHeaderView frame height to the intrinsic height of the stackView
    CGRect frame = self.stackView.bounds;
    self.stackedTableHeaderView.frame = frame;
    // reset the tableHeaderView to update the size change
    self.tableView.tableHeaderView = self.stackedTableHeaderView;
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
    /*
    [self.sourceOptions addObject:option];
    
    MenuItemSourceOptionView *optionView = [[MenuItemSourceOptionView alloc] init];
    optionView.sourceOption = option;
    [optionView setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisVertical];
    [self.stackView addArrangedSubview:optionView];
     */
}

#pragma mark - UITableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
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
