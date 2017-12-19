import XCTest
@testable import WordPress

class EditorSettingsTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testAztecEnabledByDefaultButNotForcedAgain() {
        let testClosure: () -> () = { () in
            let database = EphemeralKeyValueDatabase()

            // This simulates the first launch
            let editorSettings = EditorSettings(database: database)

            XCTAssertTrue(editorSettings.isEnabled(.aztec))

            // This simulates a second launch
            let secondEditorSettings = EditorSettings(database: database)

            XCTAssertTrue(secondEditorSettings.isEnabled(.aztec))
        }

        BuildConfiguration.localDeveloper.test(testClosure)
        BuildConfiguration.a8cBranchTest.test(testClosure)
        BuildConfiguration.a8cPrereleaseTesting.test(testClosure)
        BuildConfiguration.appStore.test(testClosure)
    }
}
