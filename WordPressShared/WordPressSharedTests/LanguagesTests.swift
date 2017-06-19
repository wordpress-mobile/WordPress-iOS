import XCTest
@testable import WordPressShared



class LanguagesTests: XCTestCase {
    func testLanguagesEffectivelyLoadJsonFile() {
        let languages = WordPressComLanguageDatabase()

        XCTAssert(languages.all.count != 0)
        XCTAssert(languages.popular.count != 0)
    }

    func testAllLanguagesHaveValidFields() {
        let languages = WordPressComLanguageDatabase()
        let sum = languages.all + languages.popular

        for language in sum {
            XCTAssert(language.slug.characters.count > 0)
            XCTAssert(language.name.characters.count > 0)
        }
    }

    func testAllLanguagesContainPopularLanguages() {
        let languages = WordPressComLanguageDatabase()

        for language in languages.popular {
            let filtered = languages.all.filter { $0.id == language.id }
            XCTAssert(filtered.count == 1)
        }
    }

    func testNameForLanguageWithIdentifierReturnsTheRightName() {
        let languages = WordPressComLanguageDatabase()

        let english = languages.nameForLanguageWithId(en)
        let spanish = languages.nameForLanguageWithId(es)

        XCTAssert(english == "English")
        XCTAssert(spanish == "Español")
    }

    func testDeviceLanguageReturnsValueForSpanish() {
        let languages = WordPressComLanguageDatabase()
        languages._overrideDeviceLanguageCode("es")

        XCTAssertEqual(languages.deviceLanguage.id, es)
    }

    func testDeviceLanguageReturnsValueForSpanishSpainLowercase() {
        let languages = WordPressComLanguageDatabase()
        languages._overrideDeviceLanguageCode("es-es")

        XCTAssertEqual(languages.deviceLanguage.id, es)
    }

    func testDeviceLanguageReturnsValueForSpanishSpain() {
        let languages = WordPressComLanguageDatabase()
        languages._overrideDeviceLanguageCode("es-ES")

        XCTAssertEqual(languages.deviceLanguage.id, es)
    }

    func testDeviceLanguageReturnsEnglishForUnknownLanguage() {
        let languages = WordPressComLanguageDatabase()
        languages._overrideDeviceLanguageCode("not-a-language")

        XCTAssertEqual(languages.deviceLanguage.id, en)
    }

    func testDeviceLanguageReturnsValueForSpanishSpainExtra() {
        let languages = WordPressComLanguageDatabase()
        languages._overrideDeviceLanguageCode("es-ES-extra")

        XCTAssertEqual(languages.deviceLanguage.id, es)
    }

    func testDeviceLanguageReturnsValueForSpanishNO() {
        let languages = WordPressComLanguageDatabase()
        languages._overrideDeviceLanguageCode("es-NO")

        XCTAssertEqual(languages.deviceLanguage.id, es)
    }

    func testDeviceLanguageReturnsZhCNForZhHans() {
        let languages = WordPressComLanguageDatabase()
        languages._overrideDeviceLanguageCode("zh-Hans")

        XCTAssertEqual(languages.deviceLanguage.id, zhCN)
    }

    func testDeviceLanguageReturnsZhTWForZhHant() {
        let languages = WordPressComLanguageDatabase()
        languages._overrideDeviceLanguageCode("zh-Hant")

        XCTAssertEqual(languages.deviceLanguage.id, zhTW)
    }

    func testDeviceLanguageReturnsZhCNForZhHansES() {
        let languages = WordPressComLanguageDatabase()
        languages._overrideDeviceLanguageCode("zh-Hans-ES")

        XCTAssertEqual(languages.deviceLanguage.id, zhCN)
    }

    func testDeviceLanguageReturnsZhTWForZhHantES() {
        let languages = WordPressComLanguageDatabase()
        languages._overrideDeviceLanguageCode("zh-Hant-ES")

        XCTAssertEqual(languages.deviceLanguage.id, zhTW)
    }


    fileprivate let en = 1
    fileprivate let es = 19
    fileprivate let zhCN = 449
    fileprivate let zhTW = 452

}
