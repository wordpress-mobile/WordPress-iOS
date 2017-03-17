import XCTest
@testable import WordPress

class EditorSettingsTests: XCTestCase {
    override func setUp() {
        super.setUp()

        let userDefaults = UserDefaults.standard
        userDefaults.removeObject(forKey: "kUserDefaultsNativeEditorAvailable")
        userDefaults.removeObject(forKey: "kUserDefaultsNativeEditorEnabled")
        userDefaults.synchronize()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testNativeEditorAvailableIsAvailableBasedOnBuild() {
        Build._overrideCurrent = .debug
        let editorSettings = EditorSettings(database: EphemeralKeyValueDatabase())

        XCTAssertTrue(editorSettings.nativeEditorAvailable)
    }

    func testNativeEditorAvailableIsNotAvailableBasedOnBuild() {
        Build._overrideCurrent = .appStore
        let editorSettings = EditorSettings(database: EphemeralKeyValueDatabase())

        XCTAssertFalse(editorSettings.nativeEditorAvailable)
    }

    func testNativeEditorAvailableIsAvailableFromOverride() {
        Build._overrideCurrent = .appStore
        let editorSettings = EditorSettings(database: EphemeralKeyValueDatabase())
        editorSettings.nativeEditorAvailable = true


        XCTAssertTrue(editorSettings.nativeEditorAvailable)
    }

    func testNativeEditorEnabledAvailableButDisabledByDefault() {
        Build._overrideCurrent = .debug
        let editorSettings = EditorSettings(database: EphemeralKeyValueDatabase())

        XCTAssertTrue(editorSettings.nativeEditorAvailable)
        XCTAssertFalse(editorSettings.nativeEditorEnabled)
    }

    func testNativeEditorEnabledNotAvailable() {
        Build._overrideCurrent = .appStore
        let editorSettings = EditorSettings(database: EphemeralKeyValueDatabase())
        editorSettings.nativeEditorEnabled = true // Force to enabled but build should still disable

        XCTAssertFalse(editorSettings.nativeEditorEnabled)
    }

    func testNativeEditorEnabledIsAvailableAndEnabledFromOverride() {
        Build._overrideCurrent = .appStore
        let editorSettings = EditorSettings(database: EphemeralKeyValueDatabase())
        editorSettings.nativeEditorAvailable = true
        editorSettings.nativeEditorEnabled = true

        XCTAssertTrue(editorSettings.nativeEditorEnabled)
    }
}
