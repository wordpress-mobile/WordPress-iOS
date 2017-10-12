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
        BuildConfiguration.localDeveloper.test {
            let editorSettings = EditorSettings(database: EphemeralKeyValueDatabase())

            XCTAssertFalse(editorSettings.nativeEditorEnabled)
        }
    }

    func testNativeEditorEnabledFromOverride() {
        BuildConfiguration.appStore.test {
            let editorSettings = EditorSettings(database: EphemeralKeyValueDatabase())
            editorSettings.nativeEditorEnabled = true

            XCTAssertTrue(editorSettings.nativeEditorEnabled)
        }
    }
}
