import Foundation
import Testing
import WordPressShared

struct DataHexStringTests {
    @Test func encodesBytesAsZeroPaddedLowercaseHex() {
        #expect(Data([0x00, 0x0f, 0xff, 0x10, 0xab]).hexString == "000fff10ab")
    }

    @Test func emptyDataProducesEmptyString() {
        #expect(Data().hexString == "")
    }

    @Test func singleByteIsZeroPadded() {
        #expect(Data([0x01]).hexString == "01")
        #expect(Data([0x0a]).hexString == "0a")
    }
}
