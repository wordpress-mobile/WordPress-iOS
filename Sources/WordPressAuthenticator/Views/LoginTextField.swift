import UIKit
import WordPressShared

open class LoginTextField: WPWalkthroughTextField {

    /// Make a Swift-only property communicate a color to the
    /// Objective-C only class, WPWalkthroughTextField.
    ///
    open override var secureTextEntryImageColor: UIColor! {
        set {
            // no-op. Usually set in Interface Builder.
        }
        get {
            return WordPressAuthenticator.shared.style.secondaryNormalBorderColor
        }
    }

    open override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = WordPressAuthenticator.shared.style.textFieldBackgroundColor
    }

    override open func draw(_ rect: CGRect) {
        if showTopLineSeparator {
            guard let context = UIGraphicsGetCurrentContext() else {
                return
            }

            drawTopLine(rect: rect, context: context)
            drawBottomLine(rect: rect, context: context)
        }
    }

    override open var placeholder: String? {
        didSet {
            guard let placeholder,
                let font else {
                return
            }

            let attributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: WordPressAuthenticator.shared.style.placeholderColor,
                .font: font
            ]
            attributedPlaceholder = NSAttributedString(string: placeholder, attributes: attributes)
        }
    }

    override open var leftViewImage: UIImage! {
        set {
            let newImage = newValue.imageWithTintColor(WordPressAuthenticator.shared.style.placeholderColor)
            super.leftViewImage = newImage
        }
        get {
            return super.leftViewImage
        }
    }

    private func drawTopLine(rect: CGRect, context: CGContext) {
        drawBorderLine(from: CGPoint(x: rect.minX, y: rect.minY), to: CGPoint(x: rect.maxX, y: rect.minY), context: context)
    }

    private func drawBottomLine(rect: CGRect, context: CGContext) {
        drawBorderLine(from: CGPoint(x: rect.minX, y: rect.maxY), to: CGPoint(x: rect.maxX, y: rect.maxY), context: context)
    }

    private func drawBorderLine(from startPoint: CGPoint, to endPoint: CGPoint, context: CGContext) {
        let path = UIBezierPath()

        path.move(to: startPoint)
        path.addLine(to: endPoint)
        path.lineWidth = UIScreen.main.scale / 2.0
        context.addPath(path.cgPath)
        context.setStrokeColor(WordPressAuthenticator.shared.style.secondaryNormalBorderColor.cgColor)
        context.strokePath()
    }
}
