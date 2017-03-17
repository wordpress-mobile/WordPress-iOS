#import "Media.h"

@interface Media (HTML)

/**
 Used in Post Editors to generate an embeddable HTML img, video or href string.
 @return String of HTML
 */
- (NSString *)html;

/**
 The image URL string for the "poster" attribute of an HTML video tag.
 @return URL as a string.
 */
- (NSString *)posterAttributeImageURL;

@end
