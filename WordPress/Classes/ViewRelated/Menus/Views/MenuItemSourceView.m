#import "MenuItemSourceView.h"
#import "MenusDesign.h"
#import "MenuItemSourceSearchBar.h"

@interface MenuItemSourceView ()

@end

@implementation MenuItemSourceView

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.results = [NSMutableArray array];
    
    {
        MenuItemSourceResult *result = [MenuItemSourceResult new];
        result.title = @"Home";
        result.badgeTitle = @"Site";
        result.selected = YES;
        [self.results addObject:result];
    }
    {
        MenuItemSourceResult *result = [MenuItemSourceResult new];
        result.title = @"About";
        [self.results addObject:result];
    }
    {
        MenuItemSourceResult *result = [MenuItemSourceResult new];
        result.title = @"Work";
        [self.results addObject:result];
    }
    {
        MenuItemSourceResult *result = [MenuItemSourceResult new];
        result.title = @"Contact";
        [self.results addObject:result];
    }
    
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
        margins.left = MenusDesignDefaultContentSpacing;
        margins.bottom = MenusDesignDefaultContentSpacing;
        margins.right = MenusDesignDefaultContentSpacing;
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
    {
        MenuItemSourceSearchBar *searchBar = [[MenuItemSourceSearchBar alloc] init];
        searchBar.translatesAutoresizingMaskIntoConstraints = NO;
        [self.stackView addArrangedSubview:searchBar];
        [searchBar setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisVertical];
        [searchBar setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisVertical];
        
        NSLayoutConstraint *heightConstraint = [searchBar.heightAnchor constraintEqualToConstant:44.0];
        heightConstraint.priority = UILayoutPriorityDefaultHigh;
        heightConstraint.active = YES;
        
        _searchBar = searchBar;
    }
    {
        UITableView *tableView = [[UITableView alloc] init];
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.contentInset = UIEdgeInsetsMake(MenusDesignDefaultContentSpacing / 2.0, 0, MenusDesignDefaultContentSpacing / 2.0, 0);
        tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        tableView.estimatedRowHeight = 50.0;
        tableView.rowHeight = UITableViewAutomaticDimension;
        [tableView setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisVertical];
        [tableView setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisVertical];
        [self.stackView addArrangedSubview:tableView];
        
        _tableView = tableView;
    }
    
    [self.tableView reloadData];
}

#pragma mark - UITableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.results.count;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    MenuItemSourceResultCell *resultCell = (MenuItemSourceResultCell *)cell;
    resultCell.result = [self.results objectAtIndex:indexPath.row];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"MenuItemSourceResultCell";
    MenuItemSourceResultCell *cell = (MenuItemSourceResultCell *)[tableView dequeueReusableCellWithIdentifier:identifier];
    if(!cell) {
        cell = [[MenuItemSourceResultCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    for(MenuItemSourceResult *result in self.results) {
        result.selected = NO;
    }
    
    MenuItemSourceResult *result = [self.results objectAtIndex:indexPath.row];
    result.selected = YES;
}

@end
