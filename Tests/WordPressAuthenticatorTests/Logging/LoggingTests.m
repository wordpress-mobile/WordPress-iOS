#import <XCTest/XCTest.h>

@import WordPressAuthenticator;
@import WordPressSharedObjC;

@interface CaptureLogs : NSObject<WordPressLoggingDelegate>

@property (nonatomic, strong) NSMutableArray *infoLogs;
@property (nonatomic, strong) NSMutableArray *errorLogs;

@end

// We are leaving some protocol methods intentionally unimplemented to then test that calling them
// will not cause a crash.
//
// See https://github.com/wordpress-mobile/WordPressAuthenticator-iOS/pull/720#issuecomment-1374952619
#pragma clang diagnostic ignored "-Wprotocol"
@implementation CaptureLogs

- (instancetype)init
{
    if ((self = [super init])) {
        self.infoLogs = [NSMutableArray new];
        self.errorLogs = [NSMutableArray new];
    }
    return self;
}

- (void)logInfo:(NSString *)str
{
    [self.infoLogs addObject:str];
}

- (void)logError:(NSString *)str
{
    [self.errorLogs addObject:str];
}

@end
#pragma clang diagnostic pop

@interface ObjCLoggingTest : XCTestCase

@property (nonatomic, strong) CaptureLogs *logger;

@end

@implementation ObjCLoggingTest

- (void)setUp
{
    self.logger = [CaptureLogs new];
    WPSetLoggingDelegate(self.logger);
}

- (void)testLogging
{
    WPLogInfo(@"This is an info log");
    WPLogInfo(@"This is an info log %@", @"with an argument");
    XCTAssertEqualObjects(self.logger.infoLogs, (@[@"This is an info log", @"This is an info log with an argument"]));

    WPLogError(@"This is an error log");
    WPLogError(@"This is an error log %@", @"with an argument");
    XCTAssertEqualObjects(self.logger.errorLogs, (@[@"This is an error log", @"This is an error log with an argument"]));
}

- (void)testUnimplementedLoggingMethod
{
    XCTAssertNoThrow(WPLogVerbose(@"verbose logging is not implemented"));
}

- (void)testNoLogging
{
    WPSetLoggingDelegate(nil);
    XCTAssertNoThrow(WPLogInfo(@"this log should not be printed"));
    XCTAssertEqual(self.logger.infoLogs.count, 0);
}

@end
