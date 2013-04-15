//
//  MediaSettings.h
//  WordPress
//
//  Created by Jeffrey Vanneste on 2013-01-12.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MediaSettings : NSObject

// creates a MediaSettings object for the first occurrence of the URL in the content 
+ (MediaSettings *)createMediaSettingsForUrl:(NSString *)url content:(NSString *)content;
- (NSString *) html;

@property (nonatomic, strong, readonly) NSString* parsedHtml;
@property (nonatomic, strong, readonly) NSString* parsedCaptionAttributes;
@property (nonatomic, strong, readonly) NSString* parsedImageHtml;
@property (nonatomic, strong, readonly) NSString* parsedAnchorHtml;

@property (nonatomic, strong) NSString* linkHref;
@property (nonatomic, strong) NSString* captionText;
@property (nonatomic, strong) NSString* alignment;
@property (nonatomic, strong) NSNumber* customWidth;
@property (nonatomic, strong) NSNumber* customHeight;

@end

