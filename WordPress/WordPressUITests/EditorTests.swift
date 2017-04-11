import XCTest

class EditorTests: XCTestCase {

    private var app: XCUIApplication!
    private var aztecEditorToggleValue: String!
    private var htmlContentTextView: XCUIElement!
    private var mainNavigationTabBar: XCUIElement!
    private var richContentTextView: XCUIElement!

    override func setUp() {
        super.setUp()

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()
        app = XCUIApplication()

        // Logout first if needed
        logoutIfNeeded()

        simpleLogin(username: WordPressTestCredentials.oneStepUser, password: WordPressTestCredentials.oneStepPassword)
        sleep(2)

        // Enable Aztec editor if needed
        mainNavigationTabBar = app.tabBars[ elementStringIDs.mainNavigationBar ]
        mainNavigationTabBar.buttons[ elementStringIDs.mainNavigationMeButton ].tap()
        app.tables.cells[ elementStringIDs.appSettingsButton ].tap()
        aztecEditorToggleValue = app.tables.cells[ elementStringIDs.aztecEditorToggle ].value as! String
        if ( aztecEditorToggleValue == "0" ) {
            app.tables.cells[ elementStringIDs.aztecEditorToggle ].tap()
        }

        // Start new post
        mainNavigationTabBar.buttons[ elementStringIDs.mainNavigationNewPostButton ].tap()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.

        // Exit editor
        app.navigationBars[ elementStringIDs.aztecPostView ].buttons[ elementStringIDs.editorCloseButton ].tap()
            app.sheets.buttons.element(boundBy: 1).tap()

        logoutIfNeeded()
        app.terminate()
        super.tearDown()
    }

    func testSimpleFormatBold() {
        typeAndSelectText(text: "text")

        app.scrollViews.otherElements.buttons[ elementStringIDs.boldButton ].tap()
        app.buttons[ elementStringIDs.sourcecodeButton ].tap()

        htmlContentTextView = app.textViews[ elementStringIDs.htmlTextField ]
        let text: String = htmlContentTextView.value as! String
        let expected = "<strong>text</strong>"
        XCTAssertEqual(expected, text)
    }

    func testSimpleFormatItalic() {
        typeAndSelectText(text: "text")

        app.scrollViews.otherElements.buttons[ elementStringIDs.italicButton ].tap()
        app.buttons[ elementStringIDs.sourcecodeButton ].tap()

        htmlContentTextView = app.textViews[ elementStringIDs.htmlTextField ]
        let text: String = htmlContentTextView.value as! String
        let expected = "<em>text</em>"
        XCTAssertEqual(expected, text)
    }

    func testSimpleFormatUnderline() {
        typeAndSelectText(text: "text")

        app.scrollViews.otherElements.buttons[ elementStringIDs.underlineButton ].tap()
        app.buttons[ elementStringIDs.sourcecodeButton ].tap()

        htmlContentTextView = app.textViews[ elementStringIDs.htmlTextField ]
        let text: String = htmlContentTextView.value as! String
        let expected = "<u>text</u>"
        XCTAssertEqual(expected, text)
    }

    func testSimpleFormatStrikethrough() {
        typeAndSelectText(text: "text")

        app.scrollViews.otherElements.buttons[ elementStringIDs.strikethroughButton ].tap()
        app.buttons[ elementStringIDs.sourcecodeButton ].tap()

        htmlContentTextView = app.textViews[ elementStringIDs.htmlTextField ]
        let text: String = htmlContentTextView.value as! String
        let expected = "<del>text</del>"
        XCTAssertEqual(expected, text)
    }

    func testSimpleFormatBlockquote() {
        typeAndSelectText(text: "text")

        app.scrollViews.otherElements.buttons[ elementStringIDs.blockquoteButton ].tap()
        app.buttons[ elementStringIDs.sourcecodeButton ].tap()
        htmlContentTextView = app.textViews[ elementStringIDs.htmlTextField ]

        let text: String = htmlContentTextView.value as! String
        let expected = "<blockquote>text</blockquote>"
        XCTAssertEqual(expected, text)
    }

    func testSimpleFormatUnorderedList() {
        typeAndSelectText(text: "text")

        app.scrollViews.otherElements.buttons[ elementStringIDs.unorderedlistButton ].tap()
        app.buttons[ elementStringIDs.sourcecodeButton ].tap()

        htmlContentTextView = app.textViews[ elementStringIDs.htmlTextField ]
        let text: String = htmlContentTextView.value as! String
        let expected = "<ul><li>text</li></ul>"
        XCTAssertEqual(expected, text)
    }

    func testSimpleFormatOrderedList() {
        typeAndSelectText(text: "text")

        app.scrollViews.otherElements.buttons[ elementStringIDs.orderedlistButton ].tap()
        app.buttons[ elementStringIDs.sourcecodeButton ].tap()

        htmlContentTextView = app.textViews[ elementStringIDs.htmlTextField ]
        let text: String = htmlContentTextView.value as! String
        let expected = "<ol><li>text</li></ol>"
        XCTAssertEqual(expected, text)
    }

