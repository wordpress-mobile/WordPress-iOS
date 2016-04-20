@protocol NSFetchedResultsControllerDelegate <NSObject>

@end

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "BlogListViewController.h"

@interface BlogListViewControllerTests : XCTestCase

@property (nonatomic, strong) BlogListViewController *blogListViewController;

@end

@implementation BlogListViewControllerTests

- (void)setUp
{
    [super setUp];
    self.blogListViewController = [[BlogListViewController alloc] init];
}

- (void)tearDown
{
    self.blogListViewController = nil;
    [super tearDown];
}

- (void)testSetEditingTrueDisablesSearchButton
{
    [self.blogListViewController setEditing:YES];
    XCTAssertFalse(self.blogListViewController.navigationItem.rightBarButtonItem.enabled);
}

- (void)testSetEditingFalseEnablesSearchButton
{
    [self.blogListViewController setEditing:NO];
    XCTAssertTrue(self.blogListViewController.navigationItem.rightBarButtonItem.enabled);
}
@end
