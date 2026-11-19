import Testing
import UIKit
@testable import WordPress

@MainActor
@Suite("AppFeedbackPromptView")
struct AppFeedbackPromptViewTests {
    /// The width of the iPhone Duo's outer screen, and the strip on its right that holds the status bar and tab bar.
    private static let width: CGFloat = 466
    private static let sideStrip: CGFloat = 84

    @Test("buttons stay inside the safe area when they don't fit beside a side inset")
    func buttonsStayInsideTheSafeArea() throws {
        // Leave less room than the buttons need side by side, but more than they need stacked.
        let (window, prompt) = makePrompt(width: 360, trailingInset: Self.sideStrip)
        defer { window.isHidden = true }

        let (yes, no) = try buttons(in: prompt)
        let safeFrame = prompt.bounds.inset(by: prompt.safeAreaInsets)
        #expect(safeFrame.width < 360)
        #expect(safeFrame.contains(yes.frame(in: prompt)))
        #expect(safeFrame.contains(no.frame(in: prompt)))
        #expect(no.frame(in: prompt).minY >= yes.frame(in: prompt).maxY, "the buttons should be stacked")
    }

    @Test("layout settles when the prompt is wider than its safe area")
    func layoutSettles() throws {
        let (window, prompt) = makePrompt(width: 360, trailingInset: Self.sideStrip)
        defer { window.isHidden = true }

        let (yes, no) = try buttons(in: prompt)
        let frames = [yes.frame(in: prompt), no.frame(in: prompt)]

        for _ in 0..<3 {
            prompt.setNeedsLayout()
            window.layoutIfNeeded()
        }

        #expect([yes.frame(in: prompt), no.frame(in: prompt)] == frames)
    }

    @Test("buttons stay side by side when they fit")
    func buttonsSideBySideWhenTheyFit() throws {
        let (window, prompt) = makePrompt(width: Self.width, trailingInset: 0)
        defer { window.isHidden = true }

        let (yes, no) = try buttons(in: prompt)
        #expect(yes.frame(in: prompt).midY == no.frame(in: prompt).midY)
        #expect(no.frame(in: prompt).minX > yes.frame(in: prompt).maxX)
    }

    // MARK: - Helpers

    /// Pins the prompt to the full width of a window, like the Notifications table header, and sets it up as the
    /// push-notification prompt.
    private func makePrompt(width: CGFloat, trailingInset: CGFloat) -> (UIWindow, AppFeedbackPromptView) {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: width, height: 600))
        let viewController = UIViewController()
        viewController.additionalSafeAreaInsets.right = trailingInset
        window.rootViewController = viewController
        window.isHidden = false

        let prompt = AppFeedbackPromptView()
        viewController.view.addSubview(prompt)
        NSLayoutConstraint.activate([
            prompt.topAnchor.constraint(equalTo: viewController.view.topAnchor, constant: 100),
            prompt.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor),
            prompt.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor)
        ])
        window.layoutIfNeeded()

        prompt.setupHeading("We'll notify you when you get followers, comments, and likes.")
        prompt.setupYesButton(title: "Allow notifications") { _ in }
        prompt.setupNoButton(title: "Not now") { _ in }
        window.layoutIfNeeded()

        return (window, prompt)
    }

    private func buttons(in prompt: AppFeedbackPromptView) throws -> (yes: UIView, no: UIView) {
        let yes = try #require(prompt.subview(withIdentifier: "yes-button"))
        let no = try #require(prompt.subview(withIdentifier: "no-button"))
        return (yes, no)
    }
}

private extension UIView {
    func frame(in view: UIView) -> CGRect {
        convert(bounds, to: view)
    }

    func subview(withIdentifier identifier: String) -> UIView? {
        if accessibilityIdentifier == identifier {
            return self
        }
        return subviews.lazy.compactMap { $0.subview(withIdentifier: identifier) }.first
    }
}
