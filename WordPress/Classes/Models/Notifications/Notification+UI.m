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
    
    NSDictionary *attributesRegular         = [WPStyleGuide notificationSubjectAttributesRegular];
    NSDictionary *attributesBold            = [WPStyleGuide notificationSubjectAttributesBold];
    NSDictionary *attributesItalics         = [WPStyleGuide notificationSubjectAttributesItalics];
    NSMutableAttributedString *theString    = [[NSMutableAttributedString alloc] initWithString:self.text attributes:attributesRegular];
    
    // Bold text up until "liked", "commented", "matched" or "followed"
    [theString applyAttributesToQuotes:attributesItalics];
    
    for (NotificationURL *url in self.urls) {
        if (url.isUser) {
            [theString addAttributes:attributesBold range:url.range];
        } else if (url.isPost) {
            [theString addAttributes:attributesItalics range:url.range];
        }
    }

    return theString;
}

- (NSAttributedString *)attributedTextRegular
{
    if (!self.text) {
        return [NSAttributedString new];
    }
    
    NSDictionary *attributesRegular         = [WPStyleGuide notificationBlockAttributesRegular];
    NSDictionary *attributesBold            = [WPStyleGuide notificationBlockAttributesBold];
    NSDictionary *attributesItalics         = [WPStyleGuide notificationBlockAttributesItalics];
    NSMutableAttributedString *theString    = [[NSMutableAttributedString alloc] initWithString:self.text attributes:attributesRegular];
    
    [theString applyAttributesToQuotes:attributesBold];
    
    // Note: CoreText isn't working with NSLinkAttributeName constant, because...
    //  DTLinkAttribute     = @"NSLinkAttributeName"
    //  NSLinkAttributeName = @"NSLink"
    for (NotificationURL *url in self.urls) {
        if (url.isPost) {
            [theString addAttributes:attributesItalics range:url.range];
        }
        
        if (!url.url) {
            continue;
        }
        
        [theString addAttribute:DTLinkAttribute value:url.url range:url.range];
        [theString addAttribute:NSForegroundColorAttributeName value:[WPStyleGuide baseLighterBlue] range:url.range];
    }

    // Manually Detect Links!
    NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:nil];
    [detector enumerateMatchesInString:self.text
                               options:kNilOptions
                                 range:NSMakeRange(0, self.text.length)
                            usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
                                [theString addAttribute:DTLinkAttribute value:result.URL range:result.range];
                                [theString addAttribute:NSForegroundColorAttributeName value:[WPStyleGuide baseLighterBlue] range:result.range];
                                
     }];
    
    return theString;
}

- (NSAttributedString *)attributedTextQuoted
{
    if (!self.text) {
        return [NSAttributedString new];
    }
    
    NSDictionary *attributes                = [WPStyleGuide notificationQuotedAttributesItalics];
    NSMutableAttributedString *theString    = [[NSMutableAttributedString alloc] initWithString:self.text attributes:attributes];
    
    return theString;
}

@end

