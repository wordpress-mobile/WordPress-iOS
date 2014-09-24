//
// Copyright (c) 2014 Mixpanel. All rights reserved.

#import "MPABTestDesignerConnection.h"
#import "MPABTestDesignerMessage.h"
#import "MPABTestDesignerSnapshotResponseMessage.h"
#import "MPABTestDesignerSnapshotRequestMessage.h"
#import "MPABTestDesignerChangeRequestMessage.h"
#import "MPABTestDesignerDeviceInfoRequestMessage.h"
#import "MPABTestDesignerTweakRequestMessage.h"
#import "MPABTestDesignerClearRequestMessage.h"
#import "MPABTestDesignerDisconnectMessage.h"

#ifdef MESSAGING_DEBUG
#define MessagingDebug(...) NSLog(__VA_ARGS__)
#else
#define MessagingDebug(...)
#endif

NSString * const kSessionVariantKey = @"session_variant";

@interface MPABTestDesignerConnection () <MPWebSocketDelegate>

@end

@implementation MPABTestDesignerConnection

{
    /* The difference between _open and _connected is that open
     is set when the socket is open, and _connected is set when
     we actually have started sending/receiving messages from
     the server. A connection can become _open/not _open in quick
     succession if the websocket proxy rejects the request, but
     we will only try and reconnect if we were actually _connected.
     */
    BOOL _open;
    BOOL _connected;
    NSURL *_url;
    NSMutableDictionary *_session;
    NSDictionary *_typeToMessageClassMap;
    MPWebSocket *_webSocket;
    NSOperationQueue *_commandQueue;
    UIView *_recordingView;
    void (^_connectCallback)();
    void (^_disconnectCallback)();
}

- (id)initWithURL:(NSURL *)url connectCallback:(void (^)())connectCallback disconnectCallback:(void (^)())disconnectCallback
{
    self = [super init];
    if (self) {
        _typeToMessageClassMap = @{
            MPABTestDesignerSnapshotRequestMessageType   : [MPABTestDesignerSnapshotRequestMessage class],
            MPABTestDesignerChangeRequestMessageType     : [MPABTestDesignerChangeRequestMessage class],
            MPABTestDesignerDeviceInfoRequestMessageType : [MPABTestDesignerDeviceInfoRequestMessage class],
            MPABTestDesignerTweakRequestMessageType      : [MPABTestDesignerTweakRequestMessage class],
            MPABTestDesignerClearRequestMessageType      : [MPABTestDesignerClearRequestMessage class],
            MPABTestDesignerDisconnectMessageType        : [MPABTestDesignerDisconnectMessage class],
        };

        _open = NO;
        _connected = NO;
        _sessionEnded = NO;
        _session = [[NSMutableDictionary alloc] init];
        _url = url;
        _connectCallback = connectCallback;
        _disconnectCallback = disconnectCallback;

        _commandQueue = [[NSOperationQueue alloc] init];
        _commandQueue.maxConcurrentOperationCount = 1;
        _commandQueue.suspended = YES;

        [self open];
    }

    return self;
}

- (id)initWithURL:(NSURL *)url
{
    return [self initWithURL:url connectCallback:nil disconnectCallback:nil];
}

- (void)open
{
    MessagingDebug(@"Attempting to open WebSocket to: %@", _url);
    _webSocket = [[MPWebSocket alloc] initWithURL:_url];
    _webSocket.delegate = self;
    [_webSocket open];
}

- (void)close
{
    [_webSocket close];
}

- (void)dealloc
{
    _webSocket.delegate = nil;
    [self close];
}

- (void)setSessionObject:(id)object forKey:(NSString *)key
{
    NSParameterAssert(key != nil);

    @synchronized (_session)
    {
        _session[key] = object ?: [NSNull null];
    }
}

- (id)sessionObjectForKey:(NSString *)key
{
    NSParameterAssert(key != nil);

    @synchronized (_session)
    {
        id object = _session[key];
        return [object isEqual:[NSNull null]] ? nil : object;
    }
}

- (void)sendMessage:(id<MPABTestDesignerMessage>)message
{
    MessagingDebug(@"Sending message: %@", [message debugDescription]);
    NSString *jsonString = [[NSString alloc] initWithData:[message JSONData] encoding:NSUTF8StringEncoding];
    [_webSocket send:jsonString];
}

