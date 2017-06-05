#import "Logging.h"
#import "WPStatsViewController.h"
#import "StatsTableViewController.h"
#import "WPStatsService.h"
#import "InsightsTableViewController.h"
#import "UIViewController+SizeClass.h"

@interface WPStatsViewController () <StatsProgressViewDelegate, WPStatsSummaryTypeSelectionDelegate, UIActionSheetDelegate>

@property (nonatomic, weak) StatsTableViewController *statsTableViewController;
@property (nonatomic, weak) InsightsTableViewController *insightsTableViewController;
@property (nonatomic, weak) IBOutlet UISegmentedControl *statsTypeSegmentControl;
@property (nonatomic, weak) IBOutlet UIProgressView *insightsProgressView;
@property (nonatomic, weak) IBOutlet UIProgressView *statsProgressView;
@property (nonatomic, weak) IBOutlet UIView *insightsContainerView;
@property (nonatomic, weak) IBOutlet UIView *statsContainerView;
@property (nonatomic, weak) UIAlertController *periodActionSheet;

@property (nonatomic, assign) StatsPeriodType previouslySelectedStatsPeriodType;
@property (nonatomic, assign) StatsPeriodType statsPeriodType;
@property (nonatomic, assign) StatsPeriodType lastSelectedStatsPeriodType;
@property (nonatomic, assign) BOOL showingAbbreviatedSegments;

@end

@implementation WPStatsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.statsPeriodType = self.lastSelectedStatsPeriodType;
    self.previouslySelectedStatsPeriodType = self.lastSelectedStatsPeriodType == StatsPeriodTypeInsights ? StatsPeriodTypeDays : self.lastSelectedStatsPeriodType;

    if (!self.isViewHorizontallyCompact) {
        [self showAllSegments];
        self.showingAbbreviatedSegments = NO;
    } else {
        [self showAbbreviatedSegments];
        self.showingAbbreviatedSegments = YES;
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [super prepareForSegue:segue sender:sender];
    
    if ([segue.identifier isEqualToString:@"StatsTableEmbed"]) {
        StatsTableViewController *tableVC = (StatsTableViewController *)segue.destinationViewController;
        self.statsTableViewController = tableVC;
        tableVC.statsDelegate = self.statsDelegate;
        tableVC.statsProgressViewDelegate = self;
        tableVC.statsService = [[WPStatsService alloc] initWithSiteId:self.siteID siteTimeZone:self.siteTimeZone oauth2Token:self.oauth2Token andCacheExpirationInterval:5 * 60];
    } else if ([segue.identifier isEqualToString:@"InsightsTableEmbed"]) {
        InsightsTableViewController *insightsTableViewController = (InsightsTableViewController *)segue.destinationViewController;
        self.insightsTableViewController = insightsTableViewController;
        insightsTableViewController.statsProgressViewDelegate = self;
        insightsTableViewController.statsTypeSelectionDelegate = self;
        insightsTableViewController.statsDelegate = self.statsDelegate;
        if ([self.statsDelegate respondsToSelector:@selector(statsService)])
        {
            insightsTableViewController.statsService = [self.statsDelegate statsService];
        }
        if (insightsTableViewController.statsService == nil)
        {
            insightsTableViewController.statsService = [[WPStatsService alloc] initWithSiteId:self.siteID siteTimeZone:self.siteTimeZone oauth2Token:self.oauth2Token andCacheExpirationInterval:5 * 60];
        }
    }
}

#pragma mark - UIViewController overrides

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];

    if (self.presentedViewController != nil && self.presentedViewController == self.periodActionSheet) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    [self updateSegmentedControlForceUpdate:YES];
}


#pragma mark - Actions

