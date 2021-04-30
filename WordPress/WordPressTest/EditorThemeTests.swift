import XCTest
import Nimble
@testable import WordPress

class EditorThemeTests: XCTestCase {

    func testParseEquivalentObjects() throws {
        let testJSON: String = """
        [{"stylesheet":"twentytwentyone","template":"twentytwentyone","textdomain":"twentytwentyone","version":"1.2","theme_supports":{"editor-color-palette":[{"name":"Black","slug":"black","color":"#000000"}],"editor-gradient-presets":[{"name":"Purple to yellow","gradient":"linear-gradient(160deg, #D1D1E4 0%, #EEEADD 100%)","slug":"purple-to-yellow"}]}}]
        """

        /// The data is the same here but the keys are rearranged for dictionary objects. This is used to validate that the order won't effect the checksum.
        let testJSONModifiedKeyOrder: String = """
        [{"version":"1.2","stylesheet":"twentytwentyone","textdomain":"twentytwentyone","template":"twentytwentyone","theme_supports":{"editor-gradient-presets":[{"gradient":"linear-gradient(160deg, #D1D1E4 0%, #EEEADD 100%)","name":"Purple to yellow","slug":"purple-to-yellow"}],"editor-color-palette":[{"slug":"black","name":"Black","color":"#000000"}]}}]
        """

        let editorTheme1 = try JSONDecoder().decode([EditorTheme].self, from: testJSON.data(using: .utf8)!).first!
        let editorTheme2 = try JSONDecoder().decode([EditorTheme].self, from: testJSONModifiedKeyOrder.data(using: .utf8)!).first!
        expect(editorTheme1.checksum).to(equal(editorTheme2.checksum))
    }

    func testParseDifferentObjects() throws {
        let testJSON: String = """
        [{"stylesheet":"twentytwentyone","template":"twentytwentyone","textdomain":"twentytwentyone","version":"1.2","theme_supports":{"editor-color-palette":[{"name":"Black","slug":"black","color":"#000000"}],"editor-gradient-presets":[{"name":"Purple to yellow","gradient":"linear-gradient(160deg, #D1D1E4 0%, #EEEADD 100%)","slug":"purple-to-yellow"}]}}]
        """

        /// The data is almost the same here but has a small modification in hopes it will registes a change to the checksum
        let testJSONModifiedKeyOrder: String = """
        [{"version":"1.2","stylesheet":"twentytwentyone","textdomain":"twentytwentyone","template":"twentytwentyone","theme_supports":{"editor-gradient-presets":[{"gradient":"linear-gradient(160deg, #D1D1E4 0%, #EEEADD 100%)","name":"Purple to yellowish","slug":"purple-to-yellow"}],"editor-color-palette":[{"slug":"black","name":"Black","color":"#000000"}]}}]
        """

        let editorTheme1 = try JSONDecoder().decode([EditorTheme].self, from: testJSON.data(using: .utf8)!).first!
        let editorTheme2 = try JSONDecoder().decode([EditorTheme].self, from: testJSONModifiedKeyOrder.data(using: .utf8)!).first!
        expect(editorTheme1.checksum).toNot(equal(editorTheme2.checksum))
    }
}
