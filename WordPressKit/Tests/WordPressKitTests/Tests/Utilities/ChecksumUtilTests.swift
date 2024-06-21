import XCTest
@testable import WordPressKit

class ChecksumUtilTests: XCTestCase {
    private let blockSettingsNOTThemeJSONResponseFilename = "wp-block-editor-v1-settings-success-NotThemeJSON"
    private let blockSettingsThemeJSONResponseFilename = "wp-block-editor-v1-settings-success-ThemeJSON"

    func testChecksumGeneration() {
        let firstObject = try! JSONDecoder().decode(RemoteBlockEditorSettings.self, from: mockedData(withFilename: blockSettingsNOTThemeJSONResponseFilename))
        let firstChecksum = ChecksumUtil.checksum(from: firstObject)
        XCTAssertFalse(firstChecksum.isEmpty)

        let secondObject = try! JSONDecoder().decode(RemoteBlockEditorSettings.self, from: mockedData(withFilename: blockSettingsThemeJSONResponseFilename))
        let secondChecksum = ChecksumUtil.checksum(from: secondObject)
        XCTAssertFalse(secondChecksum.isEmpty)

        XCTAssertNotEqual(firstChecksum, secondChecksum)
    }

    func mockedData(withFilename filename: String) -> Data {
        let json = Bundle(for: ChecksumUtilTests.self).url(forResource: filename, withExtension: "json")!
        return try! Data(contentsOf: json)
    }
}
