#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "WPSearchControllerConfigurator.h"
#import "WPSearchController.h"
#import "PostListViewController.h"

@interface WPSearchControllerConfiguratorTests : XCTestCase

@property (nonatomic, strong) WPSearchControllerConfigurator *searchControllerConfigurator;
@property (nonatomic, strong) WPSearchController *searchController;
@property (nonatomic, strong) UIView *searchWrapperView;
@property (nonatomic, strong) id viewController;

@end

@implementation WPSearchControllerConfiguratorTests

- (void)setUp
{
    [super setUp];
    self.searchController = [[WPSearchController alloc] init];
    self.searchWrapperView = [[UIView alloc] init];
    self.viewController = OCMClassMock([UIViewController class]);
    
    self.searchControllerConfigurator = [[WPSearchControllerConfigurator alloc] initWithSearchController:self.searchController
                                                                                   withSearchWrapperView:self.searchWrapperView];
}

- (void)tearDown
{
    [super tearDown];

    self.searchControllerConfigurator = nil;
    self.searchController = nil;
    self.searchWrapperView = nil;
    self.viewController = nil;
}

- (void)testConfigureSearchControllerAndWrapperViewConfiguresSearchControllerProperties
{
    [self.searchControllerConfigurator configureSearchControllerAndWrapperView];
    XCTAssertFalse(self.searchController.dimsBackgroundDuringPresentation);
    XCTAssertTrue(self.searchController.hidesNavigationBarDuringPresentation);
}

- (void)testConfigureSearchControllerAndWrapperViewConfiguresSearchBarProperties
{
    [self.searchControllerConfigurator configureSearchControllerAndWrapperView];
    UISearchBar *searchBar = self.searchController.searchBar;
    
    XCTAssertFalse(searchBar.translatesAutoresizingMaskIntoConstraints);
    XCTAssertTrue([searchBar.accessibilityIdentifier isEqualToString:@"Search"]);
    XCTAssertEqual(UITextAutocapitalizationTypeNone, searchBar.autocapitalizationType);
    XCTAssertEqual(UIBarStyleBlack, searchBar.barStyle);
    XCTAssertTrue(searchBar.showsCancelButton);
}

@end
