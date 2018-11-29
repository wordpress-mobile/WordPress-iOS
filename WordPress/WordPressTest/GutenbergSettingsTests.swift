import XCTest
@testable import WordPress

class GutenbergSettingsTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testGutenbergDisabledByDefaultAndToggleEnablesInSecondLaunch() {
        let testClosure: () -> () = { () in
            let database = EphemeralKeyValueDatabase()

            // This simulates the first launch
            let settings = GutenbergSettings(database: database)

            XCTAssertFalse(settings.isGutenbergEnabled())

            settings.toggleGutenberg()

            // This simulates a second launch
            let secondEditorSettings = GutenbergSettings(database: database)

            XCTAssertTrue(secondEditorSettings.isGutenbergEnabled())
        }

        BuildConfiguration.localDeveloper.test(testClosure)
        BuildConfiguration.a8cBranchTest.test(testClosure)
        BuildConfiguration.a8cPrereleaseTesting.test(testClosure)
        BuildConfiguration.appStore.test(testClosure)
    }
}
