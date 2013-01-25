//
//  EditPostViewController.m
//  WordPress
//
//  Created by Jorge Bernal on 1/25/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "EditPostViewControllerTest.h"
#import "EditPostViewController_Internal.h"
#import "Post.h"

@implementation EditPostViewControllerTest {
    EditPostViewController *_controller;
    Blog *_blog;
    Post *_post;
    NSManagedObjectContext *_context;
}

- (void)setupCoreData {
    NSURL *modelURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"WordPress" ofType:@"momd"]];
    NSManagedObjectModel *mom = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    STAssertTrue([psc addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:NULL] ? YES : NO, @"Should be able to add in-memory store");
    _context = [[NSManagedObjectContext alloc] init];
    [_context setPersistentStoreCoordinator:psc];
}

- (void)setUp {
    [super setUp];
    [self setupCoreData];
    _blog = [NSEntityDescription insertNewObjectForEntityForName:@"Blog" inManagedObjectContext:_context];
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

    [titleTextField.delegate textFieldDidBeginEditing:titleTextField];
    [titleTextField.delegate textField:titleTextField shouldChangeCharactersInRange:NSMakeRange(0, 0) replacementString:@"Test1"];
    titleTextField.text = @"Test1";
    [titleTextField.delegate textFieldDidEndEditing:titleTextField];
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
