#import "WPStatsMixpanelClient.h"
#import <Mixpanel/Mixpanel.h>
#import "WPStatsMixpanelClientInstructionsForStat.h"

@implementation WPStatsMixpanelClient

- (void)track:(WPStat)stat
{
    [self track:stat withProperties:nil];
}

- (void)track:(WPStat)stat withProperties:(NSDictionary *)properties
{
    WPStatsMixpanelClientInstructionsForStat *instructions = [self instructionsForStat:stat];
    if (instructions == nil) {
        NSLog(@"No instructions, do nothing");
        return;
    }
    
    [self callOutToMixpanelWithMetadata:instructions andProperties:properties];
}

// Private Methods

- (void)callOutToMixpanelWithMetadata:(WPStatsMixpanelClientInstructionsForStat *)instructions andProperties:(NSDictionary *)properties
{
    if ([instructions.mixpanelEventName length] > 0) {
        [[Mixpanel sharedInstance] track:instructions.mixpanelEventName properties:properties];
    }
    
    if ([instructions.superPropertyToIncrement length] > 0) {
        [self incrementSuperProperty:instructions.superPropertyToIncrement];
    }
    
    if ([instructions.peoplePropertyToIncrement length] > 0) {
        [self incrementPeopleProperty:instructions.peoplePropertyToIncrement];
    }
}

- (void)incrementPeopleProperty:(NSString *)property
{
    [[Mixpanel sharedInstance].people increment:property by:@(1)];
}

- (void)incrementSuperProperty:(NSString *)property
{
    NSMutableDictionary *superProperties = [[NSMutableDictionary alloc] initWithDictionary:[Mixpanel sharedInstance].currentSuperProperties];
    NSUInteger propertyValue = [superProperties[property] integerValue];
    superProperties[property] = @(++propertyValue);
    [[Mixpanel sharedInstance] registerSuperProperties:superProperties];
}

- (WPStatsMixpanelClientInstructionsForStat *)instructionsForStat:(WPStat )stat
{
    WPStatsMixpanelClientInstructionsForStat *instructions;
    
    switch (stat) {
        case WPStatApplicationOpened:
            instructions = [WPStatsMixpanelClientInstructionsForStat initWithMixpanelEventName:@"Application Opened"];
            break;
        case WPStatApplicationClosed:
            instructions = [WPStatsMixpanelClientInstructionsForStat initWithMixpanelEventName:@"Application Closed"];
            break;
        case WPStatThemesAccessThemeBrowser:
            instructions = [WPStatsMixpanelClientInstructionsForStat initWithMixpanelEventName:@"Theme - Access Theme Browser"];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_accessed_theme_browser"];
            break;
        case WPStatThemesChangedTheme:
            instructions = [WPStatsMixpanelClientInstructionsForStat initWithMixpanelEventName:@"Theme - Changed Theme"];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_changed_theme"];
            break;
        case WPStatReaderAccessedReader:
            instructions = [WPStatsMixpanelClientInstructionsForStat initWithMixpanelEventName:@"Reader - Accessed Reader"];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_accessed_reader"];
            break;
        case WPStatReaderOpenedArticle:
            instructions = [WPStatsMixpanelClientInstructionsForStat initWithMixpanelEventName:@"Reader - Opened Article"];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_opened_article"];
            break;
        case WPStatReaderLikedArticle:
            instructions = [WPStatsMixpanelClientInstructionsForStat initWithMixpanelEventName:@"Reader - Liked Article"];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_liked_article"];
            break;
        case WPStatReaderRebloggedArticle:
            instructions = [WPStatsMixpanelClientInstructionsForStat initWithMixpanelEventName:@"Reader - Reblogged Article"];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_reblogged_article"];
            break;
        case WPStatReaderInfiniteScroll:
            instructions = [WPStatsMixpanelClientInstructionsForStat initWithMixpanelEventName:@"Reader - Infinite Scroll"];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_reader_performed_infinite_scroll"];
            break;
        case WPStatReaderFollowedReaderTag:
            instructions = [WPStatsMixpanelClientInstructionsForStat initWithMixpanelEventName:@"Reader - Followed Reader Tag"];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_followed_reader_tag"];
            break;
        case WPStatReaderUnfollowedReaderTag:
            instructions = [WPStatsMixpanelClientInstructionsForStat initWithMixpanelEventName:@"Reader - Unfollowed Reader Tag"];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_unfollowed_reader_tag"];
            break;
        case WPStatReaderFilteredByReaderTag:
            instructions = [WPStatsMixpanelClientInstructionsForStat initWithMixpanelEventName:@"Reader - Filtered By Reader Tag"];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_filtered_by_reader_tag"];
            break;
        case WPStatReaderLoadedFreshlyPressed:
            instructions = [WPStatsMixpanelClientInstructionsForStat initWithMixpanelEventName:@"Reader - Loaded Freshly Pressed"];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_loaded_freshly_pressed"];
            break;
        case WPStatReaderCommentedOnArticle:
            instructions = [WPStatsMixpanelClientInstructionsForStat initWithMixpanelEventName:@"Reader - Commented on Article"];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_commented_on_reader_article"];
            break;
        default:
            break;
    }
    
    return instructions;
}

@end
