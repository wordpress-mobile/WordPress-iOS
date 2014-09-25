#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "SuggestionService.h"

@interface SuggestionService ()

@property (nonatomic, strong) NSCache *suggestionsCache;

@end

@interface SuggestionServiceTest : XCTestCase

@end

@implementation SuggestionServiceTest

- (void)testSuggestionsForSiteIdUpdatesSuggestionsForTheFirstTime {
    NSNumber *siteID = @1;
    SuggestionService *service = [SuggestionService shared];
    id suggestionServiceMock = OCMPartialMock(service);
    id suggestionsCacheMock = OCMPartialMock(service.suggestionsCache);

    // replace updateSuggestionsForSiteID method
    OCMStub([suggestionServiceMock updateSuggestionsForSiteID:siteID]);

    NSArray *invalidArray = nil;
    OCMStub([suggestionsCacheMock objectForKey:siteID]).andReturn(invalidArray);

    [service suggestionsForSiteID:siteID];

    // verify that the method has been called
    OCMVerify([suggestionServiceMock updateSuggestionsForSiteID:siteID]);
}

- (void)testShouldShowSuggestionsPageForSiteIdReturnNoForEmptyList {
    NSNumber *siteID = @1;
    SuggestionService *service = [SuggestionService shared];
    id suggestionsCacheMock = OCMPartialMock(service.suggestionsCache);

    NSArray *emptyArray = @[];
    OCMStub([suggestionsCacheMock objectForKey:siteID]).andReturn(emptyArray);

    BOOL returnValue = [service shouldShowSuggestionsPageForSiteID:siteID];

    XCTAssertFalse(returnValue, @"Suggestions page shouldn't be shown if the suggestion list is empty");
}

@end
