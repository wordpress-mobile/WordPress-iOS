import XCTest
@testable import WordPress

class TenorTests: XCTestCase {

    override func setUp() {

    }

    func testTonerResponseParsing() {
        let json = Bundle(for: TenorTests.self).url(forResource: "tenor", withExtension: "json")!
        let data = try! Data(contentsOf: json)
        guard let response = try? JSONDecoder().decode(TenorResponse.self, from: data) else {
            XCTFail("Toner response shuold be properly parsed")
            return
        }
        
        XCTAssertEqual(response.next, "5", "Next page start offset should be correct")
        XCTAssertEqual(response.results.count, 5, "Result count should be correct")
        
        let media = response.results.first!
    
        XCTAssertNotNil(media.gifs[.nanogif] , "Nano gif should exist")
        XCTAssertNotNil(media.gifs[.tinygif], "Tiny gif should exist")
        XCTAssertNotNil(media.gifs[.mediumgif], "Medium gif should exist")
        XCTAssertNotNil(media.gifs[.gif], "Normal gif should exist")
        
        let gif = media.gifs[.gif]!
        
        XCTAssertTrue(gif.dims[0] > 0 && gif.dims[1] > 0, "Gifs should have non-zero dimensions")
        XCTAssertNotNil(gif.url, "Gifs should have a url")
        XCTAssertNotNil(gif.preview, "Gifs should have a preview url")
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

}
