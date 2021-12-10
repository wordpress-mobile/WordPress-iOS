import ScreenObject
import XCTest

public class AztecEditorScreen: ScreenObject {

    enum Mode {
        case rich
        case html

        func toggle() -> Mode {
            return self == .rich ? .html : .rich
        }
    }

    let mode: Mode
    private(set) var textView: XCUIElement

    private let richTextField = "aztec-rich-text-view"
    private let htmlTextField = "aztec-html-text-view"

    var mediaButton: XCUIElement { app.buttons["format_toolbar_insert_media"] }
    var sourcecodeButton: XCUIElement { app.buttons["format_toolbar_toggle_html_view"] }

    private let textViewGetter: (String) -> (XCUIApplication) -> XCUIElement = { identifier in
        return { app in
            var textView = app.textViews[identifier]

            if textView.exists == false {
                if app.otherElements[identifier].exists {
                    textView = app.otherElements[identifier]
                }
            }

            return textView
        }
    }

    init(mode: Mode, app: XCUIApplication = XCUIApplication()) throws {
        self.mode = mode
        let textField: String
        switch mode {
        case .rich:
            textField = richTextField
        case .html:
            textField = htmlTextField
        }

        textView = app.textViews[textField]

        try super.init(
            expectedElementGetters: [ textViewGetter(textField) ],
            app: app
        )

        showOptionsStrip()
    }

    func showOptionsStrip() {
        textView.coordinate(withNormalizedOffset: .zero).tap()
        expandOptionsStrip()
    }

    func expandOptionsStrip() {
        let expandButton = app.children(matching: .window).element(boundBy: 1).children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .button).element

