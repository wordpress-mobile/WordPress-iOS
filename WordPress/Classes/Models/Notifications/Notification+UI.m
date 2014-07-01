#import "Notification+UI.h"

#import <DTCoreText/DTCoreTextConstants.h>

#import "NSAttributedString+Util.h"
#import "WPStyleGuide+Notifications.h"



#pragma mark ====================================================================================
#pragma mark NotificationBlock+UI
#pragma mark ====================================================================================

@implementation NotificationBlock (UI)

- (NSAttributedString *)attributedSubject
{
    if (!self.text) {
        return [NSAttributedString new];
    }
    
    NSArray *keywords                       = @[ @"liked", @"commented", @"followed", @"matched", @"reblogged", @"replied" ];
    NSDictionary *attributes                = [WPStyleGuide notificationSubjectAttributes];
    NSDictionary *attributesBold            = [WPStyleGuide notificationSubjectAttributesBold];
    NSDictionary *attributesItalics         = [WPStyleGuide notificationSubjectAttributesItalics];
    NSMutableAttributedString *theString    = [[NSMutableAttributedString alloc] initWithString:self.text attributes:attributes];
    
    // Bold text up until "liked", "commented", "matched" or "followed"
    [theString applyAttributesToQuotes:attributesItalics];
    [theString applyAttributes:attributesBold untilKeywords:keywords];

    return theString;
}

- (NSAttributedString *)attributedText
{
    if (!self.text) {
        return [NSAttributedString new];
    }
    
    NSDictionary *attributes                = [WPStyleGuide notificationBlockAttributes];
    NSDictionary *attributesBold            = [WPStyleGuide notificationBlockAttributesBold];
    NSMutableAttributedString *theString    = [[NSMutableAttributedString alloc] initWithString:self.text attributes:attributes];
    
    [theString applyAttributesToQuotes:attributesBold];
    
    // Note: CoreText isn't working with NSLinkAttributeName constant, because...
    //  DTLinkAttribute     = @"NSLinkAttributeName"
    //  NSLinkAttributeName = @"NSLink"
    for (NotificationURL *url in self.urls) {
        [theString addAttribute:DTLinkAttribute value:url.url range:url.range];
        [theString addAttribute:NSForegroundColorAttributeName value:[WPStyleGuide baseLighterBlue] range:url.range];
    }

    return theString;
}

@end

