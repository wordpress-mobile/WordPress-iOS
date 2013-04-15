//
//  MediaSettings.m
//  WordPress
//
//  Created by Jeffrey Vanneste on 2013-01-12.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "MediaSettings.h"

@interface MediaSettings ()
@property (nonatomic, strong) NSString* parsedHtml;
@property (nonatomic, strong) NSString* parsedCaptionAttributes;
@property (nonatomic, strong) NSString* parsedImageHtml;
@property (nonatomic, strong) NSString* parsedAnchorHtml;
@end


@implementation MediaSettings {}

@synthesize parsedHtml;
@synthesize parsedImageHtml;
@synthesize parsedCaptionAttributes;
@synthesize parsedAnchorHtml;
@synthesize linkHref;
@synthesize captionText;
@synthesize customWidth;
@synthesize customHeight;
@synthesize alignment;

- (void)dealloc {
    parsedHtml = nil;
    parsedImageHtml = nil;
    parsedCaptionAttributes = nil;
    parsedAnchorHtml = nil;
    linkHref = nil;
    captionText = nil;
    customWidth = nil;
    customHeight = nil;
    alignment = nil;
}


- (NSString *) html {
    NSMutableString *html = [NSMutableString string];
    
    // MediaSettings can only generate html if existing parsed html exists
    if (parsedHtml == nil || [parsedHtml isEqualToString:@""] || parsedImageHtml == nil || [parsedImageHtml isEqualToString:@""]) {
        return @"";
    }
    
    // create the caption blocks
    NSString *captionPrefix = nil;
    NSString *captionPostfix = nil;
    if (captionText != nil && ![captionText isEqualToString:@""]) {
        NSString *captionAttributes = @"";
        if (parsedCaptionAttributes == nil || [parsedCaptionAttributes isEqualToString:@""]) {
            captionAttributes = @"";
        } else {
            captionAttributes = [NSString stringWithString:parsedCaptionAttributes];
        }
        if (alignment != nil) {
            captionAttributes = [self replaceOrSetValueInContent:captionAttributes regex:@"align=['\"]([^'\"]*)['\"]?" replacement:[NSString stringWithFormat:@"align=\"%@\"", alignment]];
        }
        if (customWidth != nil) {
            captionAttributes = [self replaceOrSetValueInContent:captionAttributes regex:@"width=['\"]([0-9]*)['\"]?" replacement:[NSString stringWithFormat:@"width=\"%d\"", [customWidth intValue]]];
        }
        captionPrefix = [NSString stringWithFormat:@"[caption%@]", captionAttributes];
        captionPostfix = [NSString stringWithFormat:@"%@[/caption]", captionText];
    } else {
        captionPrefix = @"";
        captionPostfix = @"";
    }
    
    // create the link blocks
    NSString *linkPrefix = @"";
    NSString *linkPostfix = @"";
    if (linkHref != nil) {
        if (![linkHref isEqualToString:@""]) {
            if (parsedAnchorHtml == nil || [parsedAnchorHtml isEqualToString:@""]) {
                linkPrefix = [NSString stringWithFormat:@"<a href=\"%@\">", linkHref];
            } else {
                // temporary remove the trailing >
                linkPrefix = [parsedAnchorHtml substringWithRange:NSMakeRange(0, parsedAnchorHtml.length-1)]; 
                linkPrefix = [NSString stringWithFormat:@"%@>", [self replaceOrSetValueInContent:linkPrefix regex:@"href=['\"]([^'\"]*)['\"]?" replacement:[NSString stringWithFormat:@"href=\"%@\"", linkHref]]];
            }
            linkPostfix = @"</a>";
        } 
    }
    
    // update the image html
    NSString *imageHtml = [NSString stringWithString:parsedImageHtml];
    // temporary remove the trailing />
    imageHtml = [imageHtml substringWithRange:NSMakeRange(0, imageHtml.length-2)];
    if (customWidth != nil) {
        imageHtml = [self replaceOrSetValueInContent:imageHtml regex:@"width=['\"]([0-9]*)['\"]?" replacement:[NSString stringWithFormat:@"width=\"%d\"", [customWidth intValue]]];
    }
    if (customHeight != nil) {
        imageHtml = [self replaceOrSetValueInContent:imageHtml regex:@"height=['\"]([0-9]*)['\"]?" replacement:[NSString stringWithFormat:@"height=\"%d\"", [customHeight intValue]]];
    }
    if (alignment != nil) {
        // add the alignment to the img class field unless it was added to the caption shortcode
        NSString *imageClass = [MediaSettings parseContent:imageHtml regex:@"class=['\"]([^'\"]*)['\"]?" retrievalGroup:1];
        NSMutableArray *imageClasses = [NSMutableArray arrayWithArray:[imageClass componentsSeparatedByString:@" "]];
        [imageClasses removeObject:@""];
        [imageClasses removeObject:@"alignnone"];
        [imageClasses removeObject:@"alignleft"];
        [imageClasses removeObject:@"alignright"];
        [imageClasses removeObject:@"aligncenter"];
        if (captionText == nil || [captionText isEqualToString:@""]) {
            [imageClasses addObject:alignment];
        }
        if ([imageClasses count] > 0) {
            imageClass = [imageClasses componentsJoinedByString:@" "];
            imageHtml = [self replaceOrSetValueInContent:imageHtml regex:@"class=['\"]([^'\"]*)['\"]?" replacement:[NSString stringWithFormat:@"class=\"%@\"", imageClass]];
        }
    }
    imageHtml = [NSString stringWithFormat:@"%@/>", imageHtml];
    
    [html appendFormat:@"%@%@%@%@%@", captionPrefix, linkPrefix, imageHtml, linkPostfix, captionPostfix];
    
    return html;
}

