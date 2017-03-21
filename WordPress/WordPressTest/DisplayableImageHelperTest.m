#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "DisplayableImageHelper.h"

static NSString * const PathForAttachmentD = @"http://www.example.com/exampleD.png";

@interface DisplayableImageHelper()
+ (NSArray *)filteredAttachmentsArray:(NSArray *)attachments;
@end

@interface DisplayableImageHelperTest : XCTestCase
@end



@implementation DisplayableImageHelperTest

- (void)setUp {
    [super setUp];

}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (NSDictionary *)attachmentsDictionary
{
    NSDictionary *attachmentA = @{
                                  @"mime_type":@"video/mp4",
                                  @"width":@"1000",
                                  @"URL":@"http://www.example.com/exampleA.mp4"
                                  };
    NSDictionary *attachmentB = @{
                                  @"mime_type":@"image/png",
                                  @"width":@"10",
                                  @"URL":@"http://www.example.com/exampleB.png"
                                  };
    NSDictionary *attachmentC = @{
                                  @"mime_type":@"image/png",
                                  @"width":@"100",
                                  @"URL":@"http://www.example.com/exampleC.png"
                                  };
    NSDictionary *attachmentD = @{
                                  @"mime_type":@"image/png",
                                  @"width":@"1000",
                                  @"URL":PathForAttachmentD
                                  };

    return @{@"A":attachmentA,
             @"B":attachmentB,
             @"C":attachmentC,
             @"D":attachmentD};

}

- (void)testSearchPostAttachmentsForImageToDisplay
{
    NSDictionary *attachments = [self attachmentsDictionary];
    NSArray *arr = @[
                     [[attachments objectForKey:@"A"] objectForKey:@"URL"],
                     [[attachments objectForKey:@"B"] objectForKey:@"URL"],
                     [[attachments objectForKey:@"C"] objectForKey:@"URL"],
                     [[attachments objectForKey:@"D"] objectForKey:@"URL"],
                     ];

    NSString *content = [arr componentsJoinedByString:@" "];
    NSString *path = [DisplayableImageHelper searchPostAttachmentsForImageToDisplay:attachments existingInContent:content];
    XCTAssertTrue([path isEqualToString:PathForAttachmentD], @"Example D should be the matched attachment.");
}

- (void)testFilteredAttachmentsArray
{
    NSArray *attachments = [[self attachmentsDictionary] allValues];
    NSArray *filteredAttachments = [DisplayableImageHelper filteredAttachmentsArray:attachments];

    NSMutableArray *mAttachments = [attachments mutableCopy];
    [mAttachments removeObjectsInArray:filteredAttachments];

    XCTAssertTrue([mAttachments count] == 1, @"The video attachment should be missing from the filtered array");
}

- (void)testSearchPostContentForAttachmentIdsInGalleries
{
    NSSet *idsSet = [DisplayableImageHelper searchPostContentForAttachmentIdsInGalleries:@"Hello gallery [gallery ids=\"823,822,821\" type=\"rectangular\"] Another gallery [gallery ids=\"823,900\"]"];

    XCTAssertTrue([idsSet count] == 4, @"It should find four elements");
    XCTAssertTrue([idsSet containsObject:@(823)], "It should find 823");
    XCTAssertTrue([idsSet containsObject:@(900)], "It should find 900");
}

- (void)testSearchPostContentForImageToDisplay
{
    NSString *imageSrc= [DisplayableImageHelper searchPostContentForImageToDisplay:@"Img200 <img width=\"200\" src=\"http://photo.com/200.jpg\" /> Img300<img width=\"300\" src=\"http://photo.com/300.jpg\" /> Img100<img width=\"100\" src=\"http://photo.com/100.jpg\" />"];
    XCTAssertTrue([imageSrc isEqualToString:@"http://photo.com/300.jpg"], @"It should find the 300.jpg");

    imageSrc= [DisplayableImageHelper searchPostContentForImageToDisplay:@"Img200 <img width=\"200\" src=\"http://photo.com/200.jpg\" /> Img300<img src=\"http://photo.com/300.jpg\" /> Img100<img width=\"100\" src=\"http://photo.com/100.jpg\" />"];
    XCTAssertTrue([imageSrc isEqualToString:@"http://photo.com/200.jpg"], @"It should find the 200.jpg");

    imageSrc= [DisplayableImageHelper searchPostContentForImageToDisplay:@"Img200 <img src=\"http://photo.com/200.jpg\" /> Img300<img src=\"http://photo.com/300.jpg\" /> Img100<img src=\"http://photo.com/100.jpg\" />"];
    XCTAssertTrue([imageSrc length] == 0, @"It shouldn't find an image since none have a width");
}

@end
