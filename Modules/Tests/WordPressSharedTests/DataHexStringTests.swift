import Foundation
import Testing
import WordPressShared

struct DataHexStringTests {
    @Test func encodesBytesAsZeroPaddedLowercaseHex() {
        #expect(Data([0x00, 0x0f, 0xff, 0x10, 0xab]).hexString == "000fff10ab")
    }

    @Test func emptyDataProducesEmptyString() {
        #expect(Data().hexString.isEmpty)
    }

    @Test func singleByteIsZeroPadded() {
        #expect(Data([0x01]).hexString == "01")
        #expect(Data([0x0a]).hexString == "0a")
    }

    @Test func highBytesAreUnsignedNotSignExtended() {
        #expect(Data([0x80, 0x81, 0xfe, 0xff]).hexString == "8081feff")
        #expect(Data([0x80]).hexString.count == 2)
    }

    @Test func byteOrderIsPreserved() {
        #expect(Data([0x12, 0x34, 0x56, 0x78]).hexString == "12345678")
    }

    @Test func allByteValuesMatchIndependentNibbleReference() {
        let data = Data(0...255)
        let digits = Array("0123456789abcdef")
        let expected = String((0...255).flatMap { byte in
            [digits[Int(byte >> 4)], digits[Int(byte & 0x0f)]]
        })
        #expect(data.hexString == expected)
        #expect(data.hexString.count == 512)
    }

    @Test func hexStringRoundTripsBackToOriginalBytes() {
        let original = Data(0...255)
        let hex = original.hexString
        var decoded = Data()
        var index = hex.startIndex
        while index < hex.endIndex {
            let next = hex.index(index, offsetBy: 2)
            decoded.append(UInt8(hex[index..<next], radix: 16)!)
            index = next
        }
        #expect(decoded == original)
    }

    @Test func encodesUTF8ReferenceVector() {
        let data = Data("Hello, World!".utf8)
        #expect(data.hexString == "48656c6c6f2c20576f726c6421")
    }

    @Test func encodesDataSliceWithNonZeroStartIndex() {
        let base = Data([0xde, 0xad, 0xbe, 0xef])
        let slice = base[1..<3]
        #expect(slice.startIndex == 1)
        #expect(slice.hexString == "adbe")
    }
}
