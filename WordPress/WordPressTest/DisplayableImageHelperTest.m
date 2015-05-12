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
    NSString *path = [DisplayableImageHelper searchPostAttachmentsForImageToDisplay:attachments];
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

@end
