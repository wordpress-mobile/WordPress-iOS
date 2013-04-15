//
//  MediaSettingsTests.m
//  WordPress
//
//  Created by Jeffrey Vanneste on 2013-01-12.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "MediaSettingsTests.h"

@implementation MediaSettingsTests

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testParseSettingsWhenUrlNotFound {
    // setup
    NSString *content = @"<a href=\"http://www.someurl.com/image.jpg\"><img src=\"http://www.someurl2.com/image2.jpg\"/>This image links to the image we want to match but we shouldn't match it since the URL is not in the img src</a>  <img src=\"http://www.someurl.com/image.jpg\"/>";

    // test
    MediaSettings *mediaSettings = [MediaSettings createMediaSettingsForUrl:@"http://www.someurlnotfound.com/image.jpg" content:content];
    //NSLog(@"MediaSettings: %@", mediaSettings);
    
    // asserts
    STAssertNotNil(mediaSettings, @"mediaSettings should not be nil");
    STAssertNil(mediaSettings.parsedHtml, @"parsedHtml will be nil since no matching HTML was found");
}

- (void)testParseSettingsUrlMatchInContentAndImage {
    // setup
    NSString *content = @"<a href=\"http://www.someurl.com/image.jpg\"><img src=\"http://www.someurl2.com/image2.jpg\"/>This image links to the image we want to match but we shouldn't match it since the URL is not in the img src</a>  <img src=\"http://www.someurl.com/image.jpg\"/>";
    NSString *parsedHtml = @"<img src=\"http://www.someurl.com/image.jpg\"/>";
    
    // test
    MediaSettings *mediaSettings = [MediaSettings createMediaSettingsForUrl:@"http://www.someurl.com/image.jpg" content:content];
    //NSLog(@"MediaSettings: %@", mediaSettings);
    
    // asserts
    STAssertEqualObjects(parsedHtml, mediaSettings.parsedHtml, @"parsedHtml");
}

- (void)testParseSettingsForMultipleImages {
    // setup
    NSString *content = @"<p   >Previous content</p  >\n\n<img src=\"http://www.someurl.com/image.jpg\"/>  and some post content <div>end</div><img src=\"http://www.someurl.com/image.jpg\"/> <img src=\"http://www.someurl2.com/image2.jpg\"   /> <img src=\"http://www.someurl.com/image.jpg\"/>";
    NSString *parsedHtml = @"<img src=\"http://www.someurl2.com/image2.jpg\"   />";
    
    // test
    MediaSettings *mediaSettings = [MediaSettings createMediaSettingsForUrl:@"http://www.someurl2.com/image2.jpg" content:content];
    //NSLog(@"MediaSettings: %@", mediaSettings);
    
    // asserts
    STAssertEqualObjects(parsedHtml, mediaSettings.parsedHtml, @"parsedHtml");
}

- (void)testParseSettingsForSingleImageWithoutLinkAndNoAttributes {
    // setup
    NSString *content = @"<p   >Previous content</p  >\n\n<img src=\"http://www.someurl.com/image.jpg\"/>  and some post content <div>end</div>";
    NSString *parsedHtml = @"<img src=\"http://www.someurl.com/image.jpg\"/>";
    
    // test
    MediaSettings *mediaSettings = [MediaSettings createMediaSettingsForUrl:@"http://www.someurl.com/image.jpg" content:content];
    //NSLog(@"MediaSettings: %@", mediaSettings);
    
    // asserts
    STAssertEqualObjects(parsedHtml, mediaSettings.parsedHtml, @"parsedHtml");
}

- (void)testParseSettingsForSingleImageWithoutLink {
    // setup
    NSString *content = @"<p   >Previous content</p  >\n\n<img src=\"http://www.someurl.com/image.jpg\" width=\"540\" height=\"405\" class=\"alignnone\" />  and some post content <div>end</div>";
    MediaSettings *expectedMediaSettings = [[MediaSettings alloc] init];
    NSString *parsedHtml = @"<img src=\"http://www.someurl.com/image.jpg\" width=\"540\" height=\"405\" class=\"alignnone\" />";
    expectedMediaSettings.alignment = @"alignnone";
    expectedMediaSettings.customHeight = [NSNumber numberWithInt:405];
    expectedMediaSettings.customWidth = [NSNumber numberWithInt:540];
    
    // test
    MediaSettings *mediaSettings = [MediaSettings createMediaSettingsForUrl:@"http://www.someurl.com/image.jpg" content:content];
    //NSLog(@"MediaSettings: %@", mediaSettings);
    
    // asserts
    STAssertEqualObjects(parsedHtml, mediaSettings.parsedHtml, @"parsedHtml");
    STAssertEqualObjects(expectedMediaSettings.alignment, mediaSettings.alignment, @"alignment");
    STAssertEqualObjects(expectedMediaSettings.customHeight, mediaSettings.customHeight, @"customHeight");
    STAssertEqualObjects(expectedMediaSettings.customWidth, mediaSettings.customWidth, @"customWidth");
}

