#import <XCTest/XCTest.h>
#import "ReaderTopicServiceRemote.h"
#import "ReaderPostServiceRemote.h"
#import "RemoteReaderPost.h"
#import "WPKit-Swift.h"


@interface ReaderPostServiceRemoteTests : XCTestCase
@end

@implementation ReaderPostServiceRemoteTests


#pragma mark - Configuration

- (NSDictionary *)metaDictionaryWithKey:(NSString *)key value:(id)value {
    NSDictionary *site = [NSDictionary dictionaryWithObject:value forKey:key];
    return @{
             @"meta": @{@"data": @{
                                @"site": site
                                }
                        }
             };
}

- (NSDictionary *)editorialDictionaryWithKey:(NSString *)key value:(id)value {
    NSDictionary *editorial = [NSDictionary dictionaryWithObject:value forKey:key];
    return @{@"editorial":editorial};
}

- (NSDictionary *)tagDictionaryWithName:(NSString *)name slug:(NSString *)slug postCount:(NSNumber *)postCount
{
    return @{
             @"name":name,
             @"slug":slug,
             @"post_count":postCount
             };
}

- (NSDictionary *)demoTagDictionary
{
    NSDictionary *tags = @{
                           @"fake":[self tagDictionaryWithName:@"Fake" slug:@"fake" postCount:@(1)],
                           @"primary":[self tagDictionaryWithName:@"Primary" slug:@"primary" postCount:@(10)],
                           @"secondary":[self tagDictionaryWithName:@"Secondary" slug:@"secondary" postCount:@(9)],
                           };
    return @{@"tags":tags};
}

- (NSDictionary *)demoTagsAndEditorialDictionary
{
    NSDictionary *editorial = @{
                                @"highlight_topic_title":@"Editorial",
                                @"highlight_topic":@"editorial"
                                };
    NSMutableDictionary *mdict = [[self demoTagDictionary] mutableCopy];
    [mdict setObject:editorial forKey:@"editorial"];

    return [mdict copy];
}

#pragma mark - Common

/**
 *  @brief      Common method for instantiating and initializing the service object.
 *  @details    This is only useful for cases that don't need to mock the API object.
 *
 *  @returns    The newly created service object.
 */
- (ReaderPostServiceRemote*)service
{
    WordPressComRestApi *api = [[WordPressComRestApi alloc] initWithOAuthToken:nil userAgent:nil];
    return [[ReaderPostServiceRemote alloc] initWithWordPressComRestApi:api];
}

#pragma mark - ReaderPostServiceRemote tests

- (void)testEndpointUrlForSearchPhrase
{
    ReaderPostServiceRemote *remoteService = nil;
    XCTAssertNoThrow(remoteService = [self service]);

    NSString *phrase = @"coffee";
    NSString *endpoint = [remoteService endpointUrlForSearchPhrase:phrase];
    XCTAssertTrue([endpoint hasSuffix:@"q=coffee"], @"The expected search term was not found");

    phrase = @"coffee talk";
    endpoint = [remoteService endpointUrlForSearchPhrase:phrase];
    XCTAssertTrue([endpoint hasSuffix:@"q=coffee%20talk"], @"The expected search term was not found");

    phrase = @"coffee-talk";
    endpoint = [remoteService endpointUrlForSearchPhrase:phrase];
    XCTAssertTrue([endpoint hasSuffix:@"q=coffee-talk"], @"The expected search term was not found");

    phrase = @"coffee & cake";
    endpoint = [remoteService endpointUrlForSearchPhrase:phrase];
    XCTAssertTrue([endpoint hasSuffix:@"q=coffee%20&%20cake"], @"The expected search term was not found");
}

@end
