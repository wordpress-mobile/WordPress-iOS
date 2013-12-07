//
//  EditPostViewController.m
//  WordPress
//
//  Created by Jorge Bernal on 1/25/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <OHHTTPStubs/OHHTTPStubs.h>
#import <WPXMLRPC/WPXMLRPC.h>

#import "UIKitTestHelper.h"
#import "AsyncTestHelper.h"
#import "CoreDataTestHelper.h"
#import "EditPostViewControllerTest.h"
#import "EditPostViewController_Internal.h"
#import "Post.h"
#import "WPAccount.h"
#import "ContextManager.h"

@implementation EditPostViewControllerTest {
    EditPostViewController *_controller;
    WPAccount *_account;
    Blog *_blog;
    Post *_post;
    dispatch_semaphore_t postRevisionLock;
}

- (void)setUp {
    [super setUp];
    NSDictionary *blogDict = @{
                               @"blogid": @1,
                               @"url": @"http://test.blog/",
                               @"xmlrpc": @"http://test.blog/xmlrpc.php",
                               @"blogName": @"A test blog",
                               };

    _account = [WPAccount createOrUpdateSelfHostedAccountWithXmlrpc:blogDict[@"xmlrpc"] username:@"test" andPassword:@"test" withContext:[ContextManager sharedInstance].mainContext];
    _blog = [_account findOrCreateBlogFromDictionary:blogDict withContext:[_account managedObjectContext]];
    _post = [Post newDraftForBlog:_blog];
    
    XCTAssertNoThrow(_controller = [[EditPostViewController alloc] initWithPost:_post]);
    
    // Lock to wait for post revision creation
    postRevisionLock = dispatch_semaphore_create(0);
    [_post addObserver:self forKeyPath:@"revision" options:NSKeyValueObservingOptionNew context:NULL];
    
    // Kick off post revision creation
    [_controller viewDidLoad];
    
    // We need a non-ATHSemaphore here, as ATHNotify() from the app's Reader fetches cause
    // saves which cause the semaphore to be prematurely signalled
    // Wait for the post revision to be created
    long status = 0;
    NSDate *timeoutDate = [NSDate dateWithTimeIntervalSinceNow:AsyncTestCaseDefaultTimeout];
    while ((status = dispatch_semaphore_wait(postRevisionLock, DISPATCH_TIME_NOW)) &&
           [[NSDate date] compare:timeoutDate] == NSOrderedAscending) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
    if (status != 0) {
        XCTFail(@"Time out occurred waiting for post revision to be created");
    }
    
    UIViewController *rvc = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
    XCTAssertNoThrow([rvc presentViewController:_controller animated:NO completion:^{
        NSLog(@"subviews: %@", [rvc.view subviews]);
        XCTAssertNotNil(_controller.view);
        XCTAssertNotNil(_controller.view.superview);
    }]);
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (_post.revision) {
        dispatch_semaphore_signal(postRevisionLock);
    }
}

- (void)tearDown {
    [super tearDown];
    _blog = nil;
    _post = nil;
    [[CoreDataTestHelper sharedHelper] reset];
    UIViewController *rvc = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
    [rvc dismissViewControllerAnimated:NO completion:nil];
    _controller = nil;
}

- (void)testPostIsCorrect {
    XCTAssertNotNil(_post);
    XCTAssertEqualObjects(_post.status, @"publish");
    XCTAssertEqualObjects(_blog, _post.blog);
}

- (void)testViewController {
    UITextField *titleTextField = [self titleTextField];
    XCTAssertNotNil(titleTextField);
    XCTAssertEqualObjects(titleTextField.accessibilityIdentifier, @"EditorTitleField");
    XCTAssertEqualObjects(_post.revision, _controller.apost);

    [titleTextField typeText:@"Test1"];
    XCTAssertEqualObjects(titleTextField.text, @"Test1");
    XCTAssertEqualObjects(_post.revision.postTitle, @"Test1");

    _post.revision.postTitle = @"Test2";
    XCTAssertNoThrow([_controller performSelector:@selector(refreshUIForCurrentPost)]);
    XCTAssertEqualObjects(titleTextField.text, @"Test2");
}

- (void)testAutosave {
    return; // Disabled autosaves for now
    UITextField *titleTextField = [self titleTextField];

    [OHHTTPStubs shouldStubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return ([[request.URL absoluteString] isEqualToString:_blog.xmlrpc]);
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        WPXMLRPCDecoder *decoder = [[WPXMLRPCDecoder alloc] initWithData:[request HTTPBody]];
        NSDictionary *xmlrpcRequest = [decoder object];
        if (xmlrpcRequest) {
            NSString *methodName = [xmlrpcRequest objectForKey:@"methodName"];
            if ([methodName isEqualToString:@"metaWeblog.newPost"]) {
                return [OHHTTPStubsResponse responseWithFile:@"xmlrpc-response-newpost.xml" contentType:@"text/xml" responseTime:OHHTTPStubsDownloadSpeedWifi];
            } else if ([methodName isEqualToString:@"metaWeblog.getPost"]) {
                return [OHHTTPStubsResponse responseWithFile:@"xmlrpc-response-getpost.xml" contentType:@"text/xml" responseTime:OHHTTPStubsDownloadSpeedWifi];
            }
        }

        return nil;
    }];

    ATHStart();
    [[NSNotificationCenter defaultCenter] addObserverForName:EditPostViewControllerDidAutosaveNotification object:_controller queue:nil usingBlock:^(NSNotification *note) {
        ATHNotify();
    }];
    [[NSNotificationCenter defaultCenter] addObserverForName:EditPostViewControllerAutosaveDidFailNotification object:_controller queue:nil usingBlock:^(NSNotification *note) {
        NSError *error = [[note userInfo] objectForKey:@"error"];
        XCTFail(@"Autosave failed: %@", error);
        ATHNotify();
    }];
    [titleTextField typeText:@"This is a very long title, which should trigger the autosave methods. Just in case... Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nunc est neque, adipiscing vitae euismod ut, elementum nec nibh. In hac habitasse platea dictumst. Mauris eu est lectus, sed elementum nunc. Praesent elit enim, facilisis eu tincidunt imperdiet, iaculis eu elit. In hac habitasse platea dictumst. Pellentesque feugiat elementum nulla, vitae pellentesque urna porttitor quis. Quisque et libero leo. Vestibulum ut erat ut ligula aliquet iaculis. Morbi egestas justo id nunc feugiat viverra vel sed risus. Nunc non ligula erat, eu ullamcorper purus. Nullam vitae erat velit, semper congue nibh. Vestibulum pulvinar mi a justo tincidunt venenatis in nec tortor. Curabitur tortor risus, consequat eget sollicitudin gravida, vestibulum vitae lacus. Aenean ut magna adipiscing mauris iaculis sollicitudin at id nisi."];
    ATHEnd();
    XCTAssertEqualObjects(_post.postID, @123);
    XCTAssertEqualObjects(_post.status, @"draft");
}

#pragma mark - Helpers

- (UITextField *)titleTextField {
    // For iOS7
    NSArray *views = [_controller.view subviews];
    for (UIView *view in views) {
        if ([view isKindOfClass:[UITextField class]] && [[view accessibilityIdentifier] isEqualToString:@"EditorTitleField"]) {
            return (UITextField *)view;
        }
    }
    return nil;
}

@end