    func testSimpleFormatLink() {
        typeAndSelectText(text: "text")

        // Prepare link to be auto-filled in URL field
        UIPasteboard.general.string = "https://wordpress.com/"

        app.scrollViews.otherElements.buttons[ elementStringIDs.linkButton ].tap()
        app.alerts.buttons.element(boundBy: 3).tap()
        app.buttons[ elementStringIDs.sourcecodeButton ].tap()

        htmlContentTextView = app.textViews[ elementStringIDs.htmlTextField ]
        let text: String = htmlContentTextView.value as! String
        let expected = "<a href=\"https://wordpress.com/\">text</a>"
        XCTAssertEqual(expected, text)
    }

    func testSimpleHorizontalRuler() {
        app.scrollViews.otherElements.buttons[ elementStringIDs.horizontalrulerButton ].tap()
        app.buttons[ elementStringIDs.sourcecodeButton ].tap()

        htmlContentTextView = app.textViews[ elementStringIDs.htmlTextField ]
        let text: String = htmlContentTextView.value as! String
        let expected = "<hr>"
        XCTAssertEqual(expected, text)
    }

    func testSimpleMoreTag() {
        app.scrollViews.otherElements.buttons[ elementStringIDs.moreButton ].tap()
        app.buttons[ elementStringIDs.sourcecodeButton ].tap()

        htmlContentTextView = app.textViews[ elementStringIDs.htmlTextField ]
        let text: String = htmlContentTextView.value as! String
        let expected = "<!--more-->"
        XCTAssertEqual(expected, text)
    }

    func testSimpleFormatHeadingOne() {
        typeAndSelectText(text: "text")

        app.scrollViews.otherElements.buttons[ elementStringIDs.headerButton ].tap()
//        app.tables.staticTexts[ elementStringIDs.header1Button ].tap()
        app.tables.cells[ elementStringIDs.header1Button ].tap()
        app.buttons[ elementStringIDs.sourcecodeButton ].tap()

        htmlContentTextView = app.textViews[ elementStringIDs.htmlTextField ]
        let text: String = htmlContentTextView.value as! String
        let expected = "<h1>text</h1>"
        XCTAssertEqual(expected, text)
    }

    func testSimpleFormatHeadingTwo() {
        typeAndSelectText(text: "text")

        app.scrollViews.otherElements.buttons[ elementStringIDs.headerButton ].tap()
        app.tables.staticTexts[ elementStringIDs.header2Button ].tap()
        app.buttons[ elementStringIDs.sourcecodeButton ].tap()

        htmlContentTextView = app.textViews[ elementStringIDs.htmlTextField ]
        let text: String = htmlContentTextView.value as! String
        let expected = "<h2>text</h2>"
        XCTAssertEqual(expected, text)

    }

    func testSimpleFormatHeadingThree() {
        typeAndSelectText(text: "text")

        app.scrollViews.otherElements.buttons[ elementStringIDs.headerButton ].tap()
        app.tables.staticTexts[ elementStringIDs.header3Button ].tap()
        app.buttons[ elementStringIDs.sourcecodeButton ].tap()

        htmlContentTextView = app.textViews[ elementStringIDs.htmlTextField ]
        let text: String = htmlContentTextView.value as! String
        let expected = "<h3>text</h3>"
        XCTAssertEqual(expected, text)
    }

    func testSimpleFormatHeadingFour() {
        typeAndSelectText(text: "text")

        app.scrollViews.otherElements.buttons[ elementStringIDs.headerButton ].tap()
        app.tables.element(boundBy: 1).swipeUp()
        app.tables.staticTexts[ elementStringIDs.header4Button ].tap()
        app.buttons[ elementStringIDs.sourcecodeButton ].tap()

        htmlContentTextView = app.textViews[ elementStringIDs.htmlTextField ]
        let text: String = htmlContentTextView.value as! String
        let expected = "<h4>text</h4>"
        XCTAssertEqual(expected, text)
    }

    func testSimpleFormatHeadingFive() {
        typeAndSelectText(text: "text")

        app.scrollViews.otherElements.buttons[ elementStringIDs.headerButton ].tap()
        app.tables.element(boundBy: 1).swipeUp()
        app.tables.staticTexts[ elementStringIDs.header5Button ].tap()
        app.buttons[ elementStringIDs.sourcecodeButton ].tap()

        htmlContentTextView = app.textViews[ elementStringIDs.htmlTextField ]
        let text: String = htmlContentTextView.value as! String
        let expected = "<h5>text</h5>"
        XCTAssertEqual(expected, text)
    }

    func testSimpleFormatHeadingSix() {
        typeAndSelectText(text: "text")

        app.scrollViews.otherElements.buttons[ elementStringIDs.headerButton ].tap()
        app.tables.element(boundBy: 1).swipeUp()
        app.tables.staticTexts[ elementStringIDs.header6Button ].tap()
        app.buttons[ elementStringIDs.sourcecodeButton ].tap()

        htmlContentTextView = app.textViews[ elementStringIDs.htmlTextField ]
        let text: String = htmlContentTextView.value as! String
        let expected = "<h6>text</h6>"
        XCTAssertEqual(expected, text)
    }

}
