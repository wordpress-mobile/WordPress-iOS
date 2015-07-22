#import "SiteTitleViewController.h"
#import "WPTextFieldTableViewCell.h"
#import "WPStyleGuide.h"

static NSString * const SiteTitleTextCell = @"SiteTitleTextCell";

@interface SiteTitleViewController()

@property (nonatomic, strong) WPTextFieldTableViewCell *textFieldCell;

@end

@implementation SiteTitleViewController

- (instancetype)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
    
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.textFieldCell = [[WPTextFieldTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:SiteTitleTextCell];
    self.textFieldCell.textField.clearButtonMode = UITextFieldViewModeAlways;
    self.textFieldCell.minimumLabelWidth = 0.0f;
    self.textFieldCell.textField.placeholder = NSLocalizedString(@"A title for the site", @"Placeholder text for the title of a site");
    [WPStyleGuide configureTableViewTextCell:self.textFieldCell];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0 && indexPath.row == 0)
    {
        return self.textFieldCell;
    }
    return nil;
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0)
    {
        return @"";
    }
    return @"";
}
@end