- (NSString *)description {
    NSMutableString *result = [[NSMutableString alloc] init];
    [result appendFormat:@"parsedHtml: %@\n", parsedHtml];
    [result appendFormat:@"parsedAnchorHtml: %@\n", parsedAnchorHtml];
    [result appendFormat:@"parsedImageHtml: %@\n", parsedImageHtml];
    [result appendFormat:@"parsedCaptionAttributes: %@\n", parsedCaptionAttributes];
    [result appendFormat:@"linkHref: %@\n", linkHref];
    [result appendFormat:@"captionText: %@\n", captionText];
    [result appendFormat:@"customWidth: %@\n", customWidth];
    [result appendFormat:@"customHeight: %@\n", customHeight];
    [result appendFormat:@"alignment: %@\n", alignment];
    
    [result appendFormat:@"html: %@\n", [self html]];
    return result;
}

- (NSString *)replaceOrSetValueInContent:(NSString *)content regex:(NSString *)regex replacement:(NSString *)replacement {
    NSError* error = nil;
    NSRegularExpression* regexExpression = [NSRegularExpression
                                            regularExpressionWithPattern:regex
                                            options:NSRegularExpressionCaseInsensitive
                                            error:&error];
    NSArray* matches = [regexExpression matchesInString:content options:NSRegularExpressionCaseInsensitive range:NSMakeRange(0, [content length])];
    for (NSTextCheckingResult* match in matches) {
        if ([match numberOfRanges] > 0) {
            NSMutableString *newContent = [NSMutableString stringWithString:content];
            [newContent replaceCharactersInRange:[match rangeAtIndex:0] withString:replacement];
            return newContent;
        }
    }
    
    // if no match is found return the same content
    return [NSString stringWithFormat:@"%@ %@", content, replacement];
}

