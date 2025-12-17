import Testing
import NaturalLanguage

@Suite("Word Counting")
struct TestHelperWordCountTests {

    @Test("English word counting")
    func englishWordCounting() {
        let text = "The quick brown fox jumps over the lazy dog"
        let count = TestHelpers.countWords(text, language: .english)
        #expect(count == 9)
    }

    @Test("Spanish word counting")
    func spanishWordCounting() {
        let text = "El rápido zorro marrón salta sobre el perro perezoso"
        let count = TestHelpers.countWords(text, language: .spanish)
        #expect(count == 9)
    }

    @Test("Japanese word counting")
    func japaneseWordCounting() {
        // "I like Japanese food very much" - 5 meaningful word units
        let text = "私は日本料理が大好きです"
        let count = TestHelpers.countWords(text, language: .japanese)

        // NLTokenizer properly segments Japanese into word units
        // Should recognize: 私/は/日本料理/が/大好き/です
        #expect(count >= 5 && count <= 7, "Expected 5-7 words, got \(count)")
    }

    @Test("Mandarin word counting")
    func mandarinWordCounting() {
        // "I like Chinese tea culture" - approximately 6-8 word units
        let text = "我喜欢中国茶文化"
        let count = TestHelpers.countWords(text, language: .simplifiedChinese)

        // NLTokenizer segments: 我/喜欢/中国/茶/文化
        #expect(count >= 4 && count <= 8, "Expected 4-8 words, got \(count)")
    }

    @Test("French word counting with punctuation")
    func frenchWordCountingWithPunctuation() {
        let text = "Bonjour! Comment allez-vous aujourd'hui?"
        let count = TestHelpers.countWords(text, language: .french)
        // "allez-vous" is correctly tokenized as 2 words (verb + pronoun)
        #expect(count == 5)
    }

    @Test("Empty text")
    func emptyText() {
        let count = TestHelpers.countWords("", language: .english)
        #expect(count == 0)
    }

    @Test("Single word")
    func singleWord() {
        let count = TestHelpers.countWords("Hello", language: .english)
        #expect(count == 1)
    }

    @Test("Text with extra whitespace")
    func textWithWhitespace() {
        let text = "  Hello    world   "
        let count = TestHelpers.countWords(text, language: .english)
        #expect(count == 2)
    }

    @Test("Mixed English and numbers")
    func mixedContent() {
        let text = "There are 3 apples and 5 oranges"
        let count = TestHelpers.countWords(text, language: .english)
        #expect(count == 7)
    }

    @Test("German word counting with compounds")
    func germanWordCounting() {
        let text = "Die deutsche Automobilindustrie ist sehr wichtig"
        let count = TestHelpers.countWords(text, language: .german)
        #expect(count == 6)
    }

    @Test("Russian word counting with Cyrillic")
    func russianWordCounting() {
        let text = "Русская литература очень богата и интересна"
        let count = TestHelpers.countWords(text, language: .russian)
        #expect(count == 6)
    }
}
