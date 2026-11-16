import Testing
import UIKit
@testable import WordPressUI

@MainActor
@Suite struct TableViewKeyboardObserverTests {
    private static let windowSize = CGSize(width: 390, height: 844)
    private static let keyboardHeight: CGFloat = 336

    private let window: UIWindow
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let observer = TableViewKeyboardObserver()

    /// The inset UIKit adds for the bottom safe area before the keyboard appears.
    private let safeAreaInset: CGFloat

    init() throws {
        let viewController = UIViewController()
        // Guarantees a bottom safe area on any simulator. The window can add the screen's own on top.
        viewController.additionalSafeAreaInsets.bottom = 34

        tableView.frame = viewController.view.bounds
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        viewController.view.addSubview(tableView)

        window = UIWindow(frame: CGRect(origin: .zero, size: Self.windowSize))
        window.rootViewController = viewController
        window.isHidden = false
        window.layoutIfNeeded()

        observer.tableView = tableView

        safeAreaInset = tableView.adjustedContentInset.bottom
        try #require(safeAreaInset >= 34 && safeAreaInset < Self.keyboardHeight)
    }

    @Test func contentEndsAtTheKeyboardTop() {
        postKeyboardWillShow(height: Self.keyboardHeight)

        // The keyboard covers the bottom safe area, so it must not be counted twice.
        #expect(tableView.adjustedContentInset.bottom == Self.keyboardHeight)
    }

    @Test func keyboardBelowTheTableViewAddsNoInset() {
        postKeyboardWillShow(height: Self.keyboardHeight, originY: Self.windowSize.height)

        #expect(tableView.contentInset.bottom == 0)
        #expect(tableView.adjustedContentInset.bottom == safeAreaInset)
    }

    @Test func keyboardInsideTheSafeAreaAddsNoInset() {
        postKeyboardWillShow(height: safeAreaInset - 10)

        #expect(tableView.contentInset.bottom == 0)
        #expect(tableView.adjustedContentInset.bottom == safeAreaInset)
    }

    @Test func hidingTheKeyboardRestoresTheInset() {
        postKeyboardWillShow(height: Self.keyboardHeight)
        NotificationCenter.default.post(name: UIResponder.keyboardWillHideNotification, object: nil)

        #expect(tableView.contentInset.bottom == 0)
        #expect(tableView.adjustedContentInset.bottom == safeAreaInset)
    }

    private func postKeyboardWillShow(height: CGFloat, originY: CGFloat? = nil) {
        let frame = CGRect(
            x: 0,
            y: originY ?? Self.windowSize.height - height,
            width: Self.windowSize.width,
            height: height
        )
        NotificationCenter.default.post(
            name: UIResponder.keyboardWillShowNotification,
            object: nil,
            userInfo: [UIResponder.keyboardFrameEndUserInfoKey: NSValue(cgRect: frame)]
        )
    }
}
