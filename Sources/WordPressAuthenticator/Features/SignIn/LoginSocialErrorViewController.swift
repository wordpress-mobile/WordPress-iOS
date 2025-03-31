import Foundation
import Gridicons
import WordPressShared

@objc
protocol LoginSocialErrorViewControllerDelegate {
    func retryWithEmail()
    func retryWithAddress()
    func retryAsSignup()
    func errorDismissed()
}

/// ViewController for presenting recovery options when social login fails
class LoginSocialErrorViewController: NUXTableViewController {
    fileprivate var errorTitle: String
    fileprivate var errorDescription: String
    @objc weak var delegate: LoginSocialErrorViewControllerDelegate?

    private var forUnified: Bool = false
    private var actionButtonTapped: Bool = false
    private let unifiedAuthEnabled = WordPressAuthenticator.shared.configuration.enableUnifiedAuth

    fileprivate enum Sections: Int {
        case titleAndDescription = 0
        case buttons = 1

        static var count: Int {
            return buttons.rawValue + 1
        }
    }

    fileprivate enum Buttons: Int {
        case tryEmail = 0
        case tryAddress = 1
        case signup = 2

        static var count: Int {
            return signup.rawValue + 1
        }
    }

    /// Create and instance of LoginSocialErrorViewController
    ///
    /// - Parameters:
    ///   - title: The title that will be shown on the error VC
    ///   - description: A brief explination of what failed during social login
    @objc init(title: String, description: String) {
        errorTitle = title
        errorDescription = description

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        errorTitle = aDecoder.value(forKey: "errorTitle") as? String ?? ""
        errorDescription = aDecoder.value(forKey: "errorDescription") as? String ?? ""

        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let unifiedGoogle = unifiedAuthEnabled && loginFields.meta.socialService == .google
        let unifiedApple = unifiedAuthEnabled && loginFields.meta.socialService == .apple
        forUnified = unifiedGoogle || unifiedApple

        styleNavigationBar(forUnified: forUnified)
        styleBackground()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if !actionButtonTapped {
            delegate?.errorDismissed()
        }
    }

    private func styleBackground() {
        guard let unifiedBackgroundColor = WordPressAuthenticator.shared.unifiedStyle?.viewControllerBackgroundColor else {
            view.backgroundColor = WordPressAuthenticator.shared.style.viewControllerBackgroundColor
            return
        }

        view.backgroundColor = forUnified ? unifiedBackgroundColor : WordPressAuthenticator.shared.style.viewControllerBackgroundColor
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section == Sections.buttons.rawValue,
            let delegate else {
            return
        }

        actionButtonTapped = true

        switch indexPath.row {
        case Buttons.tryEmail.rawValue:
            delegate.retryWithEmail()
        case Buttons.tryAddress.rawValue:
            if loginFields.restrictToWPCom {
                fallthrough
            } else {
                delegate.retryWithAddress()
            }
        case Buttons.signup.rawValue:
            fallthrough
        default:
            delegate.retryAsSignup()
        }
    }
}

// MARK: UITableViewDelegate methods

extension LoginSocialErrorViewController {
    private struct RowHeightConstants {
        static let estimate: CGFloat = 45.0
        static let automatic: CGFloat = UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return RowHeightConstants.estimate
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return RowHeightConstants.automatic
    }
}

// MARK: UITableViewDataSource methods

extension LoginSocialErrorViewController {
    private func numberOfButtonsToShow() -> Int {

        var buttonCount = loginFields.restrictToWPCom ? Buttons.count - 1 : Buttons.count

        // Don't show the Signup Retry if showing unified social flows.
        // At this point, we've already tried signup and are past it.
        let unifiedGoogle = unifiedAuthEnabled && loginFields.meta.socialService == .google
        let unifiedApple = unifiedAuthEnabled && loginFields.meta.socialService == .apple

        if unifiedGoogle || unifiedApple {
            buttonCount -= 1
        }

        return buttonCount
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return Sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case Sections.titleAndDescription.rawValue:
            return 1
        case Sections.buttons.rawValue:
            return numberOfButtonsToShow()
        default:
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        switch indexPath.section {
        case Sections.titleAndDescription.rawValue:
            cell = titleAndDescriptionCell()
        case Sections.buttons.rawValue:
            fallthrough
        default:
            cell = buttonCell(index: indexPath.row)
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footer = UIView()
        footer.backgroundColor = WordPressAuthenticator.shared.style.viewControllerBackgroundColor
        return footer
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.5
    }

    private func titleAndDescriptionCell() -> UITableViewCell {
        return LoginSocialErrorCell(title: errorTitle, description: errorDescription, forUnified: forUnified)
    }

    private func buttonCell(index: Int) -> UITableViewCell {
        let cell = UITableViewCell()
        let buttonText: String
        let buttonIcon: UIImage
        switch index {
        case Buttons.tryEmail.rawValue:
            buttonText = NSLocalizedString("Try with another email", comment: "When social login fails, this button offers to let the user try again with a differen email address")
            buttonIcon = .gridicon(.undo)
        case Buttons.tryAddress.rawValue:
            if loginFields.restrictToWPCom {
                fallthrough
            } else {
                buttonText = NSLocalizedString("Try with the site address", comment: "When social login fails, this button offers to let them try tp login using a URL")
                buttonIcon = .gridicon(.domains)
            }
        case Buttons.signup.rawValue:
            fallthrough
        default:
            buttonText = NSLocalizedString("Sign up", comment: "When social login fails, this button offers to let them signup for a new WordPress.com account")
            buttonIcon = .gridicon(.mySites)
        }
        cell.textLabel?.text = buttonText
        cell.textLabel?.textColor = WPStyleGuide.darkGrey()
        cell.imageView?.image = buttonIcon.imageWithTintColor(WPStyleGuide.grey())
        return cell
    }
}
