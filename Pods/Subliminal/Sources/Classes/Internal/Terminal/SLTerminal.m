//
//  SLTerminal.m
//  Subliminal
//
//  For details and documentation:
//  http://github.com/inkling/Subliminal
//
//  Copyright 2013-2014 Inkling Systems, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "SLTerminal.h"


NSString *const SLTerminalJavaScriptException = @"SLTerminalJavaScriptException";

// do not change these values without updating `SLTerminal.js`
// and `Subliminal.tracetemplate`
static NSString *const SLTerminalPreferencesKeyScriptIndex      = @"scriptIndex";
static NSString *const SLTerminalPreferencesKeyScript           = @"script";
static NSString *const SLTerminalPreferencesKeyResultIndex      = @"resultIndex";
static NSString *const SLTerminalPreferencesKeyResult           = @"result";
static NSString *const SLTerminalPreferencesKeyException        = @"exception";

// variables are referred to by formatting @"%@.%@", self.scriptNamespace, <variableName>
// do not change these values without updating `SLTerminal.js`
// and `Subliminal.tracetemplate`
static NSString *const SLTerminalNamespace                      = @"SLTerminal";
static NSString *const SLTerminalScriptLoggingEnabledVariable   = @"scriptLoggingEnabled";
static NSString *const SLTerminalHasShutDownVariable            = @"hasShutDown";

const NSTimeInterval SLTerminalReadRetryDelay = 0.1;

// This is calibrated with respect to errors reported on Travis.
// It should be a comfortable margin--the actual discrepancy between
// Travis' execution times, and what we (had) thought would suffice,
// is closer to 0.14.
const NSTimeInterval SLTerminalEvaluationDelay = 0.2;

/**
 Identifier for the `evalQueue` for use with `dispatch_get_specific`.
 */
static const void *const kEvalQueueIdentifier = &kEvalQueueIdentifier;

@implementation SLTerminal {
    NSString *_scriptNamespace;
    dispatch_queue_t _evalQueue;
    NSUInteger _scriptIndex;
    BOOL _scriptLoggingEnabled;
}

+ (void)initialize {
    // initialize shared terminal, to prevent an SLTerminal
    // from being manually initialized prior to +sharedTerminal being invoked,
    // bypassing the assert at the top of -init
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    [SLTerminal sharedTerminal];
#pragma clang diagnostic pop
}

static SLTerminal *__sharedTerminal = nil;
+ (SLTerminal *)sharedTerminal {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __sharedTerminal = [[SLTerminal alloc] init];
    });
    return __sharedTerminal;
}

- (id)init {
    NSAssert(!__sharedTerminal, @"SLTerminal should not be initialized manually. Use +sharedTerminal instead.");
    
    self = [super init];
    if (self) {
        _scriptNamespace = SLTerminalNamespace;
        _evalQueue = dispatch_queue_create("com.inkling.subliminal.SLTerminal.evalQueue", DISPATCH_QUEUE_SERIAL);
        dispatch_queue_set_specific(_evalQueue, kEvalQueueIdentifier, (void *)kEvalQueueIdentifier, NULL);
    }
    return self;
}

- (void)dealloc {
    // On OS X 10.8, dispatch objects are NSObjects, and ARC renders it unnecessary
    // (and impossible) to manually release objects.
    // But on iOS, dispatch objects only become NSObjects in iOS 6,
    // and Subliminal still supports 5.1.
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
    dispatch_release(_evalQueue);
#endif
}

- (NSString *)scriptNamespace {
    return _scriptNamespace;
}

- (dispatch_queue_t)evalQueue {
    return _evalQueue;
}

- (BOOL)currentQueueIsEvalQueue
{
    return dispatch_get_specific(kEvalQueueIdentifier) != NULL;
}

#if TARGET_IPHONE_SIMULATOR
// in the simulator, UIAutomation uses a target-specific plist in ~/Library/Application Support/iPhone Simulator/[system version]/Library/Preferences/[bundle ID].plist
// _not_ the NSUserDefaults plist, in the sandboxed Library
// see http://stackoverflow.com/questions/4977673/reading-preferences-set-by-uiautomations-uiaapplication-setpreferencesvaluefork
- (NSString *)simulatorPreferencesPath {
    static NSString *path = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *plistRootPath = nil, *relativePlistPath = nil;
        NSString *plistName = [NSString stringWithFormat:@"%@.plist", [[NSBundle mainBundle] bundleIdentifier]];

        // 1. get into the simulator's app support directory by fetching the sandboxed Library's path
        NSString *userDirectoryPath = [(NSURL *)[[[NSFileManager defaultManager] URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] lastObject] path];
        // 2. get out of our application directory, back to the root support directory for this system version
        plistRootPath = [userDirectoryPath substringToIndex:([userDirectoryPath rangeOfString:@"Applications"].location)];

        // 3. locate, relative to here, /Library/Preferences/[bundle ID].plist
        relativePlistPath = [NSString stringWithFormat:@"Library/Preferences/%@", plistName];
        
        // 4. and unescape spaces, if necessary (i.e. in the simulator)
        NSString *unsanitizedPlistPath = [plistRootPath stringByAppendingPathComponent:relativePlistPath];
        path = [unsanitizedPlistPath stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    });
    return path;
}
#endif // TARGET_IPHONE_SIMULATOR


