#import "ColorsTableViewController.h"
#import <WordPress-iOS-Shared/WPStyleGuide.h>

@interface ColorsTableViewController ()

@property (nonatomic, strong) NSMutableArray *colors;

@end

@interface ColorDetails : NSObject

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) UIColor *color;

+ (instancetype)initWithTitle:(NSString *)title andColor:(UIColor *)color;

@end

@implementation ColorDetails

+ (instancetype)initWithTitle:(NSString *)title andColor:(UIColor *)color {
    ColorDetails *colorDetails = [[self class] new];
    colorDetails.title = title;
    colorDetails.color = color;
    return colorDetails;
}

@end

@implementation ColorsTableViewController

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.title = NSLocalizedString(@"Colors", nil);
        self.colors = [NSMutableArray array];
        for (NSDictionary *colorInformation in [self colorDetails]) {
            [self.colors addObject:[ColorDetails initWithTitle:colorInformation[@"title"] andColor:colorInformation[@"color"]]];
        }
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.colors count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CellIdentifier" forIndexPath:indexPath];
    ColorDetails *colorDetails = [self.colors objectAtIndex:indexPath.row];
    cell.textLabel.text = colorDetails.title;
    cell.backgroundColor = colorDetails.color;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

#pragma mark - Private Methods

- (NSArray *)colorDetails {
    return @[
             @{@"title": @"WordPress Blue", @"color": [WPStyleGuide wordPressBlue]},
             @{@"title": @"Base Lighter Blue", @"color": [WPStyleGuide baseLighterBlue]},
             @{@"title": @"Base Darker Blue", @"color": [WPStyleGuide baseLighterBlue]},
             @{@"title": @"Light Blue", @"color": [WPStyleGuide baseLighterBlue]},
             @{@"title": @"New Kid on the Block Blue", @"color": [WPStyleGuide newKidOnTheBlockBlue]},
             @{@"title": @"Midnight Blue", @"color": [WPStyleGuide midnightBlue]},
             @{@"title": @"Jazzy Orange", @"color": [WPStyleGuide jazzyOrange]},
             @{@"title": @"Fire Orange", @"color": [WPStyleGuide fireOrange]},
             @{@"title": @"Big Eddie Grey", @"color": [WPStyleGuide bigEddieGrey]},
             @{@"title": @"Little Eddie Grey", @"color": [WPStyleGuide littleEddieGrey]},
             @{@"title": @"Whisper Grey", @"color": [WPStyleGuide whisperGrey]},
             @{@"title": @"All T All Shade Grey", @"color": [WPStyleGuide allTAllShadeGrey]},
             @{@"title": @"Read Grey", @"color": [WPStyleGuide readGrey]},
             @{@"title": @"It's Everywhere Grey", @"color": [WPStyleGuide itsEverywhereGrey]},
             @{@"title": @"Dark as Night Grey", @"color": [WPStyleGuide darkAsNightGrey]},
             @{@"title": @"Text Field Placeholder Grey", @"color": [WPStyleGuide textFieldPlaceholderGrey]},
             @{@"title": @"Validation Error Red", @"color": [WPStyleGuide validationErrorRed]},
             @{@"title": @"Table View Action Color", @"color": [WPStyleGuide tableViewActionColor]},
             @{@"title": @"Button Action Color", @"color": [WPStyleGuide buttonActionColor]},
             @{@"title": @"Keyboard Color", @"color": [WPStyleGuide keyboardColor]},
             @{@"title": @"Notifications Light Grey", @"color": [WPStyleGuide notificationsLightGrey]},
             @{@"title": @"Notifications Dark Grey", @"color": [WPStyleGuide notificationsDarkGrey]},
             @{@"title": @"NUX Form Text", @"color": [WPStyleGuide nuxFormText]},
             @{@"title": @"NUX Form Placeholder Text", @"color": [WPStyleGuide nuxFormPlaceholderText]}
             ];
}

@end
