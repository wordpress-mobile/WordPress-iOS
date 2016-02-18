import XCTest
@testable import WordPress



class LanguagesTests: XCTestCase
{
    func testLanguagesEffectivelyLoadJsonFile() {
        let languages = Languages.sharedInstance
        
        XCTAssert(languages.all.count != 0)
        XCTAssert(languages.popular.count != 0)
    }
    
    func testAllLanguagesHaveValidFields() {
        let languages = Languages.sharedInstance
        let sum = languages.all + languages.popular
        
        for language in sum {
            XCTAssert(language.slug.characters.count > 0)
            XCTAssert(language.name.characters.count > 0)
        }
    }
    
    func testAllLanguagesContainPopularLanguages() {
        let languages = Languages.sharedInstance
        
        for language in languages.popular {
            let filtered = languages.all.filter { $0.languageId == language.languageId }
            XCTAssert(filtered.count == 1)
        }
    }
    
    func testNameForLanguageWithIdentifierReturnsTheRightName() {
        let languages = Languages.sharedInstance
        
        let english = languages.nameForLanguageWithId(1)
        let spanish = languages.nameForLanguageWithId(19)
        
        XCTAssert(english == "English")
        XCTAssert(spanish == "Español")
    }
}