- (void)testParseSettingsForSingleImageWithLink {
    // setup
    NSString *content = @"<p   >Previous content</p  >\n\n<a href=\"http://www.someurl.com/image.jpg\"><img src=\"http://www.someurl.com/image.jpg\" width=\"540\" height=\"405\" class=\"alignnone\" /></a> and some post content <div>end</div>";
    MediaSettings *expectedMediaSettings = [[MediaSettings alloc] init];
    NSString *parsedHtml = @"<a href=\"http://www.someurl.com/image.jpg\"><img src=\"http://www.someurl.com/image.jpg\" width=\"540\" height=\"405\" class=\"alignnone\" /></a>";
    expectedMediaSettings.alignment = @"alignnone";
    expectedMediaSettings.customHeight = [NSNumber numberWithInt:405];
    expectedMediaSettings.customWidth = [NSNumber numberWithInt:540];
    expectedMediaSettings.linkHref = @"http://www.someurl.com/image.jpg";
    
    // test
    MediaSettings *mediaSettings = [MediaSettings createMediaSettingsForUrl:@"http://www.someurl.com/image.jpg" content:content];
    //NSLog(@"MediaSettings: %@", mediaSettings);
    
    // asserts
    STAssertEqualObjects(parsedHtml, mediaSettings.parsedHtml, @"parsedHtml");
    STAssertEqualObjects(expectedMediaSettings.alignment, mediaSettings.alignment, @"alignment");
    STAssertEqualObjects(expectedMediaSettings.customHeight, mediaSettings.customHeight, @"customHeight");
    STAssertEqualObjects(expectedMediaSettings.customWidth, mediaSettings.customWidth, @"customWidth");
    STAssertEqualObjects(expectedMediaSettings.linkHref, mediaSettings.linkHref, @"linkHref");
}

- (void)testParseSettingsForMultipleImageWithCaption {
    // setup
    NSString *content = @"<p   >Previous content</p  >\n\n[caption id=\"captionid2\" align=\"aligncenter\" width=\"302\"]<a class=\"linkcssclass1 class2\" title=\"linktitle1\" href=\"http://someurl.com/image2.jpg\" target=\"_blank\" rel=\"linkrel1\"><img class=\"otherclass secondclass\" style=\"border: 4px solid black; margin: 1px 2px;\" title=\"asdf\" alt=\"\" src=\"http://www.someurl.com/image2.jpg\" width=\"302\" height=\"227\" /></a> asdfsdf[/caption] and some post content <div>end</div>  [caption id=\"caption_id1\" align=\"aligncenter\" width=\"302\"]<a class=\"linkcssclass1 class2\" title=\"linktitle1\" href=\"http://www.someurl.com/image1.jpg\" target=\"_blank\" rel=\"linkrel1\"><img class=\"otherclass secondclass\" style=\"border: 4px solid black; margin: 1px 2px;\" title=\"asdf\" alt=\"\" src=\"http://www.Someurl.com/image1.jpg\" width=\"302\" height=\"227\" /></a> asdfsdf[/caption]";
    MediaSettings *expectedMediaSettings = [[MediaSettings alloc] init];
    NSString *parsedHtml = @"[caption id=\"caption_id1\" align=\"aligncenter\" width=\"302\"]<a class=\"linkcssclass1 class2\" title=\"linktitle1\" href=\"http://www.someurl.com/image1.jpg\" target=\"_blank\" rel=\"linkrel1\"><img class=\"otherclass secondclass\" style=\"border: 4px solid black; margin: 1px 2px;\" title=\"asdf\" alt=\"\" src=\"http://www.Someurl.com/image1.jpg\" width=\"302\" height=\"227\" /></a> asdfsdf[/caption]";
    expectedMediaSettings.customHeight = [NSNumber numberWithInt:227];
    expectedMediaSettings.customWidth = [NSNumber numberWithInt:302];
    expectedMediaSettings.linkHref = @"http://www.someurl.com/image1.jpg";
    expectedMediaSettings.captionText = @" asdfsdf";
    expectedMediaSettings.alignment = @"aligncenter";
  
    // test
    MediaSettings *mediaSettings = [MediaSettings createMediaSettingsForUrl:@"http://www.someurl.com/image1.jpg" content:content];
    //NSLog(@"MediaSettings: %@", mediaSettings);
    
    // asserts
    STAssertEqualObjects(parsedHtml, mediaSettings.parsedHtml, @"parsedHtml");
    STAssertEqualObjects(expectedMediaSettings.alignment, mediaSettings.alignment, @"alignment");
    STAssertEqualObjects(expectedMediaSettings.customHeight, mediaSettings.customHeight, @"customHeight");
    STAssertEqualObjects(expectedMediaSettings.customWidth, mediaSettings.customWidth, @"customWidth");
    STAssertEqualObjects(expectedMediaSettings.linkHref, mediaSettings.linkHref, @"linkHref");
    STAssertEqualObjects(expectedMediaSettings.captionText, mediaSettings.captionText, @"captionText");
}

