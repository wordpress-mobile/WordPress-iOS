//
//  EditPostViewController.m
//  WordPress
//
//  Created by Jorge Bernal on 1/25/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <OHHTTPStubs/OHHTTPStubs.h>

#import "UIKitTestHelper.h"
#import "AsyncTestHelper.h"
#import "CoreDataTestHelper.h"
#import "EditPostViewControllerTest.h"
#import "EditPostViewController_Internal.h"
#import "Post.h"

@implementation EditPostViewControllerTest {
    EditPostViewController *_controller;
    Blog *_blog;
    Post *_post;
}

- (void)setUp {
    [super setUp];
    NSDictionary *blogDict = @{
                               @"blogid": @1,
                               @"url": @"http://test.blog/",
                               @"xmlrpc": @"http://test.blog/xmlrpc.php",
                               @"blogName": @"A test blog",
                               @"isAdmin": @YES,
                               @"username": @"test",
                               @"password": @"test"
                               };
    _blog = [Blog createFromDictionary:blogDict withContext:[[CoreDataTestHelper sharedHelper] managedObjectContext]];
    _post = [Post newDraftForBlog:_blog];
    STAssertNoThrow(_controller = [[EditPostViewController alloc] initWithPost:[_post createRevision]], nil);
    UIViewController *rvc = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
    STAssertNoThrow([rvc presentModalViewController:_controller animated:NO], nil);
    STAssertNotNil(_controller.view, nil);
    STAssertNotNil(_controller.view.superview, nil);
}

- (void)tearDown {
    [super tearDown];
    _blog = nil;
    _post = nil;
    [[CoreDataTestHelper sharedHelper] reset];
    UIViewController *rvc = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
    [rvc dismissModalViewControllerAnimated:NO];
    _controller = nil;
}

- (void)testPostIsCorrect {
    STAssertNotNil(_post, nil);
    STAssertEqualObjects(_post.status, @"publish", nil);
    STAssertEqualObjects(_blog, _post.blog, nil);
}

- (void)testViewController {
    UITextField *titleTextField = [self titleTextField];
    STAssertNotNil(titleTextField, nil);
    STAssertEqualObjects(titleTextField.accessibilityIdentifier, @"EditorTitleField", nil);
    STAssertEqualObjects(_post.revision, _controller.apost, nil);

    [titleTextField typeText:@"Test1"];
    STAssertEqualObjects(titleTextField.text, @"Test1", nil);
    STAssertEqualObjects(_post.revision.postTitle, @"Test1", nil);

    _post.revision.postTitle = @"Test2";
    STAssertNoThrow([_controller performSelector:@selector(refreshUIForCurrentPost)], nil);
    STAssertEqualObjects(titleTextField.text, @"Test2", nil);

    STAssertNoThrow([_controller performSelector:@selector(switchToSettings)], nil);
    STAssertNoThrow([_controller performSelector:@selector(switchToPreview)], nil);
    STAssertNoThrow([_controller performSelector:@selector(switchToEdit)], nil);
}

- (void)testAutosave {
    UITextField *titleTextField = [self titleTextField];

    [OHHTTPStubs shouldStubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return ([[request.URL absoluteString] isEqualToString:_blog.xmlrpc]);
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        NSString *body = [[NSString alloc] initWithData:[request HTTPBody] encoding:NSUTF8StringEncoding];
        if ([body rangeOfString:@"This is a very long title"].location != NSNotFound) {
            return [OHHTTPStubsResponse responseWithFile:@"xmlrpc-response-newpost.xml" contentType:@"text/xml" responseTime:OHHTTPStubsDownloadSpeedWifi];
        }
        if ([body rangeOfString:@"metaWeblog.getPost"].location != NSNotFound) {
            return [OHHTTPStubsResponse responseWithFile:@"xmlrpc-response-getpost.xml" contentType:@"text/xml" responseTime:OHHTTPStubsDownloadSpeedWifi];
        }
        return nil;
    }];

    ATHStart();
    [[NSNotificationCenter defaultCenter] addObserverForName:EditPostViewControllerDidAutosaveNotification object:_controller queue:nil usingBlock:^(NSNotification *note) {
        ATHNotify();
    }];
    [[NSNotificationCenter defaultCenter] addObserverForName:EditPostViewControllerAutosaveDidFailNotification object:_controller queue:nil usingBlock:^(NSNotification *note) {
        NSError *error = [[note userInfo] objectForKey:@"error"];
        STFail(@"Autosave failed: %@", error);
        ATHNotify();
    }];
    [titleTextField typeText:@"This is a very long title, which should trigger the autosave methods. Just in case... Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nunc est neque, adipiscing vitae euismod ut, elementum nec nibh. In hac habitasse platea dictumst. Mauris eu est lectus, sed elementum nunc. Praesent elit enim, facilisis eu tincidunt imperdiet, iaculis eu elit. In hac habitasse platea dictumst. Pellentesque feugiat elementum nulla, vitae pellentesque urna porttitor quis. Quisque et libero leo. Vestibulum ut erat ut ligula aliquet iaculis. Morbi egestas justo id nunc feugiat viverra vel sed risus. Nunc non ligula erat, eu ullamcorper purus. Nullam vitae erat velit, semper congue nibh. Vestibulum pulvinar mi a justo tincidunt venenatis in nec tortor. Curabitur tortor risus, consequat eget sollicitudin gravida, vestibulum vitae lacus. Aenean ut magna adipiscing mauris iaculis sollicitudin at id nisi."];
    ATHWait();
    STAssertEqualObjects(_post.postID, @123, nil);
    STAssertEqualObjects(_post.status, @"draft", nil);
}

#pragma mark - Helpers

- (UITextField *)titleTextField {
    NSArray *views = [[[[[_controller.view subviews] objectAtIndex:0] subviews] objectAtIndex:0] subviews];
    for (UIView *view in views) {
        if ([view isKindOfClass:[UITextField class]] && [[view accessibilityIdentifier] isEqualToString:@"EditorTitleField"]) {
            return (UITextField *)view;
        }
    }
    return nil;
}

@end