- (IBAction)statsTypeControlDidChange:(UISegmentedControl *)control
{
    if (control.selectedSegmentIndex == 0) {
        self.statsPeriodType = StatsPeriodTypeInsights;
        self.insightsContainerView.hidden = NO;
        if (self.insightsProgressView.progress > 0.0f) {
            self.insightsProgressView.hidden = NO;
        }
        self.statsContainerView.hidden = YES;
        self.statsProgressView.hidden = YES;
        return;
    }
    
    if (self.showingAbbreviatedSegments && control.selectedSegmentIndex == 2) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Select Period Unit", @"Stats Segmented Control Action Sheet on small screens")
                                                                                 message:nil
                                                                          preferredStyle:UIAlertControllerStyleActionSheet];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel button title") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            self.statsTypeSegmentControl.selectedSegmentIndex = self.statsPeriodType == StatsPeriodTypeInsights ? StatsPeriodTypeInsights : 1;
        }];
        UIAlertAction *daysAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Days", @"Title of Days segmented control") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            self.statsPeriodType = StatsPeriodTypeDays;
            self.previouslySelectedStatsPeriodType = StatsPeriodTypeDays;
            [self showAbbreviatedSegments];
        }];
        UIAlertAction *weeksAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Weeks", @"Title of Weeks segmented control") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            self.statsPeriodType = StatsPeriodTypeWeeks;
            self.previouslySelectedStatsPeriodType = StatsPeriodTypeWeeks;
            [self showAbbreviatedSegments];
        }];
        UIAlertAction *monthsAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Months", @"Title of Months segmented control") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            self.statsPeriodType = StatsPeriodTypeMonths;
            self.previouslySelectedStatsPeriodType = StatsPeriodTypeMonths;
            [self showAbbreviatedSegments];
        }];
        UIAlertAction *yearsAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Years", @"Title of Years segmented control") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            self.statsPeriodType = StatsPeriodTypeYears;
            self.previouslySelectedStatsPeriodType = StatsPeriodTypeYears;
            [self showAbbreviatedSegments];
        }];
        
        [alertController addAction:cancelAction];
        [alertController addAction:daysAction];
        [alertController addAction:weeksAction];
        [alertController addAction:monthsAction];
        [alertController addAction:yearsAction];

        // If not displayed full screen, the alert controller is automatically displayed in a popover by the system
        alertController.popoverPresentationController.sourceView = control;
        CGFloat segmentWidth = CGRectGetWidth(control.bounds) / control.numberOfSegments;
        alertController.popoverPresentationController.sourceRect = CGRectMake(control.selectedSegmentIndex * segmentWidth, 0, segmentWidth, CGRectGetHeight(control.bounds));

        self.periodActionSheet = alertController;
        [self presentViewController:alertController animated:YES completion:nil];
    } else {
        self.insightsContainerView.hidden = YES;
        self.insightsProgressView.hidden = YES;
        self.statsContainerView.hidden = NO;
        if (self.statsProgressView.progress > 0.0f) {
            self.statsProgressView.hidden = NO;
        }
   
        if (self.showingAbbreviatedSegments && control.selectedSegmentIndex == 1) {
            self.statsPeriodType = self.previouslySelectedStatsPeriodType;
        } else {
            self.statsPeriodType = control.selectedSegmentIndex;
            self.previouslySelectedStatsPeriodType = self.statsPeriodType;
        }
    }
    
}


#pragma mark - WPStatsSummaryTypeSelectionDelegate methods

- (void)viewController:(UIViewController *)viewController changeStatsSummaryTypeSelection:(StatsSummaryType)statsSummaryType
{
    self.previouslySelectedStatsPeriodType = StatsPeriodTypeDays;
    self.statsPeriodType = StatsPeriodTypeDays;
    
    [self updateSegmentedControlForceUpdate:YES];

    self.insightsContainerView.hidden = YES;
    self.insightsProgressView.hidden = YES;
    self.statsContainerView.hidden = NO;
    if (self.statsProgressView.progress > 0.0f) {
        self.statsProgressView.hidden = NO;
    }
    
    [self.statsTableViewController switchToSummaryType:statsSummaryType];
}

#pragma mark - StatsTableViewControllerDelegate methods


- (void)statsViewControllerDidBeginLoadingStats:(UIViewController *)controller
{
    UIProgressView *progressView = nil;
    BOOL controllerIsVisible = NO;
    if (controller == self.insightsTableViewController) {
        progressView = self.insightsProgressView;
        controllerIsVisible = self.statsPeriodType == StatsPeriodTypeInsights;
    } else if (controller == self.statsTableViewController) {
        progressView = self.statsProgressView;
        controllerIsVisible = self.statsPeriodType != StatsPeriodTypeInsights;
    }
    
    if (controllerIsVisible) {
        progressView.hidden = NO;
    }

    progressView.progress = 0.03f;
}

- (void)statsViewController:(UIViewController *)controller loadingProgressPercentage:(CGFloat)percentage
{
    UIProgressView *progressView = nil;
    BOOL controllerIsVisible = NO;
    if (controller == self.insightsTableViewController) {
        progressView = self.insightsProgressView;
        controllerIsVisible = self.statsPeriodType == StatsPeriodTypeInsights;
    } else if (controller == self.statsTableViewController) {
        progressView = self.statsProgressView;
        controllerIsVisible = self.statsPeriodType != StatsPeriodTypeInsights;
    }
    
    if (controllerIsVisible) {
        progressView.hidden = NO;
    }
    
    [progressView setProgress:(float)percentage animated:YES];
}

- (void)statsViewControllerDidEndLoadingStats:(UIViewController *)controller
{
    UIProgressView *progressView = nil;
    if (controller == self.insightsTableViewController) {
        progressView = self.insightsProgressView;
    } else if (controller == self.statsTableViewController) {
        progressView = self.statsProgressView;
    }

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.25 animations:^{
            progressView.alpha = 0.0f;
        }
                         completion:^(BOOL finished) {
                             progressView.alpha = 1.0f;
                             progressView.hidden = YES;
                             progressView.progress = 0.0f;
                         }];
    });
}


#pragma mark - Private methods

