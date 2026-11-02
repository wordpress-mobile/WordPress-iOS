#import <XCTest/XCTest.h>
#import "WPLogger.h"

@import CocoaLumberjack;
@import WordPressSharedObjC;

#pragma mark - Test doubles

@interface WPLoggingObjCTestsRecordingDelegate : NSObject <WordPressLoggingDelegate>
@property (nonatomic, strong) NSMutableArray<NSString *> *entries;
@end

@implementation WPLoggingObjCTestsRecordingDelegate

- (instancetype)init
{
    self = [super init];
    if (self) {
        _entries = [NSMutableArray array];
    }
    return self;
}

- (void)logError:(NSString *)str { [self.entries addObject:[@"error: " stringByAppendingString:str]]; }
- (void)logWarning:(NSString *)str { [self.entries addObject:[@"warning: " stringByAppendingString:str]]; }
- (void)logInfo:(NSString *)str { [self.entries addObject:[@"info: " stringByAppendingString:str]]; }
- (void)logDebug:(NSString *)str { [self.entries addObject:[@"debug: " stringByAppendingString:str]]; }
- (void)logVerbose:(NSString *)str { [self.entries addObject:[@"verbose: " stringByAppendingString:str]]; }

@end

/// Records the messages CocoaLumberjack hands to its loggers.
@interface WPLoggingObjCTestsRecordingLogger : DDAbstractLogger
@property (atomic, strong) NSArray<DDLogMessage *> *messages;
@end

@implementation WPLoggingObjCTestsRecordingLogger

- (instancetype)init
{
    self = [super init];
    if (self) {
        _messages = @[];
    }
    return self;
}

- (void)logMessage:(DDLogMessage *)logMessage
{
    @synchronized (self) {
        self.messages = [self.messages arrayByAddingObject:logMessage];
    }
}

@end

#pragma mark - Tests

/// Covers Objective-C logging through `WPLog*`, which replaced direct use of the
/// CocoaLumberjack `DDLog*` macros in the app's Objective-C code.
@interface WPLoggingObjCTests : XCTestCase
@property (nonatomic, strong, nullable) id<WordPressLoggingDelegate> originalDelegate;
@property (nonatomic, strong, nullable) WPLoggingObjCTestsRecordingLogger *recordingLogger;
@end

@implementation WPLoggingObjCTests

- (void)setUp
{
    [super setUp];
    self.originalDelegate = WPGetLoggingDelegate();
}

- (void)tearDown
{
    WPSetLoggingDelegate(self.originalDelegate);
    if (self.recordingLogger) {
        [DDLog removeLogger:self.recordingLogger];
        self.recordingLogger = nil;
    }
    // Restore the app's log level, which tests below change.
    [WPLogger configureLoggerLevelWithExtraDebug];
    [super tearDown];
}

#pragma mark Delivery to the logging delegate

- (void)testEachLevelCallsTheMatchingDelegateMethod
{
    WPLoggingObjCTestsRecordingDelegate *delegate = [WPLoggingObjCTestsRecordingDelegate new];
    WPSetLoggingDelegate(delegate);

    WPLogError(@"e");
    WPLogWarning(@"w");
    WPLogInfo(@"i");
    WPLogDebug(@"d");
    WPLogVerbose(@"v");

    NSArray *expected = @[@"error: e", @"warning: w", @"info: i", @"debug: d", @"verbose: v"];
    XCTAssertEqualObjects(delegate.entries, expected);
}

- (void)testFormatSpecifiersAreExpanded
{
    WPLoggingObjCTestsRecordingDelegate *delegate = [WPLoggingObjCTestsRecordingDelegate new];
    WPSetLoggingDelegate(delegate);

    NSError *error = [NSError errorWithDomain:@"TestDomain" code:42 userInfo:@{NSLocalizedDescriptionKey: @"Something failed"}];
    WPLogInfo(@"%@ %d %ld %lu %.2f %s %%", @"object", -1, (long)2, (unsigned long)3, 4.5, "cstring");
    WPLogError(@"%@", nil);
    WPLogError(@"Error: %@", error.localizedDescription);
    WPLogWarning(@"%@ %@", NSStringFromSelector(@selector(viewDidLoad)), @[@1]);

    NSArray *expected = @[
        @"info: object -1 2 3 4.50 cstring %",
        @"error: (null)",
        @"error: Error: Something failed",
        @"warning: viewDidLoad (\n    1\n)",
    ];
    XCTAssertEqualObjects(delegate.entries, expected);
}