- (void)testParseSettingsForMultipleImageWithCaptionAndNoLink {
    // setup
    NSString *content = @"<p   >Previous content</p  >\n\n[caption id=\"captionid2\" align=\"aligncenter\" width=\"302\"]<a class=\"linkcssclass1 class2\" title=\"linktitle1\" href=\"http://someurl.com/image2.jpg\" target=\"_blank\" rel=\"linkrel1\"><img class=\"otherclass secondclass\" style=\"border: 4px solid black; margin: 1px 2px;\" title=\"asdf\" alt=\"\" src=\"http://www.someurl.com/image2.jpg\" width=\"302\" height=\"227\" /></a> asdfsdf[/caption] and some post content <div>end</div>  [caption id=\"caption_id1\" align=\"aligncenter\" width=\"302\"]<img class=\"otherclass secondclass\" style=\"border: 4px solid black; margin: 1px 2px;\" title=\"asdf\" alt=\"\" src=\"http://www.Someurl.com/image1.jpg\" width=\"302\" height=\"227\" />asdfsdf[/caption]";
    MediaSettings *expectedMediaSettings = [[MediaSettings alloc] init];
    NSString *parsedHtml = @"[caption id=\"caption_id1\" align=\"aligncenter\" width=\"302\"]<img class=\"otherclass secondclass\" style=\"border: 4px solid black; margin: 1px 2px;\" title=\"asdf\" alt=\"\" src=\"http://www.Someurl.com/image1.jpg\" width=\"302\" height=\"227\" />asdfsdf[/caption]";
    expectedMediaSettings.customHeight = [NSNumber numberWithInt:227];
    expectedMediaSettings.customWidth = [NSNumber numberWithInt:302];
    expectedMediaSettings.captionText = @"asdfsdf";
    expectedMediaSettings.alignment = @"aligncenter";
    
    // test
    MediaSettings *mediaSettings = [MediaSettings createMediaSettingsForUrl:@"http://www.someurl.com/image1.jpg" content:content];
    //NSLog(@"MediaSettings: %@", mediaSettings);
    
    // asserts
    STAssertEqualObjects(parsedHtml, mediaSettings.parsedHtml, @"parsedHtml");
    STAssertEqualObjects(expectedMediaSettings.customHeight, mediaSettings.customHeight, @"customHeight");
    STAssertEqualObjects(expectedMediaSettings.customWidth, mediaSettings.customWidth, @"customWidth");
    STAssertEqualObjects(expectedMediaSettings.captionText, mediaSettings.captionText, @"captionText");
    STAssertEqualObjects(expectedMediaSettings.alignment, mediaSettings.alignment, @"alignment");
}


- (void)testParseSettingsAndUpdateWithoutLosingAttributes {
    // setup
    NSString *content = @"<p   >Previous content</p  >\n\n[caption id=\"captionid2\" align=\"aligncenter\" width=\"302\"]<a class=\"linkcssclass1 class2\" title=\"linktitle1\" href=\"http://someurl.com/image2.jpg\" target=\"_blank\" rel=\"linkrel1\"><img class=\"otherclass secondclass\" style=\"border: 4px solid black; margin: 1px 2px;\" title=\"asdf\" alt=\"\" src=\"http://www.someurl.com/image2.jpg\" width=\"302\" height=\"227\" /></a> asdfsdf[/caption] and some post content <div>end</div>  [caption id=\"caption_id1\" align=\"aligncenter\" width=\"302\"]<img class=\"otherclass secondclass\" style=\"border: 4px solid black; margin: 1px 2px;\" title=\"asdf\" alt=\"\" src=\"http://www.Someurl.com/image1.jpg\" width=\"302\" height=\"227\" />asdfsdf[/caption]";
    NSString *expectedMediaHtml = @"[caption id=\"captionid2\" align=\"alignleft\" width=\"302\"]<a class=\"linkcssclass1 class2\" title=\"linktitle1\" href=\"http://someurl.com/image2.jpg\" target=\"_blank\" rel=\"linkrel1\"><img class=\"otherclass secondclass\" style=\"border: 4px solid black; margin: 1px 2px;\" title=\"asdf\" alt=\"\" src=\"http://www.someurl.com/image2.jpg\" width=\"302\" height=\"227\" /></a> asdfsdf[/caption]";
    MediaSettings *mediaSettings = [MediaSettings createMediaSettingsForUrl:@"http://www.someurl.com/image2.jpg" content:content];
    
    // test
    mediaSettings.alignment = @"alignleft";
    //NSLog(@"MediaSettings: %@", mediaSettings);
    
    // asserts
    STAssertEqualObjects(expectedMediaHtml, [mediaSettings html], @"html");
}