#pragma mark - 
#pragma mark - Class methods
+ (NSString *)parseContent:(NSString *)content regex:(NSString *)regex retrievalGroup:(int)retrievalGroup {
    NSError* error = nil;
    NSRegularExpression* regexExpression = [NSRegularExpression
                                            regularExpressionWithPattern:regex
                                            options:NSRegularExpressionCaseInsensitive
                                            error:&error];
    NSArray* matches = [regexExpression matchesInString:content options:NSRegularExpressionCaseInsensitive range:NSMakeRange(0, [content length])];
    for (NSTextCheckingResult* match in matches) {
        if ([match numberOfRanges] > retrievalGroup) {
            return [content substringWithRange:[match rangeAtIndex:retrievalGroup]];
        }
    }
    
    // if nothing is found
    return @"";
}

+ (MediaSettings *)createMediaSettingsForUrlHelper:(NSString *)url content:(NSString *)content includeCaption:(BOOL)includeCaption mediaSettings:(MediaSettings *)mediaSettings {
    if (mediaSettings == nil) {
        mediaSettings = [[MediaSettings alloc] init];
    }
    
    // This will match every [caption...] ... [/caption] and create 3 groups:
    //  Group0: the whole match
    //  Group1: html containing link and img or just img if there is no link
    //  Group2: the img html
    //  Group3: the caption if includeCaption is set
    NSError* error = nil;
    NSRegularExpression* fullMediaRegex;
    if (includeCaption) {
        fullMediaRegex = [NSRegularExpression
                          regularExpressionWithPattern:@"((?:<a [^>]+>)?(<img [^>]+>)(?:<\\/a>)?)([\\s\\S]*)"
                          options:NSRegularExpressionCaseInsensitive
                          error:&error];
    } else {
        fullMediaRegex = [NSRegularExpression
                          regularExpressionWithPattern:@"((?:<a [^>]+>)?(<img [^>]+>)(?:<\\/a>)?)"
                          options:NSRegularExpressionCaseInsensitive
                          error:&error];
    }
    
    // find the first match of url in a media match
    NSArray* matches = [fullMediaRegex matchesInString:content options:NSRegularExpressionCaseInsensitive range:NSMakeRange(0, [content length])];
    for (NSTextCheckingResult* match in matches) {
        NSString* matchText = [content substringWithRange:[match range]];
        if ([matchText rangeOfString:url options:NSCaseInsensitiveSearch].location != NSNotFound) {
            if ([match numberOfRanges] >= 3) {
                // text containing the link and img
                NSString *imageHtml = [content substringWithRange:[match rangeAtIndex:2]];
                mediaSettings.parsedImageHtml = imageHtml;
                NSString *imageSource = [self parseContent:imageHtml regex:@"src=['\"]([^'\"]*)['\"]?" retrievalGroup:1];
                if ([imageSource caseInsensitiveCompare:url] != NSOrderedSame) {
                    // the image source tag does not match the url passed in so look at the next match
                    continue;
                }
                NSString *parsedWidth = [self parseContent:imageHtml regex:@"width=['\"]([0-9]*)['\"]?" retrievalGroup:1];
                if (parsedWidth != nil && ![parsedWidth isEqualToString:@""]) {
                    mediaSettings.customWidth = [NSNumber numberWithInt:[parsedWidth intValue]];
                }
                NSString *parsedHeight = [self parseContent:imageHtml regex:@"height=['\"]([0-9]*)['\"]?" retrievalGroup:1];
                if (parsedHeight != nil && ![parsedHeight isEqualToString:@""]) {
                    mediaSettings.customHeight = [NSNumber numberWithInt:[parsedHeight intValue]];
                }
                if (mediaSettings.alignment == nil) {
                    NSString *imageClasses = [self parseContent:imageHtml regex:@"class=['\"]([^'\"]*)['\"]?" retrievalGroup:1];
                    if ([imageClasses rangeOfString:@"alignleft" options:NSCaseInsensitiveSearch].location != NSNotFound) {
                        mediaSettings.alignment = @"alignleft";
                    } else if ([imageClasses rangeOfString:@"aligncenter" options:NSCaseInsensitiveSearch].location != NSNotFound) {
                        mediaSettings.alignment = @"aligncenter";
                    } else if ([imageClasses rangeOfString:@"alignright" options:NSCaseInsensitiveSearch].location != NSNotFound) {
                        mediaSettings.alignment = @"alignright";
                    } else {
                        mediaSettings.alignment = @"alignnone";
                    }  
                }
            }
            if ([match numberOfRanges] >= 2) {
                // text containing the link and img
                NSString *linkAndImageHtml = [content substringWithRange:[match rangeAtIndex:1]];
                if (!includeCaption) {
                    mediaSettings.parsedHtml = linkAndImageHtml;
                }
                        
                mediaSettings.linkHref = [self parseContent:linkAndImageHtml regex:@"href=['\"]([^'\"]*)['\"]?" retrievalGroup:1];
                if (mediaSettings.linkHref != nil && ![mediaSettings.linkHref isEqualToString:@""]) {
                    NSRange imageHtmlRange = [linkAndImageHtml rangeOfString:mediaSettings.parsedImageHtml];
                    
                    mediaSettings.parsedAnchorHtml = [linkAndImageHtml substringWithRange:NSMakeRange(0, imageHtmlRange.location)];;
                }
            }
            if (includeCaption && [match numberOfRanges] >= 4) {
                mediaSettings.captionText = [content substringWithRange:[match rangeAtIndex:3]];
            }

            break;
        }
    }
    
    return mediaSettings;
}

