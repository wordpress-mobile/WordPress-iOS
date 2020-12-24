#import "WPLogger.h"
#import "WordPress-Swift.h"

@import CocoaLumberjack;

@interface WPLogger ()
@property (nonatomic, strong, readwrite) DDFileLogger * _Nonnull fileLogger;
@end

@implementation WPLogger

#pragma mark - Initialization

+ (WPLogger *)shared {
    static WPLogger *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    return shared;
}

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        [self configureLogging];
    }
    
    return self;
}

#pragma mark - Configuration

- (void)configureLogging
{
    // Remove the old Documents/wordpress.log if it exists
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:@"wordpress.log"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if ([fileManager fileExistsAtPath:filePath]) {
        [fileManager removeItemAtPath:filePath error:nil];
    }
    
    // Sets up the CocoaLumberjack logging; debug output to console and file
#ifdef DEBUG
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
#endif
    [DDLog addLogger:self.fileLogger];

    [WPLogger configureLoggerLevelWithExtraDebug];
}

#pragma mark - Getters

- (DDFileLogger *)fileLogger
{
    if (!_fileLogger) {
        DDFileLogger *fileLogger = [[DDFileLogger alloc] init];
        fileLogger.rollingFrequency = 60 * 60 * 24; // 24 hour rolling
        fileLogger.logFileManager.maximumNumberOfLogFiles = 7;
        fileLogger.logFormatter = [[CustomLogFormatter alloc] init];

        _fileLogger = fileLogger;
    }
    
    return _fileLogger;
}

#pragma mark - Reading from the log

// get the log content with a maximum byte size
- (NSString *)getLogFilesContentWithMaxSize:(NSInteger)maxSize
{
    NSMutableString *description = [NSMutableString string];
    
    NSArray *sortedLogFileInfos = [[self.fileLogger logFileManager] sortedLogFileInfos];
    NSInteger count = [sortedLogFileInfos count];
    
    // we start from the last one
    for (NSInteger index = 0; index < count; index++) {
        DDLogFileInfo *logFileInfo = [sortedLogFileInfos objectAtIndex:index];
        
        NSData *logData = [[NSFileManager defaultManager] contentsAtPath:[logFileInfo filePath]];
        if ([logData length] > 0) {
            NSString *result = [[NSString alloc] initWithBytes:[logData bytes]
                                                        length:[logData length]
                                                      encoding: NSUTF8StringEncoding];
            
            [description appendString:result];
        }
    }
    
    if ([description length] > maxSize) {
        description = (NSMutableString *)[description substringWithRange:NSMakeRange(0, maxSize)];
    }
    
    return description;
}

#pragma mark - Public static methods

+ (void)configureLoggerLevelWithExtraDebug {
    BOOL extraDebug = [[NSUserDefaults standardUserDefaults] boolForKey:@"extra_debug"];
    if (extraDebug) {
        [WordPressAppDelegate setLogLevel:DDLogLevelVerbose];
    } else {
        [WordPressAppDelegate setLogLevel:DDLogLevelInfo];
    }
}

@end
