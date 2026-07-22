import Testing
@testable import WordPressShared

@Suite("Languages Tests")
struct LanguagesTests {
    let en = 1
    let es = 19
    let zhCN = 449
    let zhTW = 452

    @Test func testLanguagesEffectivelyLoadJsonFile() {
        let languages = WordPressComLanguageDatabase.shared

        #expect(!languages.all.isEmpty)
        #expect(!languages.popular.isEmpty)
    }

    @Test func testAllLanguagesHaveValidFields() {
        let languages = WordPressComLanguageDatabase.shared
        let sum = languages.all + languages.popular

        for language in sum {
            #expect(!language.slug.isEmpty)
            #expect(!language.name.isEmpty)
        }
    }

    @Test func testAllLanguagesContainPopularLanguages() {
        let languages = WordPressComLanguageDatabase.shared

        for language in languages.popular {
            let filtered = languages.all.filter { $0.id == language.id }
            #expect(filtered.count == 1)
        }
    }

    @Test func testNameForLanguageWithIdentifierReturnsTheRightName() {
        let languages = WordPressComLanguageDatabase.shared

        let english = languages.nameForLanguageWithId(en)
        let spanish = languages.nameForLanguageWithId(es)

        #expect(english == "English")
        #expect(spanish == "Español")
    }

    @Test func testDeviceLanguageReturnsValueForSpanish() {
        let languages = WordPressComLanguageDatabase(deviceLanguageCode: "es")
        #expect(languages.deviceLanguage.id == es)
    }

    @Test func testDeviceLanguageReturnsValueForSpanishSpainLowercase() {
        let languages = WordPressComLanguageDatabase(deviceLanguageCode: "es-es")
        #expect(languages.deviceLanguage.id == es)
    }

    @Test func testDeviceLanguageReturnsValueForSpanishSpain() {
        let languages = WordPressComLanguageDatabase(deviceLanguageCode: "es-ES")
        #expect(languages.deviceLanguage.id == es)
    }

    @Test func testDeviceLanguageReturnsEnglishForUnknownLanguage() {
        let languages = WordPressComLanguageDatabase(deviceLanguageCode: "not-a-language")
        #expect(languages.deviceLanguage.id == en)
    }

    @Test func testDeviceLanguageReturnsValueForSpanishSpainExtra() {
        let languages = WordPressComLanguageDatabase(deviceLanguageCode: "es-ES-extra")
        #expect(languages.deviceLanguage.id == es)
    }

    @Test func testDeviceLanguageReturnsValueForSpanishNO() {
        let languages = WordPressComLanguageDatabase(deviceLanguageCode: "es-NO")
        #expect(languages.deviceLanguage.id == es)
    }

    @Test func testDeviceLanguageReturnsZhCNForZhHans() {
        let languages = WordPressComLanguageDatabase(deviceLanguageCode: "zh-Hans")
        #expect(languages.deviceLanguage.id == zhCN)
    }

    @Test func testDeviceLanguageReturnsZhTWForZhHant() {
        let languages = WordPressComLanguageDatabase(deviceLanguageCode: "zh-Hant")
        #expect(languages.deviceLanguage.id == zhTW)
    }

    @Test func testDeviceLanguageReturnsZhCNForZhHansES() {
        let languages = WordPressComLanguageDatabase(deviceLanguageCode: "zh-Hans-ES")
        #expect(languages.deviceLanguage.id == zhCN)
    }

    @Test func testDeviceLanguageReturnsZhTWForZhHantES() {
        let languages = WordPressComLanguageDatabase(deviceLanguageCode: "zh-Hant-ES")
        #expect(languages.deviceLanguage.id == zhTW)
    }
}
