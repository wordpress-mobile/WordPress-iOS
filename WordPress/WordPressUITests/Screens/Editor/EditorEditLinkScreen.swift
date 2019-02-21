import Foundation
import XCTest

class EditorEditLinkScreen: BaseScreen {
    var linkModal: XCUIElement
    var urlTextField: XCUIElement
    var nameTextField: XCUIElement
    var cancelButton: XCUIElement
    var insertButton: XCUIElement
    var removeButton: XCUIElement

    init() {
        let app = XCUIApplication()
        linkModal = app.alerts["linkModal"]

        urlTextField = linkModal.collectionViews.textFields["linkModalURL"]
        nameTextField = linkModal.collectionViews.textFields["linkModalText"]
        cancelButton = linkModal.buttons["Cancel"]
        insertButton = linkModal.buttons["insertLinkButton"]
        removeButton = linkModal.buttons["Remove Link"]

        super.init(element: linkModal)
    }

    func updateURL(url: String) -> EditorEditLinkScreen {
        urlTextField.tap()
        urlTextField.replaceText(text: url)
        return self
    }

    func updateName(text: String) -> EditorEditLinkScreen {
        nameTextField.tap()
        nameTextField.replaceText(text: text)
        return self
    }

    func ok() -> EditorScreen {
        insertButton.tap()

        return EditorScreen(mode: .rich)
    }

    func cancel() -> EditorScreen {
        cancelButton.tap()

        return EditorScreen(mode: .rich)
    }

    func remove() -> EditorScreen {
        removeButton.tap()

        return EditorScreen(mode: .rich)
    }
}