- (void)updateSegmentedControlForceUpdate:(BOOL)forceUpdate
{
//    if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
//        self.statsTypeSegmentControl.selectedSegmentIndex = self.statsPeriodType;
//        self.showingAbbreviatedSegments = NO;
//        return;
//    }
    
    // If rotated from landscape to portrait
    BOOL wasShowingAbbreviatedSegments = self.showingAbbreviatedSegments;
    self.showingAbbreviatedSegments = self.isViewHorizontallyCompact;
    
    if (self.showingAbbreviatedSegments && (wasShowingAbbreviatedSegments == NO || forceUpdate)) {
        [self showAbbreviatedSegments];
        
    } else if ((wasShowingAbbreviatedSegments || forceUpdate) && self.showingAbbreviatedSegments == NO) {
        [self showAllSegments];
    }
}

- (void)showAbbreviatedSegments
{
    [self.statsTypeSegmentControl removeAllSegments];
    [self.statsTypeSegmentControl insertSegmentWithTitle:NSLocalizedString(@"Insights", @"Title of Insights segmented control") atIndex:0 animated:NO];
    
    if (self.previouslySelectedStatsPeriodType == StatsPeriodTypeDays) {
        [self.statsTypeSegmentControl insertSegmentWithTitle:NSLocalizedString(@"Days", @"Title of Days segmented control") atIndex:1 animated:NO];
    } else if (self.previouslySelectedStatsPeriodType == StatsPeriodTypeWeeks) {
        [self.statsTypeSegmentControl insertSegmentWithTitle:NSLocalizedString(@"Weeks", @"Title of Weeks segmented control") atIndex:1 animated:NO];
    } else if (self.previouslySelectedStatsPeriodType == StatsPeriodTypeMonths) {
        [self.statsTypeSegmentControl insertSegmentWithTitle:NSLocalizedString(@"Months", @"Title of Months segmented control") atIndex:1 animated:NO];
    } else if (self.previouslySelectedStatsPeriodType == StatsPeriodTypeYears) {
        [self.statsTypeSegmentControl insertSegmentWithTitle:NSLocalizedString(@"Years", @"Title of Years segmented control") atIndex:1 animated:NO];
    }
    
    [self.statsTypeSegmentControl insertSegmentWithTitle:NSLocalizedString(@"More…", @"Title of more periods segmented control") atIndex:2 animated:NO];
    
    if (self.statsPeriodType == StatsPeriodTypeInsights) {
        self.statsTypeSegmentControl.selectedSegmentIndex = 0;
    } else {
        self.statsTypeSegmentControl.selectedSegmentIndex = 1;
    }
}

- (void)showAllSegments
{
    [self.statsTypeSegmentControl removeAllSegments];
    [self.statsTypeSegmentControl insertSegmentWithTitle:NSLocalizedString(@"Insights", @"Title of Insights segmented control") atIndex:0 animated:NO];
    [self.statsTypeSegmentControl insertSegmentWithTitle:NSLocalizedString(@"Days", @"Title of Days segmented control") atIndex:1 animated:NO];
    [self.statsTypeSegmentControl insertSegmentWithTitle:NSLocalizedString(@"Weeks", @"Title of Weeks segmented control") atIndex:2 animated:NO];
    [self.statsTypeSegmentControl insertSegmentWithTitle:NSLocalizedString(@"Months", @"Title of Months segmented control") atIndex:3 animated:NO];
    [self.statsTypeSegmentControl insertSegmentWithTitle:NSLocalizedString(@"Years", @"Title of Years segmented control") atIndex:4 animated:NO];
    
    self.statsTypeSegmentControl.selectedSegmentIndex = self.statsPeriodType;
}

- (void)setStatsPeriodType:(StatsPeriodType)statsPeriodType
{
    if (statsPeriodType != StatsPeriodTypeInsights && statsPeriodType != _statsPeriodType) {
        StatsPeriodUnit periodUnit = statsPeriodType - 1;
        [self.statsTableViewController changeGraphPeriod:periodUnit];
        self.statsContainerView.hidden = NO;
        self.insightsContainerView.hidden = YES;
    } else {
        self.statsContainerView.hidden = YES;
        self.insightsContainerView.hidden = NO;
    }
    
    _statsPeriodType = statsPeriodType;
    self.lastSelectedStatsPeriodType = statsPeriodType;
}

#pragma mark - Stats type persistence helpers

- (StatsPeriodType)lastSelectedStatsPeriodType
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    StatsPeriodType statsPeriodType = (StatsPeriodType)[userDefaults integerForKey:@"LastSelectedStatsPeriodType"];
    
    DDLogVerbose(@"Last stats period type: %@", @(statsPeriodType));
    return statsPeriodType;
}

- (void)setLastSelectedStatsPeriodType:(StatsPeriodType)lastSelectedStatsPeriodType
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setInteger:lastSelectedStatsPeriodType forKey:@"LastSelectedStatsPeriodType"];
}

@end
