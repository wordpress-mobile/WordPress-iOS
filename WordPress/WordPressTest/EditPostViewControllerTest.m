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

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
    XCTAssertEqualObjects(_post.revision, _controller.post);

    [titleTextField typeText:@"Test1"];
    XCTAssertEqualObjects(titleTextField.text, @"Test1");
    XCTAssertEqualObjects(_post.revision.postTitle, @"Test1");

    _post.revision.postTitle = @"Test2";
    XCTAssertNoThrow([_controller performSelector:@selector(refreshUIForCurrentPost)]);
    XCTAssertEqualObjects(titleTextField.text, @"Test2");
}

#pragma mark - Notifications

- (void)controllerDidAutosave:(NSNotification *)notification {
    ATHNotify();
}

- (void)controllerAutosaveDidFail:(NSNotification *)notification {
    NSError *error = [[notification userInfo] objectForKey:@"error"];
    XCTFail(@"Autosave failed: %@", error);
    ATHNotify();
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
