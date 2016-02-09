import XCTest
@testable import WordPress

class LanguagesTests: XCTestCase
{
    func testLanguagesEffectivelyLoadJsonFile() {
        let languages = Languages()
        
        XCTAssert(languages.all.count != 0)
        XCTAssert(languages.popular.count != 0)
    }
    
    func testAllLanguagesHaveValidFields() {
        let languages = Languages()
        let sum = languages.all + languages.popular
        
        for language in sum {
            XCTAssert(language.slug.characters.count > 0)
            XCTAssert(language.name.characters.count > 0)
            XCTAssert(language.value != nil)
        }
    }
}
