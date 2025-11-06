import XCTest
import Testing
@testable import WordPressShared

@Suite("Languages Tests")
class LanguagesTests {
    let en = 1
    let es = 19
    let zhCN = 449
    let zhTW = 452

    @Test func testLanguagesEffectivelyLoadJsonFile() {
        let languages = WordPressComLanguageDatabase.shared

        XCTAssert(languages.all.count != 0)
        XCTAssert(languages.popular.count != 0)
    }

    @Test func testAllLanguagesHaveValidFields() {
        let languages = WordPressComLanguageDatabase.shared
        let sum = languages.all + languages.popular

        for language in sum {
            XCTAssert(language.slug.count > 0)
            XCTAssert(language.name.count > 0)
        }
    }

    @Test func testAllLanguagesContainPopularLanguages() {
        let languages = WordPressComLanguageDatabase.shared

        for language in languages.popular {
            let filtered = languages.all.filter { $0.id == language.id }
            XCTAssert(filtered.count == 1)
        }
    }

    @Test func testNameForLanguageWithIdentifierReturnsTheRightName() {
        let languages = WordPressComLanguageDatabase.shared

        let english = languages.nameForLanguageWithId(en)
        let spanish = languages.nameForLanguageWithId(es)

        XCTAssert(english == "English")
        XCTAssert(spanish == "Español")
    }

    @Test func testDeviceLanguageReturnsValueForSpanish() {
        let languages = WordPressComLanguageDatabase(deviceLanguageCode: "es")
        XCTAssertEqual(languages.deviceLanguage.id, es)
    }

    @Test func testDeviceLanguageReturnsValueForSpanishSpainLowercase() {
        let languages = WordPressComLanguageDatabase(deviceLanguageCode: "es-es")
        XCTAssertEqual(languages.deviceLanguage.id, es)
    }

    @Test func testDeviceLanguageReturnsValueForSpanishSpain() {
        let languages = WordPressComLanguageDatabase(deviceLanguageCode: "es-ES")
        XCTAssertEqual(languages.deviceLanguage.id, es)
    }

    @Test func testDeviceLanguageReturnsEnglishForUnknownLanguage() {
        let languages = WordPressComLanguageDatabase(deviceLanguageCode: "not-a-language")
        XCTAssertEqual(languages.deviceLanguage.id, en)
    }

    @Test func testDeviceLanguageReturnsValueForSpanishSpainExtra() {
        let languages = WordPressComLanguageDatabase(deviceLanguageCode: "es-ES-extra")
        XCTAssertEqual(languages.deviceLanguage.id, es)
    }

    @Test func testDeviceLanguageReturnsValueForSpanishNO() {
        let languages = WordPressComLanguageDatabase(deviceLanguageCode: "es-NO")
        XCTAssertEqual(languages.deviceLanguage.id, es)
    }

    @Test func testDeviceLanguageReturnsZhCNForZhHans() {
        let languages = WordPressComLanguageDatabase(deviceLanguageCode: "zh-Hans")
        XCTAssertEqual(languages.deviceLanguage.id, zhCN)
    }

    @Test func testDeviceLanguageReturnsZhTWForZhHant() {
        let languages = WordPressComLanguageDatabase(deviceLanguageCode: "zh-Hant")
        XCTAssertEqual(languages.deviceLanguage.id, zhTW)
    }

    @Test func testDeviceLanguageReturnsZhCNForZhHansES() {
        let languages = WordPressComLanguageDatabase(deviceLanguageCode: "zh-Hans-ES")
        XCTAssertEqual(languages.deviceLanguage.id, zhCN)
    }

    @Test func testDeviceLanguageReturnsZhTWForZhHantES() {
        let languages = WordPressComLanguageDatabase(deviceLanguageCode: "zh-Hant-ES")
        XCTAssertEqual(languages.deviceLanguage.id, zhTW)
    }
}
