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
        
        let english = languages.nameForLanguageWithId(en)
        let spanish = languages.nameForLanguageWithId(es)
        
        XCTAssert(english == "English")
        XCTAssert(spanish == "Español")
    }

    func testDeviceLanguageIdReturnsValueForSpanish() {
        let languages = Languages()
        languages._overrideDeviceLanguageCode("es")

        XCTAssertEqual(languages.deviceLanguageId(), es)
    }

    func testDeviceLanguageIdReturnsValueForSpanishSpainLowercase() {
        let languages = Languages()
        languages._overrideDeviceLanguageCode("es-es")

        XCTAssertEqual(languages.deviceLanguageId(), es)
    }

    func testDeviceLanguageIdReturnsValueForSpanishSpain() {
        let languages = Languages()
        languages._overrideDeviceLanguageCode("es-ES")

        XCTAssertEqual(languages.deviceLanguageId(), es)
    }

    func testDeviceLanguageIdReturnsEnglishForUnknownLanguage() {
        let languages = Languages()
        languages._overrideDeviceLanguageCode("not-a-language")

        XCTAssertEqual(languages.deviceLanguageId(), en)
    }

    func testDeviceLanguageIdReturnsValueForSpanishSpainExtra() {
        let languages = Languages()
        languages._overrideDeviceLanguageCode("es-ES-extra")

        XCTAssertEqual(languages.deviceLanguageId(), es)
    }

    func testDeviceLanguageIdReturnsValueForSpanishNO() {
        let languages = Languages()
        languages._overrideDeviceLanguageCode("es-NO")

        XCTAssertEqual(languages.deviceLanguageId(), es)
    }

    func testDeviceLanguageIdReturnsZhCNForZhHans() {
        let languages = Languages()
        languages._overrideDeviceLanguageCode("zh-Hans")

        XCTAssertEqual(languages.deviceLanguageId(), zhCN)
    }

    func testDeviceLanguageIdReturnsZhTWForZhHant() {
        let languages = Languages()
        languages._overrideDeviceLanguageCode("zh-Hant")

        XCTAssertEqual(languages.deviceLanguageId(), zhTW)
    }

    func testDeviceLanguageIdReturnsZhCNForZhHansES() {
        let languages = Languages()
        languages._overrideDeviceLanguageCode("zh-Hans-ES")

        XCTAssertEqual(languages.deviceLanguageId(), zhCN)
    }

    func testDeviceLanguageIdReturnsZhTWForZhHantES() {
        let languages = Languages()
        languages._overrideDeviceLanguageCode("zh-Hant-ES")

        XCTAssertEqual(languages.deviceLanguageId(), zhTW)
    }


    private let en = 1
    private let es = 19
    private let zhCN = 449
    private let zhTW = 452

}
