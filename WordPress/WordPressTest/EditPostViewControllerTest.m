//
//  EditPostViewController.m
//  WordPress
//
//  Created by Jorge Bernal on 1/25/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <Nocilla/Nocilla.h>
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
    _blog = (Blog *)[[CoreDataTestHelper sharedHelper] insertEntityWithName:@"Blog"];
    _blog.xmlrpc = @"http://test.blog/xmlrpc.php";
    _blog.url = @"http://test.blog/";
    _post = [Post newDraftForBlog:_blog];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testPostIsCorrect {
    STAssertNotNil(_post, nil);
    STAssertEqualObjects(_post.status, @"publish", nil);
    STAssertEqualObjects(_blog, _post.blog, nil);
}

- (void)testViewController {
    STAssertNoThrow(_controller = [[EditPostViewController alloc] initWithPost:_post], nil);
    UIViewController *rvc = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
    STAssertNoThrow([rvc presentModalViewController:_controller animated:NO], nil);
    STAssertNotNil(_controller.view, nil);
    STAssertNotNil(_controller.view.superview, nil);
    NSArray *views = [[[[[_controller.view subviews] objectAtIndex:0] subviews] objectAtIndex:0] subviews];
    UITextField *titleTextField;
    for (UIView *view in views) {
        if ([view isKindOfClass:[UITextField class]] && [[view accessibilityIdentifier] isEqualToString:@"EditorTitleField"]) {
            titleTextField = (UITextField *)view;
        }
    }
    STAssertNotNil(titleTextField, nil);
    STAssertEqualObjects(titleTextField.accessibilityIdentifier, @"EditorTitleField", nil);
    STAssertEqualObjects(_post, _controller.apost, nil);

    [titleTextField typeText:@"Test1"];
    STAssertEqualObjects(titleTextField.text, @"Test1", nil);
    STAssertEqualObjects(_post.postTitle, @"Test1", nil);

    _post.postTitle = @"Test2";
    STAssertNoThrow([_controller performSelector:@selector(refreshUIForCurrentPost)], nil);
    STAssertEqualObjects(titleTextField.text, @"Test2", nil);

    STAssertNoThrow([_controller performSelector:@selector(switchToSettings)], nil);
    STAssertNoThrow([_controller performSelector:@selector(switchToPreview)], nil);
    STAssertNoThrow([_controller performSelector:@selector(switchToEdit)], nil);
}

@end
