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
        default:
            break;
    }
    
    return instructions;
}

@end
