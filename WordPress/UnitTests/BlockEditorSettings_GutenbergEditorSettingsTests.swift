import Foundation
import XCTest

@testable import WordPress

class BlockEditorSettings_GutenbergEditorSettingsTests: CoreDataTestCase {

    func test_initWithRemoteEditorTheme_correctlyDetectsFSE() {
        let fseTheme = makeRemoteEditorTheme()
        let settings = BlockEditorSettings(editorTheme: fseTheme!, context: mainContext)

        XCTAssertNotNil(settings)
        XCTAssertTrue(settings!.isFSETheme)

        let nonFSETheme = makeRemoteEditorTheme(isFSETheme: false)
        let settings2 = BlockEditorSettings(editorTheme: nonFSETheme!, context: mainContext)

        XCTAssertNotNil(settings2)
        XCTAssertFalse(settings2!.isFSETheme)
    }

}

// MARK: - Helpers

private extension BlockEditorSettings_GutenbergEditorSettingsTests {
    func makeRemoteEditorTheme(isFSETheme: Bool = true) -> RemoteEditorTheme? {
        guard var themeJson = mockedThemesResponse(filename: "get_wp_v2_themes_twentytwenty"),
              var themeSupports = themeJson["theme_supports"] as? [String: AnyHashable] else {
            return nil
        }
        themeSupports["block-templates"] = isFSETheme
        themeJson["theme_supports"] = themeSupports

        guard let data = try? JSONSerialization.data(withJSONObject: themeJson) else {
            return nil
        }
        return try? JSONDecoder().decode(RemoteEditorTheme.self, from: data)
    }

    func mockedThemesResponse(filename: String) -> [String: AnyHashable]? {
        guard let json = Bundle(for: BlockEditorSettingsServiceTests.self).url(forResource: filename, withExtension: "json"),
              let data = try? Data(contentsOf: json),
              let response = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [[String: AnyHashable]] else {
            return nil
        }
        return response.first
    }
}
