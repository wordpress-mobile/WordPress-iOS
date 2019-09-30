#import "ActivityLogViewController.h"
#import "ActivityLogDetailViewController.h"
#import <CocoaLumberjack/DDFileLogger.h>
#import "WordPress-Swift.h"
#import "WPLogger.h"
#import "WPGUIConstants.h"

static NSString *const ActivityLogCellIdentifier = @"ActivityLogCell";

@interface ActivityLogViewController ()

@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, weak) DDFileLogger *fileLogger;
@property (nonatomic, strong) NSArray *logFiles;

@end

@implementation ActivityLogViewController

- (id)init
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        // TODO - Replace this call with an injected value, depending on design conventions already in place
        WordPressAppDelegate *delegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
        _fileLogger = delegate.logger.fileLogger;

        self.title = NSLocalizedString(@"Activity Logs", @"");

        UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Logs", @"")
                                                                       style:UIBarButtonItemStylePlain
                                                                      target:nil
                                                                      action:nil];
        [self.navigationItem setBackBarButtonItem:backButton];
    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [WPStyleGuide configureAutomaticHeightRowsFor:self.tableView];
    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
    [self loadLogFiles];

    [self.tableView registerClass:[WPTableViewCell class] forCellReuseIdentifier:ActivityLogCellIdentifier];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadLogFiles
{
    self.logFiles = self.fileLogger.logFileManager.sortedLogFileInfos;
}

- (NSDateFormatter *)dateFormatter
{
    if (_dateFormatter) {
        return _dateFormatter;
    }
    _dateFormatter = [[NSDateFormatter alloc] init];
    _dateFormatter.dateStyle = NSDateFormatterMediumStyle;
    _dateFormatter.doesRelativeDateFormatting = YES;
    _dateFormatter.timeStyle = NSDateFormatterShortStyle;
    return _dateFormatter;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return self.logFiles.count;
    }

    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    WPTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ActivityLogCellIdentifier];
    if (indexPath.section == 0) {
        DDLogFileInfo *logFileInfo = (DDLogFileInfo *)self.logFiles[indexPath.row];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.text = indexPath.row == 0 ? NSLocalizedString(@"Current", @"") : [self.dateFormatter stringFromDate:logFileInfo.creationDate];
        cell.textLabel.textAlignment = NSTextAlignmentNatural;
        [WPStyleGuide configureTableViewCell:cell];
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.textLabel.text = NSLocalizedString(@"Clear Old Activity Logs", @"");
        [WPStyleGuide configureTableViewActionCell:cell];
    }
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return NSLocalizedString(@"Log Files By Created Date", @"");
    }
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (section == 0) {
        return NSLocalizedString(@"Up to seven days worth of logs are saved.", @"Help text shown below the list of debug logs.");
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section
{
    [WPStyleGuide configureTableViewSectionFooter:view];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.section == 0) {
        DDLogFileInfo *logFileInfo = (DDLogFileInfo *)self.logFiles[indexPath.row];
        NSData *logData = [NSData dataWithContentsOfFile:logFileInfo.filePath];
        NSString *logText = [[NSString alloc] initWithData:logData encoding:NSUTF8StringEncoding];

        ActivityLogDetailViewController *detailViewController = [[ActivityLogDetailViewController alloc] initWithLog:logText
                                                                                                       forDateString:[self.dateFormatter stringFromDate:logFileInfo.creationDate]];
        [self.navigationController pushViewController:detailViewController animated:YES];
    } else {
        for (DDLogFileInfo *logFileInfo in self.logFiles) {
            if (logFileInfo.isArchived) {
                [[NSFileManager defaultManager] removeItemAtPath:logFileInfo.filePath error:nil];
            }
        }

        DDLogWarn(@"All archived log files erased.");

        [self loadLogFiles];
        [self.tableView reloadData];
    }
}

@end
