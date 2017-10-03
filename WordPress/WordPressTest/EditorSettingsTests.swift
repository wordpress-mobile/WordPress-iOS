import XCTest
@testable import WordPress

class EditorSettingsTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testNativeEditorEnabledAvailableButDisabledByDefault() {
        Build.withCurrent(.localDeveloper) {
            let editorSettings = EditorSettings(database: EphemeralKeyValueDatabase())

            XCTAssertFalse(editorSettings.nativeEditorEnabled)
        }
    }

    func testNativeEditorEnabledFromOverride() {
        Build.withCurrent(.appStore) {
            let editorSettings = EditorSettings(database: EphemeralKeyValueDatabase())
            editorSettings.nativeEditorEnabled = true

            XCTAssertTrue(editorSettings.nativeEditorEnabled)
        }
    }
}