- (void)testUpdateWithAddingCaption {
    // setup
    NSString *content = @"<p>paragraph text</p><img src=\"http://www.someurl.com/image1.jpg\" />";
    NSString *expectedMediaHtml = @"[caption align=\"alignnone\"]<img src=\"http://www.someurl.com/image1.jpg\" />brand new caption text[/caption]";
    MediaSettings *mediaSettings = [MediaSettings createMediaSettingsForUrl:@"http://www.someurl.com/image1.jpg" content:content];
    
    // test
    mediaSettings.captionText = @"brand new caption text";
    //NSLog(@"MediaSettings: %@", mediaSettings);
    
    // asserts
    STAssertEqualObjects(expectedMediaHtml, [mediaSettings html], @"html");
}

- (void)testUpdateWithAddingCaptionAndAlignmentRemovedFromImage {
    // setup
    NSString *content = @"<p>paragraph text</p><img src=\"http://www.someurl.com/image1.jpg\" class=\"class1 alignleft  class2  \" />";
    NSString *expectedMediaHtml = @"[caption align=\"alignleft\"]<img src=\"http://www.someurl.com/image1.jpg\" class=\"class1 class2\" />brand new caption text[/caption]";
    MediaSettings *mediaSettings = [MediaSettings createMediaSettingsForUrl:@"http://www.someurl.com/image1.jpg" content:content];
    
    // test
    mediaSettings.captionText = @"brand new caption text";
    //NSLog(@"MediaSettings: %@", mediaSettings);
    
    // asserts
    STAssertEqualObjects(expectedMediaHtml, [mediaSettings html], @"html");
}

- (void)testUpdateWithRemovingCaptionAndAlignmentMovedToImage {
    // setup
    NSString *content = @"<p>paragraph text</p>[caption id=\"123\" align='   aligncenter  ']<img src=\"http://www.someurl.com/image1.jpg\" class=\"class1  class2  \" />existing caption[/caption]";
    NSString *expectedMediaHtml = @"<img src=\"http://www.someurl.com/image1.jpg\" class=\"class1 class2 aligncenter\" />";
    MediaSettings *mediaSettings = [MediaSettings createMediaSettingsForUrl:@"http://www.someurl.com/image1.jpg" content:content];
    
    // test
    mediaSettings.captionText = @"";
    //NSLog(@"MediaSettings: %@", mediaSettings);
    
    // asserts
    STAssertEqualObjects(expectedMediaHtml, [mediaSettings html], @"html");
}

- (void)testUpdateWithAddingLink {
    // setup
    NSString *content = @"<p>paragraph text</p>[caption id=\"123\" align='   aligncenter  ']<img src=\"http://www.someurl.com/image1.jpg\" class=\"class1  class2  \" />existing caption[/caption]";
    NSString *expectedMediaHtml = @"[caption id=\"123\" align=\"aligncenter\"]<a href=\"http://www.google.com\"><img src=\"http://www.someurl.com/image1.jpg\" class=\"class1 class2\" /></a>existing caption[/caption]";
    MediaSettings *mediaSettings = [MediaSettings createMediaSettingsForUrl:@"http://www.someurl.com/image1.jpg" content:content];
    
    // test
    mediaSettings.linkHref = @"http://www.google.com";
    //NSLog(@"MediaSettings: %@", mediaSettings);
    
    // asserts
    STAssertEqualObjects(expectedMediaHtml, [mediaSettings html], @"html");
}

- (void)testUpdateWithRemovingLink {
    // setup
    NSString *content = @"<p>paragraph text</p>[caption id=\"123\" align='   aligncenter  ']<a href=\"http://www.google.com\"><img src=\"http://www.someurl.com/image1.jpg\" class=\"class1  class2  \" /></a>existing caption[/caption]";
    NSString *expectedMediaHtml = @"[caption id=\"123\" align=\"aligncenter\"]<img src=\"http://www.someurl.com/image1.jpg\" class=\"class1 class2\" />existing caption[/caption]";
    MediaSettings *mediaSettings = [MediaSettings createMediaSettingsForUrl:@"http://www.someurl.com/image1.jpg" content:content];
    
    // test
    mediaSettings.linkHref = nil;
    //NSLog(@"MediaSettings: %@", mediaSettings);
    
    // asserts
    STAssertEqualObjects(expectedMediaHtml, [mediaSettings html], @"html");
}
@end
