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
@property (nonatomic, strong) id<WPSearchControllerWithResultsUpdatingDelegate> delegate;

@end

@implementation WPSearchControllerConfiguratorTests

- (void)setUp
{
    [super setUp];
    self.searchController = [[WPSearchController alloc] init];
    self.searchWrapperView = [[UIView alloc] init];
    
    self.searchControllerConfigurator = [[WPSearchControllerConfigurator alloc] initWithSearchController:self.searchController
                                                                                   withSearchWrapperView:self.searchWrapperView
                                                                                            withDelegate:self.delegate];
}

- (void)tearDown
{
    [super tearDown];

    self.searchControllerConfigurator = nil;
    self.searchController = nil;
    self.searchWrapperView = nil;
}

- (void)testConfigureSearchControllerBarAndWrapperViewConfiguresSearchControllerProperties
{
    [self.searchControllerConfigurator configureSearchControllerBarAndWrapperView];
    XCTAssertFalse(self.searchController.dimsBackgroundDuringPresentation);
    XCTAssertTrue(self.searchController.hidesNavigationBarDuringPresentation);
}

- (void)testConfigureSearchControllerBarAndWrapperViewConfiguresSearchBarProperties
{
    [self.searchControllerConfigurator configureSearchControllerBarAndWrapperView];
    UISearchBar *searchBar = self.searchController.searchBar;
    
    XCTAssertFalse(searchBar.translatesAutoresizingMaskIntoConstraints);
    XCTAssertTrue([searchBar.accessibilityIdentifier isEqualToString:@"Search"]);
    XCTAssertEqual(UITextAutocapitalizationTypeNone, searchBar.autocapitalizationType);
}

@end