- (void)testPercentInArgumentIsNotTreatedAsFormat
{
    WPLoggingObjCTestsRecordingDelegate *delegate = [WPLoggingObjCTestsRecordingDelegate new];
    WPSetLoggingDelegate(delegate);

    NSString *message = @"100% done %@ %d";
    WPLogError(@"%@", message);

    XCTAssertEqualObjects(delegate.entries, @[@"error: 100% done %@ %d"]);
}

#pragma mark Level filtering through CocoaLumberjack

- (void)testInfoLevelDropsDebugAndVerbose
{
    NSString *token = [self routeThroughLibraryLoggerAtLevel:DDLogLevelInfo];

    [self logEveryLevelWithToken:token];

    XCTAssertEqualObjects([self capturedFlagsForToken:token],
                          (@[@(DDLogFlagError), @(DDLogFlagWarning), @(DDLogFlagInfo)]));
}

- (void)testVerboseLevelKeepsEveryLevel
{
    NSString *token = [self routeThroughLibraryLoggerAtLevel:DDLogLevelVerbose];

    [self logEveryLevelWithToken:token];

    XCTAssertEqualObjects([self capturedFlagsForToken:token],
                          (@[@(DDLogFlagError), @(DDLogFlagWarning), @(DDLogFlagInfo), @(DDLogFlagDebug), @(DDLogFlagVerbose)]));
}

- (void)testMessageTextReachesCocoaLumberjackUnchanged
{
    NSString *token = [self routeThroughLibraryLoggerAtLevel:DDLogLevelInfo];

    WPLogInfo(@"%@ count=%d", token, 7);
    [DDLog flushLog];

    NSArray<DDLogMessage *> *messages = [self capturedMessagesForToken:token];
    XCTAssertEqual(messages.count, 1u);
    XCTAssertEqualObjects(messages.firstObject.message, ([NSString stringWithFormat:@"%@ count=7", token]));
}

#pragma mark Helpers

/// Uses the app's real logging delegate and a recording CocoaLumberjack logger.
/// Returns a unique token, so messages logged by the app at the same time can be ignored.
- (NSString *)routeThroughLibraryLoggerAtLevel:(DDLogLevel)level
{
    Class libraryLoggerClass = NSClassFromString(@"WordPress.WordPressLibraryLogger");
    XCTAssertNotNil(libraryLoggerClass);
    WPSetLoggingDelegate([libraryLoggerClass new]);

    self.recordingLogger = [WPLoggingObjCTestsRecordingLogger new];
    [DDLog addLogger:self.recordingLogger withLevel:DDLogLevelAll];
    [WordPressAppDelegate setLogLevel:level];

    return [NSString stringWithFormat:@"WPLoggingObjCTests-%@", [NSUUID UUID].UUIDString];
}

- (void)logEveryLevelWithToken:(NSString *)token
{
    WPLogError(@"%@ error", token);
    WPLogWarning(@"%@ warning", token);
    WPLogInfo(@"%@ info", token);
    WPLogDebug(@"%@ debug", token);
    WPLogVerbose(@"%@ verbose", token);
    [DDLog flushLog];
}

- (NSArray<DDLogMessage *> *)capturedMessagesForToken:(NSString *)token
{
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(DDLogMessage *message, NSDictionary *bindings) {
        return [message.message hasPrefix:token];
    }];
    return [self.recordingLogger.messages filteredArrayUsingPredicate:predicate];
}

- (NSArray<NSNumber *> *)capturedFlagsForToken:(NSString *)token
{
    NSMutableArray *flags = [NSMutableArray array];
    for (DDLogMessage *message in [self capturedMessagesForToken:token]) {
        [flags addObject:@(message.flag)];
    }
    return flags;
}

@end
