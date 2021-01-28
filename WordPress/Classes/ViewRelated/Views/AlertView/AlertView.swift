import Foundation
import WordPressShared.WPStyleGuide


/// The purpose of this class is to render a simple AlertView, with a custom style, and the following
/// sections: [ Title, Message, Button ]
///
open class AlertView: NSObject {
    // MARK: - Public Aliases
    public typealias Completion = (() -> ())


    /// Designated Initializer
    /// - Parameters:
    ///     - title: The title of the AlertView.
    ///     - message: Message string to be displayed. Note: Bold is supported, **markdown flavor**.
    ///     - completion: A closure to be executed right after the button is pressed.
    ///
    @objc public init(title: String, message: String, button: String, completion: Completion? = nil) {
        super.init()

        Bundle.main.loadNibNamed(AlertView.classNameWithoutNamespaces(), owner: self, options: nil)

        assert(internalView != nil)
        internalView.titleLabel.text = title

        let attributedMessage = NSMutableAttributedString(string: message, attributes: Style.detailsRegularAttributes)
        internalView.descriptionLabel.attributedText = removeBoldMarkers(applyBoldStyles(attributedMessage))
    }



    /// Displays the AlertView in the window.
    ///
    @objc open func show() {
        let targetView = keyView()

        // Attach the BackgroundView
        targetView.endEditing(true)
        targetView.addSubview(internalView)

        // We should cover everything
        internalView.translatesAutoresizingMaskIntoConstraints = false
        targetView.pinSubviewToAllEdges(internalView)

        // Animate!
        internalView.fadeInWithAnimation()

        // Note:
        // The internalView will retain the AlertView itself. After it's dismissed, everything will
        // be automatically cleaned up!
        internalView?.onClick = {
            self.dismiss()
        }
    }



    /// Finds the root view attached to the window
    /// - Returns: The Key View.
    ///
    fileprivate func keyView() -> UIView {
        return (UIApplication.shared.mainWindow?.subviews.first)!
    }



    /// Fades out the AlertView, and, on completion, will cleanup and hit the completion closure.
    ///
    fileprivate func dismiss() {
        UIView.animate(withDuration: WPAnimationDurationFast, animations: { () -> Void in
                self.internalView.alpha = WPAlphaZero
            },
            completion: { (success: Bool) -> Void in
                self.internalView.removeFromSuperview()
                self.onCompletion?()
            })
    }



    /// Apples Bold Style over all of the text surrounded by **double stars**.
    ///
    /// - Parameter message: The Message that should be stylized.
    ///
    /// - Returns: The Message with Bold Substrings styled.
    ///
    fileprivate func applyBoldStyles(_ message: NSMutableAttributedString) -> NSMutableAttributedString {
        let boldPattern = "(\\*{1,2}).+?\\1"
        message.applyStylesToMatchesWithPattern(boldPattern, styles: Style.detailsBoldAttributes)
        return message
    }



    /// Removes the Bold Markers from an Attributed String.
    ///
    /// - Parameter message: The Message that should be stylized.
    ///
    /// - Returns: The Message without the **bold** markers.
    ///
    fileprivate func removeBoldMarkers(_ message: NSMutableAttributedString) -> NSMutableAttributedString {
        let range = NSRange(location: 0, length: message.length)
        message.mutableString.replaceOccurrences(of: "**",
            with: "",
            options: .caseInsensitive,
            range: range)
        return message
    }



    // MARK: - Private Aliases
    fileprivate typealias Style = WPStyleGuide.AlertView

    // MARK: - Private Properties
    fileprivate var onCompletion: Completion?

    // MARK: - Private Outlets
    @IBOutlet fileprivate var internalView: AlertInternalView!
}
