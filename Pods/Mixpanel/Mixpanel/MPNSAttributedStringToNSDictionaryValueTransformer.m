//
// Copyright (c) 2014 Mixpanel. All rights reserved.

#import "MPValueTransformers.h"

@implementation MPNSAttributedStringToNSDictionaryValueTransformer

+ (Class)transformedValueClass
{
    return [NSDictionary class];
}

+ (BOOL)allowsReverseTransformation
{
    return YES;
}

- (id)transformedValue:(id)value
{
    if ([value isKindOfClass:[NSAttributedString class]]) {
        NSAttributedString *attributedString = value;

        NSError *error = nil;
        NSData *data = nil;

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
        if ([attributedString respondsToSelector:@selector(dataFromRange:documentAttributes:error:)]) {
            data = [attributedString dataFromRange:NSMakeRange(0, [attributedString length])
                                documentAttributes:@{ NSDocumentTypeDocumentAttribute : NSHTMLTextDocumentType}
                                             error:&error];
        }
#endif
        if (data) {
            return @{
                    @"mime_type" : @"text/html",
                    @"data" : [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]
            };
        } else {
            NSLog(@"Failed to convert NSAttributedString to HTML: %@", error);
        }
    }

    return nil;
}

- (id)reverseTransformedValue:(id)value
{
    if ([value isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dictionaryValue = value;
        NSString *mimeType = dictionaryValue[@"mime_type"];
        NSString *dataString = dictionaryValue[@"data"];

        if ([mimeType isEqualToString:@"text/html"] && dataString) {
            NSError *error = nil;
            NSAttributedString *attributedString;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
            NSData *data = [dataString dataUsingEncoding:NSUTF8StringEncoding];
            attributedString = [[NSAttributedString alloc] initWithData:data
                                                                options:@{ NSDocumentTypeDocumentAttribute : NSHTMLTextDocumentType}
                                                     documentAttributes:NULL
                                                                  error:&error];
#endif
            if (attributedString == nil) {
                NSLog(@"Failed to convert HTML to NSAttributed string: %@", error);
            }

            return attributedString;
        }
    }

    return nil;
}

@end
