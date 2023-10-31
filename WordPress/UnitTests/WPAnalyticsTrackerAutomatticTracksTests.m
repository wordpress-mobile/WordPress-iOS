#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "WPAnalyticsTrackerAutomatticTracks.h"
@import AutomatticTracks;
#import <OCMock/OCMock.h>

@interface WPAnalyticsTrackerAutomatticTracksTests : XCTestCase

@property (nonatomic, strong) WPAnalyticsTrackerAutomatticTracks *subject;
@property (nonatomic, strong) id serviceMock;

@end

@interface WPAnalyticsTrackerAutomatticTracks (Testing)

@property (nonatomic, strong) TracksService *tracksService;
@property (nonatomic, strong) TracksContextManager *contextManager;

@end

@implementation WPAnalyticsTrackerAutomatticTracksTests

- (void)setUp {
    [super setUp];

    self.subject = [[WPAnalyticsTrackerAutomatticTracks alloc] init];
    self.serviceMock = OCMStrictClassMock([TracksService class]);
    self.subject.tracksService = self.serviceMock;
    self.subject.contextManager = nil;
}

- (void)tearDown {
    self.subject = nil;
    self.serviceMock = nil;
    [super tearDown];
}

- (void)testVerifyTracksNamesMappings {
    for (NSUInteger x = 0; x <= WPAnalyticsStatMaxValue; ++x) {
        OCMExpect(([self.serviceMock trackEventName:[OCMArg checkWithBlock:^BOOL(id obj) {
            TracksEvent *tracksEvent = [TracksEvent new];
            tracksEvent.uuid = [NSUUID UUID];
            tracksEvent.eventName = [NSString stringWithFormat:@"wpios_%@", obj];
            
            NSError *error;
            BOOL isValid = [tracksEvent validateObject:&error];
            
            if (!isValid) {
                NSLog(@"Error when validating TracksEvent: %@", error);
            }
            
            return isValid;
        }] withCustomProperties:[OCMArg any]]));
        

        [self.subject track:(WPAnalyticsStat)x];
    }
}

@end
