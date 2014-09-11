import Foundation
import UIKit
import XCTest

class WPStatsGroupTest: XCTestCase {
    var statsGroup: WPStatsGroup?
    
    override func setUp() {
        super.setUp()

        let data = WPStatsGroup.groupsFromData(self.referrersArray())
        self.statsGroup = data[0] as? WPStatsGroup

    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testWPStatsGroupNotNil() {
        XCTAssertNotNil(self.statsGroup, "StatsGroup instance shouldn't be nil")
    }
    
    func testWPStatsTitleName() {
        XCTAssertTrue("Search Engines" == self.statsGroup!.title, "Should be Search Engines")
    }
    
    private func referrersArray() -> NSArray {
        
        var referrers: NSMutableArray = NSMutableArray()
        
        var results: NSArray =
        [
            ["http://www.google.co.in/search", 2],
            ["http://www.google.com/search", 2],
            ["http://www.google.co.kr", 2],
            ["http://www.google.nl/search", 2],
            ["http://www.google.ro/search", 1],
            ["http://www.google.co.in", 1],
            ["http://www.google.com.tw", 1],
            ["http://www.google.co.kr/search", 1],
            ["http://www.google.de", 1],
            ["http://www.google.es", 1],
            ["http://www.google.it/search", 1],
            ["http://www.google.com.tr", 1],
            ["http://www.google.co.th/search", 1]
        ]
        
        var searchEngines: NSDictionary =
            [
                "group": "Search Engines",
                "name": "Search Engines",
                "icon": "",
                "total": 17,
                "results": results
            ]
        referrers.addObject(searchEngines)
        
        var twitter: NSDictionary =
        [
            "group": "twitter.com",
            "name": "Twitter",
            "icon": "https://secure.gravatar.com/blavatar/7905d1c4e12c54933a44d19fcd5f9356",
            "total": 1,
            "results": [
                ["http://twitter.com/", 1]
            ]
        ]
        referrers.addObject(twitter)
        
        var kpresner: NSDictionary =
        [
            "group": "kpresner.com",
            "name": "kpresner.com",
            "icon": "",
            "total": 1,
            "results": [
                ["http://kpresner.com/2014/02/22/happiness-engineering/", 1]
            ]
        ]
        referrers.addObject(kpresner)
    
        return referrers
    }
}