+ (MediaSettings *)createMediaSettingsForUrl:(NSString *)url content:(NSString *)content {
    MediaSettings *mediaSettings = [[MediaSettings alloc] init];
    
    // This will match every [caption...] ... [/caption] and create 3 groups:
    //  Group0: the whole match
    //  Group1: the caption attributes
    //  Group2: the a and img elements and the caption string
    NSError* error = nil;
    NSRegularExpression* fullMediaRegex = [NSRegularExpression
                                           regularExpressionWithPattern:@"(?:<p>)?\\[(?:wp_)?caption([^\\]]+)\\]([\\s\\S]+?)\\[\\/(?:wp_)?caption\\](?:<\\/p>)?"
                                           options:NSRegularExpressionCaseInsensitive
                                           error:&error];
    
    // find the first match of url in a media match
    BOOL mediaFound = NO;
    NSArray* matches = [fullMediaRegex matchesInString:content options:NSRegularExpressionCaseInsensitive range:NSMakeRange(0, [content length])];
    for (NSTextCheckingResult* match in matches) {
        NSString* matchText = [content substringWithRange:[match range]];
        if ([matchText rangeOfString:url options:NSCaseInsensitiveSearch].location != NSNotFound) {
            mediaSettings.parsedHtml = matchText;
            if ([match numberOfRanges] >= 1) {
                
                // get all the attributes for the caption
                NSString *captionAttributes = [content substringWithRange:[match rangeAtIndex:1]];
                
                mediaSettings.parsedCaptionAttributes = captionAttributes;
                NSString *parsedWidth = [self parseContent:captionAttributes regex:@"width=['\"]([0-9]*)['\"]?" retrievalGroup:1];
                if (parsedWidth != nil && ![parsedWidth isEqualToString:@""]) {
                    mediaSettings.customWidth = [NSNumber numberWithInt:[parsedWidth intValue]];
                }
                mediaSettings.alignment = [[self parseContent:captionAttributes regex:@"align=['\"]([^'\"]*)['\"]?" retrievalGroup:1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            }
            if ([match numberOfRanges] >= 2) {
                NSString *imageHtmlWithCaption = [content substringWithRange:[match rangeAtIndex:2]];
                [self createMediaSettingsForUrlHelper:url content:imageHtmlWithCaption includeCaption:YES mediaSettings:mediaSettings];
            }
            
            mediaFound = YES;
            break;
        }
    }
    
    if (!mediaFound) {
        // if the image didn't have a caption we need to do another search
        [self createMediaSettingsForUrlHelper:url content:content includeCaption:NO mediaSettings:mediaSettings];
    }
    
    return mediaSettings;
}

@end