#pragma mark - Communication

/**
 Performs a round trip to `SLTerminal.js` by evaluating the script and returning the
 result of `eval()` or throwing an exception.

 `SLTerminal` and `SLTerminal.js` execute in lock-step order by waiting for each other
 to update their respective keys within the application's preferences. `SLTerminal.js`
 polls the "scriptIndex" key and waits for it to increment before evaluating the
 "script" key. `SLTerminal` waits for the result by polling for the existence of the
 "resultIndex" key. `SLTerminal` then checks the "result" and "exception" keys for
 the result of `eval()`.

 Preferences Keys
 ----------------

 Application
   "scriptIndex": SLTerminal.js waits for this number to increment
        "script": The input to eval()

 Script
    "resultIndex": The app waits for this number to appear
         "result": The output of eval(), may be empty
      "exception": The textual representation of a javascript exception, will be empty if no exceptions occurred.

 */
- (id)eval:(NSString *)script {
    NSParameterAssert(script);
    NSAssert(![NSThread isMainThread], @"-eval: must not be called from the main thread.");

    if (![self currentQueueIsEvalQueue]) {
        id __block result;
        NSException *__block evalException;
        dispatch_sync(self.evalQueue, ^{
            @try {
                result = [self eval:script];
            }
            @catch (NSException *exception) {
                evalException = exception;
            }
        });
        if (evalException) @throw evalException;
        return result;
    }

    // Step 1: Write the script to UIAutomation
#if TARGET_IPHONE_SIMULATOR
    NSMutableDictionary *prefs = [NSMutableDictionary dictionaryWithContentsOfFile:[self simulatorPreferencesPath]];
    if (!prefs) {
        prefs = [NSMutableDictionary dictionary];
    }
    [prefs setObject:@( _scriptIndex ) forKey:SLTerminalPreferencesKeyScriptIndex];
    [prefs setObject:script forKey:SLTerminalPreferencesKeyScript];
    [prefs removeObjectForKey:SLTerminalPreferencesKeyResultIndex];
    [prefs removeObjectForKey:SLTerminalPreferencesKeyResult];
    [prefs removeObjectForKey:SLTerminalPreferencesKeyException];
    [prefs writeToFile:[self simulatorPreferencesPath] atomically:YES];
#else
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@( _scriptIndex ) forKey:SLTerminalPreferencesKeyScriptIndex];
    [defaults setObject:script forKey:SLTerminalPreferencesKeyScript];
    [defaults removeObjectForKey:SLTerminalPreferencesKeyResultIndex];
    [defaults removeObjectForKey:SLTerminalPreferencesKeyResult];
    [defaults removeObjectForKey:SLTerminalPreferencesKeyException];
    [defaults synchronize];
#endif

    // Step 2: Wait for the result
    NSDictionary *resultPrefs = nil;
    while (1) {
#if TARGET_IPHONE_SIMULATOR
        resultPrefs = [NSDictionary dictionaryWithContentsOfFile:[self simulatorPreferencesPath]];
#else
        [defaults synchronize];
        resultPrefs = [defaults dictionaryRepresentation];
#endif

        if (resultPrefs[SLTerminalPreferencesKeyResultIndex]) {
            NSAssert([resultPrefs[SLTerminalPreferencesKeyResultIndex] intValue] == _scriptIndex, @"Result index is out of sync with script index");
            break;
        }
        [NSThread sleepForTimeInterval:SLTerminalReadRetryDelay];
    }
    _scriptIndex++;

    // Step 3: Rethrow the javascript exception or return the result
    NSString *exceptionMessage = resultPrefs[SLTerminalPreferencesKeyException];
    id result = resultPrefs[SLTerminalPreferencesKeyResult];

    if (exceptionMessage) {
        @throw [NSException exceptionWithName:SLTerminalJavaScriptException reason:exceptionMessage userInfo:nil];
    } else {
        return result;
    }
}

- (NSString *)evalWithFormat:(NSString *)script, ... {
    NSParameterAssert(script);

    va_list args;
    va_start(args, script);
    NSString *statement = [[NSString alloc] initWithFormat:script arguments:args];
    va_end(args);

    return [self eval:statement];
}

- (BOOL)scriptLoggingEnabled {
    return _scriptLoggingEnabled;
}

- (void)setScriptLoggingEnabled:(BOOL)scriptLoggingEnabled {
    if (scriptLoggingEnabled != _scriptLoggingEnabled) {
        [self enableScriptLogging:scriptLoggingEnabled];
        _scriptLoggingEnabled = scriptLoggingEnabled;
    }
}

- (void)enableScriptLogging:(BOOL)enableScriptLogging {
    if (![self currentQueueIsEvalQueue]) {
        // dispatch_async so that this can be called by the application
        // before testing has started
        dispatch_async(self.evalQueue, ^{
            [self enableScriptLogging:enableScriptLogging];
        });
        return;
    }
    [self evalWithFormat:@"%@.%@ = %@",
                            self.scriptNamespace, SLTerminalScriptLoggingEnabledVariable,
                            (enableScriptLogging ? @"true" : @"false")];
}

- (void)shutDown {
    [self evalWithFormat:@"%@.%@ = true;", self.scriptNamespace, SLTerminalHasShutDownVariable];
}

@end
