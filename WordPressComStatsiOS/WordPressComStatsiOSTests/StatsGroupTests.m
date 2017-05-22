#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "StatsGroup.h"
#import <WordPressKit/StatsItem.h>

@interface StatsGroupTests : XCTestCase

@end

@implementation StatsGroupTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testCollapsedIsDefault
{
    StatsGroup *group = [StatsGroup new];
    XCTAssertFalse(group.isExpanded);
}

- (void)testNoItems
{
    StatsGroup *group = [StatsGroup new];
    
    XCTAssertEqual(0, group.numberOfRows);
}

- (void)testOneItemNoChildren
{
    StatsGroup *group = [StatsGroup new];
    StatsItem *item = [StatsItem new];
    group.items = @[item];
    
    XCTAssertEqual(1, group.numberOfRows);
    XCTAssertEqual(item, [group statsItemForTableViewRow:0]);
}

- (void)testTwoItemNoChildren
{
    StatsGroup *group = [StatsGroup new];
    StatsItem *item1 = [StatsItem new];
    StatsItem *item2 = [StatsItem new];
    group.items = @[item1, item2];
    
    XCTAssertEqual(2, group.numberOfRows);
    XCTAssertEqual(item1, [group statsItemForTableViewRow:0]);
    XCTAssertEqual(item2, [group statsItemForTableViewRow:1]);
}

- (void)testThreeLevelsOfItems
{
    StatsItem *item1 = [StatsItem new];
    StatsItem *subItem1 = [StatsItem new];
    StatsItem *subSubItem1 = [StatsItem new];
    StatsItem *subSubItem2 = [StatsItem new];
    StatsItem *subSubItem3 = [StatsItem new];
    StatsItem *subSubItem4 = [StatsItem new];
    StatsItem *item2 = [StatsItem new];
    StatsItem *item3 = [StatsItem new];
    StatsGroup *group = [StatsGroup new];
    group.items = @[item1, item2, item3];
    
    [item1 addChildStatsItem:subItem1];
    [subItem1 addChildStatsItem:subSubItem1];
    [subItem1 addChildStatsItem:subSubItem2];
    [subItem1 addChildStatsItem:subSubItem3];
    [subItem1 addChildStatsItem:subSubItem4];
    
    XCTAssertEqual(3, [group numberOfRows]);
    XCTAssertEqual(item1, [group statsItemForTableViewRow:0]);
    XCTAssertEqual(item2, [group statsItemForTableViewRow:1]);
    XCTAssertEqual(item3, [group statsItemForTableViewRow:2]);
    
    item1.expanded = YES;

    XCTAssertEqual(4, [group numberOfRows]);
    XCTAssertEqual(item1, [group statsItemForTableViewRow:0]);
    XCTAssertEqual(subItem1, [group statsItemForTableViewRow:1]);
    XCTAssertEqual(item2, [group statsItemForTableViewRow:2]);
    XCTAssertEqual(item3, [group statsItemForTableViewRow:3]);
    
    subItem1.expanded = YES;

    XCTAssertEqual(8, [group numberOfRows]);
    XCTAssertEqual(item1, [group statsItemForTableViewRow:0]);
    XCTAssertEqual(subItem1, [group statsItemForTableViewRow:1]);
    XCTAssertEqual(subSubItem1, [group statsItemForTableViewRow:2]);
    XCTAssertEqual(subSubItem2, [group statsItemForTableViewRow:3]);
    XCTAssertEqual(subSubItem3, [group statsItemForTableViewRow:4]);
    XCTAssertEqual(subSubItem4, [group statsItemForTableViewRow:5]);
    XCTAssertEqual(item2, [group statsItemForTableViewRow:6]);
    XCTAssertEqual(item3, [group statsItemForTableViewRow:7]);

}

@end
