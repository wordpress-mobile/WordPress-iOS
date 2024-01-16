import UIKit
import Gridicons
import WordPressShared

// MARK: - SearchTextField

final class SearchTextField: UITextField {

    // MARK: Properties

    private struct Constants {
        static let defaultPadding   = CGFloat(16)
        static let iconDimension    = CGFloat(18)
        static let iconInset        = CGFloat(19)
        static let clearButtonInset = CGFloat(-9)
        static let searchHeight     = CGFloat(44)
        static let textInset        = CGFloat(56)
    }

    // MARK: UIView

    init() {
        super.init(frame: .zero)
        initialize()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: UITextField

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: Constants.textInset, dy: 0)
    }

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        let textInsets = UIEdgeInsets(top: 0, left: Constants.textInset, bottom: 0, right: Constants.defaultPadding)
        return bounds.inset(by: textInsets)
    }

    override func leftViewRect(forBounds bounds: CGRect) -> CGRect {
        let iconY = (bounds.height - Constants.iconDimension) / 2
        return CGRect(x: Constants.iconInset, y: iconY, width: Constants.iconDimension, height: Constants.iconDimension)
    }

    override func rightViewRect(forBounds bounds: CGRect) -> CGRect {
        let iconX = bounds.width - Constants.iconInset - Constants.iconDimension
        let iconY = (bounds.height - Constants.iconDimension) / 2
        return CGRect(x: iconX, y: iconY, width: Constants.iconDimension, height: Constants.iconDimension)
    }

    override func clearButtonRect(forBounds bounds: CGRect) -> CGRect {
        let originalClearButtonRect = super.clearButtonRect(forBounds: bounds)

        var offsetX = Constants.clearButtonInset

        if effectiveUserInterfaceLayoutDirection == .rightToLeft {
            offsetX = -offsetX
        }

        return originalClearButtonRect.offsetBy(dx: offsetX, dy: 0)
    }

    // MARK: Private behavior

    private func initialize() {
        translatesAutoresizingMaskIntoConstraints = false

        backgroundColor = .listForeground
        clearButtonMode = .whileEditing
        font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .regular)
        textColor = .text

        autocapitalizationType = .none
        autocorrectionType = .no
        adjustsFontForContentSizeCategory = true

        setIconImage(view: searchIconImageView)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: Constants.searchHeight),
            ])
    }

    private lazy var searchIconImageView: UIImageView = {
        let iconSize = CGSize(width: Constants.iconDimension, height: Constants.iconDimension)
        let loupeIcon = UIImage.gridicon(.search, size: iconSize).imageWithTintColor(.listIcon)
        return UIImageView(image: loupeIcon)
    }()

    private lazy var activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.backgroundColor = UIColor.clear

        return activityIndicator
    }()

    func setIcon(isLoading: Bool) {
        if isLoading {
            setIconImage(view: activityIndicator)
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
            setIconImage(view: searchIconImageView)
        }
    }

    private func setIconImage(view: UIView) {
        // Since the RTL layout is already handled elsewhere updating leftView is enough here
        leftView = view
        leftViewMode = .always
    }
}
