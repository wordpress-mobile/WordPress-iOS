import XCTest
import Nimble

@testable import WordPress

class UUIDHelperTests: XCTestCase {
    func testExtractUUIDsFromAGivenString() {
        let stringWithUUID = " hi there885721b2-bb81-4673-9738-3f9673274b2f and another one c935de4f-ca62-4cf5-95fe-dd5d8093c7fd"
        
        let uuids = UUID.extract(from: stringWithUUID)
        
        expect(uuids).to(equal([UUID(uuidString: "885721b2-bb81-4673-9738-3f9673274b2f")!, UUID(uuidString: "c935de4f-ca62-4cf5-95fe-dd5d8093c7fd")!]))
    }
    
    func testReturnsAnEmptyArrayIfAGivenStringHasNoUUIDs() {
        let stringWithUUID = "lorem ipsum dolor sit"
        
        let uuids = UUID.extract(from: stringWithUUID)
        
        expect(uuids).to(beEmpty())
    }
}
