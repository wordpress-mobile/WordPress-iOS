#import "StatsGroup.h"

@interface StatsGroup ()

@property (nonatomic, copy, readwrite) NSString *groupTitle;
@property (nonatomic, copy, readwrite) NSString *titlePrimary;
@property (nonatomic, copy, readwrite) NSString *titleSecondary;

@end

@implementation StatsGroup

- (instancetype)initWithStatsSection:(StatsSection)statsSection andStatsSubSection:(StatsSubSection)statsSubSection
{
    self = [super init];
    if (self) {
        _statsSection = statsSection;
        _statsSubSection = statsSubSection;
        
        [self setUpTitles];
    }
    
    return self;
}


- (NSUInteger)numberOfRows
{
    NSUInteger itemCount = 0;
    
    for (StatsItem *item in self.items) {
        itemCount += [item numberOfRows];
    }
    
    return itemCount;
}


- (StatsItem *)statsItemForTableViewRow:(NSInteger)row
{
    NSInteger index = row - (NSInteger)self.offsetRows;
    
    if (index < 0) {
        return nil;
    }

    NSInteger currentIndex = 0;
    return [self statsItemForIndex:index withItems:self.items andCurrentIndex:&currentIndex];
}


- (StatsItem *)statsItemForIndex:(NSInteger)index withItems:(NSArray *)items andCurrentIndex:(NSInteger *)currentIndex
{
    for (StatsItem *item in items) {
        if ((*currentIndex) == index) {
            return item;
        }
        
        if (item.isExpanded == YES) {
            (*currentIndex)++;
            StatsItem *subItem = [self statsItemForIndex:index withItems:item.children andCurrentIndex:currentIndex];
            if (subItem) {
                return subItem;
            } else {
                (*currentIndex)--;
            }
        }
        
        (*currentIndex)++;
    }
    
    return nil;
}


- (void)setUpTitles
{
    switch (self.statsSection) {
        case StatsSectionAuthors:
            self.groupTitle = NSLocalizedString(@"Authors", @"Title for stats section for Authors");
            self.titlePrimary = NSLocalizedString(@"Author", @"");
            self.titleSecondary = NSLocalizedString(@"Views", @"");
            break;
        case StatsSectionClicks:
            self.groupTitle = NSLocalizedString(@"Clicks", @"Title for stats section for Clicks");
            self.titlePrimary = NSLocalizedString(@"Link", @"");
            self.titleSecondary = NSLocalizedString(@"Clicks", @"");
            break;
        case StatsSectionComments:
            self.groupTitle = NSLocalizedString(@"Comments", @"Title for stats section for Comments");
            self.titlePrimary = self.statsSubSection == StatsSubSectionCommentsByAuthor ? NSLocalizedString(@"Author", @"") : NSLocalizedString(@"Title", @"");
            self.titleSecondary = NSLocalizedString(@"Comments", @"");
            break;
        case StatsSectionCountry:
            self.groupTitle = NSLocalizedString(@"Countries", @"Title for stats section for Countries");
            self.titlePrimary = NSLocalizedString(@"Country", @"");
            self.titleSecondary = NSLocalizedString(@"Views", @"");
            break;
        case StatsSectionEvents:
            self.groupTitle = NSLocalizedString(@"Published", @"Title for stats section for Events");
            break;
        case StatsSectionFollowers:
            self.groupTitle = NSLocalizedString(@"Followers", @"Title for stats section for Followers");
            self.titlePrimary = NSLocalizedString(@"Follower", @"");
            self.titleSecondary = NSLocalizedString(@"Since", @"");
            break;
        case StatsSectionPosts:
            self.groupTitle = NSLocalizedString(@"Posts & Pages", @"Title for stats section for Posts & Pages");
            self.titlePrimary = NSLocalizedString(@"Title", @"");
            self.titleSecondary = NSLocalizedString(@"Views", @"");
            break;
        case StatsSectionPublicize:
            self.groupTitle = NSLocalizedString(@"Publicize", @"Title for stats section for Publicize");
            self.titlePrimary = NSLocalizedString(@"Service", @"");
            self.titleSecondary = NSLocalizedString(@"Followers", @"");
            break;
        case StatsSectionReferrers:
            self.groupTitle = NSLocalizedString(@"Referrers", @"Title for stats section for Referrers");
            self.titlePrimary = NSLocalizedString(@"Referrer", @"");
            self.titleSecondary = NSLocalizedString(@"Views", @"");
            break;
        case StatsSectionSearchTerms:
            self.groupTitle = NSLocalizedString(@"Search Terms", @"Title for stats section for Search Terms");
            self.titlePrimary = NSLocalizedString(@"Search", @"");
            self.titleSecondary = NSLocalizedString(@"Views", @"");
            break;
        case StatsSectionTagsCategories:
            self.groupTitle = NSLocalizedString(@"Tags & Categories", @"Title for stats section for Tags & Categories");
            self.titlePrimary = NSLocalizedString(@"Topic", @"");
            self.titleSecondary = NSLocalizedString(@"Views", @"");
            break;
        case StatsSectionVideos:
            self.groupTitle = NSLocalizedString(@"Videos", @"Title for stats section for Videos");
            self.titlePrimary = NSLocalizedString(@"Video", @"");
            self.titleSecondary = NSLocalizedString(@"Views", @"");
            break;
        case StatsSectionPostDetailsMonthsYears:
            self.groupTitle = NSLocalizedString(@"Months and Years", @"Title for stats section for post details months & years");
            self.titlePrimary = NSLocalizedString(@"Period", @"");
            self.titleSecondary = NSLocalizedString(@"Total", @"");
            break;
        case StatsSectionPostDetailsAveragePerDay:
            self.groupTitle = NSLocalizedString(@"Average per Day", @"Title for stats section for post details average per day");
            self.titlePrimary = NSLocalizedString(@"Period", @"");
            self.titleSecondary = NSLocalizedString(@"Overall", @"");
            break;
        case StatsSectionPostDetailsRecentWeeks:
            self.groupTitle = NSLocalizedString(@"Recent Weeks", @"Title for stats section for post details recent weeks");
            self.titlePrimary = NSLocalizedString(@"Period", @"");
            self.titleSecondary = NSLocalizedString(@"Total", @"");
            break;

        case StatsSectionGraph:
        case StatsSectionInsightsAllTime:
        case StatsSectionInsightsMostPopular:
        case StatsSectionInsightsPostActivity:
        case StatsSectionInsightsTodaysStats:
        case StatsSectionInsightsLatestPostSummary:
        case StatsSectionPeriodHeader:
        case StatsSectionWebVersion:
        case StatsSectionPostDetailsGraph:
        case StatsSectionPostDetailsLoadingIndicator:
            break;
    }

}

@end

