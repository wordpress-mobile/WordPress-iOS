import Testing
import WordPressShared

struct EmailTypoCheckerTests {

    @Test func testSuggestions() {
        #expect(EmailTypoChecker.guessCorrection(email: "hello@mop.com") == "hello@mop.com")
        #expect(EmailTypoChecker.guessCorrection(email: "hello@gmail.com") == "hello@gmail.com")
        #expect(EmailTypoChecker.guessCorrection(email: "hello") == "hello")
        #expect(EmailTypoChecker.guessCorrection(email: "hello@") == "hello@")
        #expect(EmailTypoChecker.guessCorrection(email: "@") == "@")
        #expect(EmailTypoChecker.guessCorrection(email: "").isEmpty)
        #expect(EmailTypoChecker.guessCorrection(email: "@hello") == "@hello")
        #expect(EmailTypoChecker.guessCorrection(email: "@hello.com") == "@hello.com")
        #expect(EmailTypoChecker.guessCorrection(email: "kikoo@gmail.com") == "kikoo@gmail.com")
        #expect(EmailTypoChecker.guessCorrection(email: "kikoo@azdoij.cm") == "kikoo@azdoij.cm")

        #expect(EmailTypoChecker.guessCorrection(email: "hello@gmial.com") == "hello@gmail.com")
        #expect(EmailTypoChecker.guessCorrection(email: "hello@gmai.com") == "hello@gmail.com")
        #expect(EmailTypoChecker.guessCorrection(email: "hello@yohoo.com") == "hello@yahoo.com")
        #expect(EmailTypoChecker.guessCorrection(email: "hello@yhoo.com") == "hello@yahoo.com")
        #expect(EmailTypoChecker.guessCorrection(email: "hello@ayhoo.com") == "hello@yahoo.com")
        #expect(EmailTypoChecker.guessCorrection(email: "hello@yhoo.com") == "hello@yahoo.com")
        #expect(EmailTypoChecker.guessCorrection(email: "hello@outloo.com") == "hello@outlook.com")
        #expect(EmailTypoChecker.guessCorrection(email: "hello@comcats.com") == "hello@comcast.com")
    }
}