- (id <MPABTestDesignerMessage>)designerMessageForMessage:(id)message
{
    MessagingDebug(@"raw message: %@", message);

    NSParameterAssert([message isKindOfClass:[NSString class]] || [message isKindOfClass:[NSData class]]);

    id <MPABTestDesignerMessage> designerMessage = nil;

    NSData *jsonData = [message isKindOfClass:[NSString class]] ? [(NSString *)message dataUsingEncoding:NSUTF8StringEncoding] : message;

    NSError *error = nil;
    id jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
    if ([jsonObject isKindOfClass:[NSDictionary class]]) {
        NSDictionary *messageDictionary = (NSDictionary *)jsonObject;
        NSString *type = messageDictionary[@"type"];
        NSDictionary *payload = messageDictionary[@"payload"];

        designerMessage = [_typeToMessageClassMap[type] messageWithType:type payload:payload];
    } else {
        MessagingDebug(@"Badly formed socket message expected JSON dictionary: %@", error);
    }

    return designerMessage;
}

#pragma mark - MPWebSocketDelegate Methods

- (void)webSocket:(MPWebSocket *)webSocket didReceiveMessage:(id)message
{
    if (!_connected) {
        _connected = YES;
        [self showConnectedView];
        if (_connectCallback) {
            _connectCallback();
        }
    }
    id<MPABTestDesignerMessage> designerMessage = [self designerMessageForMessage:message];
    MessagingDebug(@"WebSocket received message: %@", [designerMessage debugDescription]);

    NSOperation *commandOperation = [designerMessage responseCommandWithConnection:self];

    if (commandOperation) {
        [_commandQueue addOperation:commandOperation];
    }
}

- (void)webSocketDidOpen:(MPWebSocket *)webSocket
{
    _open = YES;
    MessagingDebug(@"WebSocket did open.");
    _commandQueue.suspended = NO;
}

- (void)webSocket:(MPWebSocket *)webSocket didFailWithError:(NSError *)error
{
    MessagingDebug(@"WebSocket did fail with error: %@", error);
    _commandQueue.suspended = YES;
    [_commandQueue cancelAllOperations];
    [self hideConnectedView];
    _open = NO;
    if (_connected) {
        _connected = NO;
        [self reconnect:YES];
        if (_disconnectCallback) {
            _disconnectCallback();
        }
    }
}

- (void)webSocket:(MPWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean
{
    MessagingDebug(@"WebSocket did close with code '%d' reason '%@'.", (int)code, reason);

    _commandQueue.suspended = YES;
    [_commandQueue cancelAllOperations];
    [self hideConnectedView];
    _open = NO;
    if (_connected) {
        _connected = NO;
        [self reconnect:YES];
        if (_disconnectCallback) {
            _disconnectCallback();
        }
    }
}

- (void)reconnect:(BOOL)initiate
{
    static int retries = 0;
    if (self.sessionEnded || _connected || retries >= 10) {
        // If we deliberately closed the connection, or are already connected
        // or we tried too many times, then stop retrying.
        retries = 0;
    } else if(initiate ^ (retries > 0)) {
        // If we are initiating a reconnect, or we are already in a
        // reconnect cycle (but not both). Then continue trying.
        MessagingDebug(@"Attempting to reconnect, attempt %d", retries);
        if (!_open) {
            [self open];
        }
        __weak MPABTestDesignerConnection *weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(MIN(pow(2, retries),10) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            MPABTestDesignerConnection *strongSelf = weakSelf;
            [strongSelf reconnect:NO];
        });
        retries++;
    }
}

- (void)showConnectedView
{
    if(!_recordingView) {
        UIWindow *mainWindow = [[UIApplication sharedApplication] delegate].window;
        _recordingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, mainWindow.frame.size.width, 1.0)];
        _recordingView.backgroundColor = [UIColor colorWithRed:4/255.0f green:180/255.0f blue:4/255.0f alpha:1.0];
        [mainWindow addSubview:_recordingView];
        [mainWindow bringSubviewToFront:_recordingView];
    }
}

- (void)hideConnectedView
{
    if (_recordingView) {
        [_recordingView removeFromSuperview];
    }
    _recordingView = nil;
}

@end