        if expandButton.exists && expandButton.isHittable && !sourcecodeButton.exists {
            expandButton.tap()
        }
    }

    @discardableResult
    func addList(type: String) -> AztecEditorScreen {
        let listButton = app.buttons["format_toolbar_toggle_list_unordered"]
        tapToolbarButton(button: listButton)
        if type == "ul" {
            app.buttons["Unordered List"].tap()
        } else if type == "ol" {
            app.buttons["Ordered List"].tap()
        }

        return self
    }

    func addListWithLines(type: String, lines: Array<String>) -> AztecEditorScreen {
        addList(type: type)

        for (index, line) in lines.enumerated() {
            enterText(text: line)
            if index != (lines.count - 1) {
                app.buttons["Return"].tap()
            }
        }
        return self
    }

    /**
     Tapping on toolbar button. And swipes if needed.
     */
    @discardableResult
    func tapToolbarButton(button: XCUIElement) -> AztecEditorScreen {
        let linkButton = app.buttons["format_toolbar_insert_link"]
        let swipeElement = mediaButton.isHittable ? mediaButton : linkButton

        if !button.exists || !button.isHittable {
            swipeElement.swipeLeft()
        }
        Logger.log(message: "Tapping on Toolbar button: \(button)", event: .d)
        button.tap()

        return self
    }

    /**
     Tapping in to textView by specific coordinate. Its always tricky to know what cooridnates to click.
     Here is a list of "known" coordinates:
     30:32 - first word in 2d indented line (list)
     30:72 - first word in 3d intended line (blockquote)
     */
    func tapByCordinates(x: Int, y: Int) -> AztecEditorScreen {
        // textView frames on different devices:
        // iPhone X (0.0, 88.0, 375.0, 391.0)
        // iPhone SE (0.0, 64.0, 320.0, 504.0)
        let frame = textView.frame
        var vector = CGVector(dx: frame.minX + CGFloat(x), dy: frame.minY + CGFloat(y))
        if frame.minY == 88 {
            let yDiff = frame.minY - 64 // 64 - is minY for "normal" devices
            vector = CGVector(dx: frame.minX + CGFloat(x), dy: frame.minY - yDiff + CGFloat(y))
        }

        textView.coordinate(withNormalizedOffset: CGVector.zero).withOffset(vector).tap()
        sleep(1) // to make sure that "paste" manu wont show up.
        return self
    }

    /**
     Common method to type in different text fields
     */
    @discardableResult
    public func enterText(text: String) -> AztecEditorScreen {
        app.staticTexts["aztec-content-placeholder"].tap()
        textView.typeText(text)
        return self
    }

    /**
     Enters text into title field.
     - Parameter text: the test to enter into the title
     */
    public func enterTextInTitle(text: String) -> AztecEditorScreen {
        let titleView = app.textViews["Title"]
        titleView.tap()
        titleView.typeText(text)

        return self
    }

    @discardableResult
    func deleteText(chars: Int) -> AztecEditorScreen {
        for _ in 1...chars {
            app.keys["delete"].tap()
        }

        return self
    }

    func getViewContent() -> String {
        if  mode == .rich {
            return getTextContent()
        }

        return getHTMLContent()
    }

    /**
     Selects all entered text in provided textView element
     */
    func selectAllText() -> AztecEditorScreen {
        textView.coordinate(withNormalizedOffset: CGVector.zero).press(forDuration: 1)
        app.menuItems["Select All"].tap()

        return self
    }

    /*
     Select Image from Camera Roll by its ID. Starts with 0
     Simulator range: 0..4
     */
    func addImageByOrder(id: Int) throws -> AztecEditorScreen {
        tapToolbarButton(button: mediaButton)

        // Allow access to device media
        app.tap() // trigger the media permissions alert handler

        // Make sure media picker is open
        if mediaButton.exists {
            tapToolbarButton(button: mediaButton)
        }

        // Inject the first picture
        try MediaPickerAlbumScreen().selectImage(atIndex: 0)
        app.buttons["insert_media_button"].tap()

        // Wait for upload to finish
        let uploadProgressBar = app.progressIndicators["Progress"]
        XCTAssertEqual(
            uploadProgressBar.waitFor(predicateString: "exists == false", timeout: 10),
            .completed
        )

        return self
    }

    // returns void since return screen depends on from which screen it loaded
    public func closeEditor() {
        XCTContext.runActivity(named: "Close the Aztec editor") { (activity) in
            XCTContext.runActivity(named: "Close the More menu if needed") { (activity) in
                let actionSheet = app.sheets.element(boundBy: 0)
                if actionSheet.exists {
                    if XCUIDevice.isPad {
                        app.otherElements["PopoverDismissRegion"].tap()
                    } else {
                        app.sheets.buttons["Keep Editing"].tap()
                    }
                }
            }

            let editorCloseButton = app.navigationBars["Azctec Editor Navigation Bar"].buttons["Close"]

            editorCloseButton.tap()

            XCTContext.runActivity(named: "Discard any local changes") { (activity) in

                let postHasChangesSheet = app.sheets["post-has-changes-alert"]
                let discardButton = XCUIDevice.isPad ? postHasChangesSheet.buttons.lastMatch : postHasChangesSheet.buttons.element(boundBy: 1)

                if postHasChangesSheet.exists && (discardButton?.exists ?? false) {
                    Logger.log(message: "Discarding unsaved changes", event: .v)
                    discardButton?.tap()
                }
            }

            XCTAssertEqual(
                editorCloseButton.waitFor(predicateString: "isEnabled == false"),
                .completed,
                "Aztec editor should be closed but is still loaded."
            )
        }
    }

    public func publish() throws -> EditorNoticeComponent {
        app.buttons["Publish"].tap()

        try confirmPublish()

        return try EditorNoticeComponent(withNotice: "Post published", andAction: "View")
    }

    private func confirmPublish() throws {
        if FancyAlertComponent.isLoaded() {
            try FancyAlertComponent().acceptAlert()
        } else {
            app.buttons["Publish Now"].tap()
        }
    }

    public func openPostSettings() throws -> EditorPostSettings {
        app.buttons["more_post_options"].tap()

        app.sheets.buttons["Post Settings"].tap()

        return try EditorPostSettings()
    }

    private func getHTMLContent() -> String {
        let text = textView.value as! String

        // Remove spaces between HTML tags.
        let regex = try! NSRegularExpression(pattern: ">\\s+?<", options: .caseInsensitive)
        let range = NSMakeRange(0, text.count)
        let strippedText = regex.stringByReplacingMatches(in: text, options: .reportCompletion, range: range, withTemplate: "><")

        return strippedText
    }

    private func getTextContent() -> String {
        return textView.value as! String
    }

    static func isLoaded(mode: Mode = .rich) -> Bool {
        (try? AztecEditorScreen(mode: mode).isLoaded) ?? false
    }
}
