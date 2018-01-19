import Foundation
import Gridicons

@objc
protocol LoginSocialErrorViewControllerDelegate {
    func retryWithEmail()
    func retryWithAddress()
    func retryAsSignup()
}

/// ViewController for presenting recovery options when social login fails
class LoginSocialErrorViewController: NUXTableViewController {
    fileprivate var errorTitle: String
    fileprivate var errorDescription: String
    fileprivate var restrictToWPCom = false
    @objc var delegate: LoginSocialErrorViewControllerDelegate?
    @objc var handler: ImmuTableViewHandler!


    /// Create and instance of LoginSocialErrorViewController
    ///
    /// - Parameters:
    ///   - title: The title that will be shown on the error VC
    ///   - description: A brief explination of what failed during social login
    @objc init(title: String, description: String, restrictToWPCom: Bool) {
        errorTitle = title
        errorDescription = description
        self.restrictToWPCom = restrictToWPCom

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        errorTitle = aDecoder.value(forKey: "errorTitle") as? String ?? ""
        errorDescription = aDecoder.value(forKey: "errorDescription") as? String ?? ""

        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = WPStyleGuide.greyLighten30()
        addWordPressLogoToNavController()

        ImmuTable.registerRows([
            LoginSocialErrorDescriptionRow.self,
            LoginSocialErrorButtonRow.self,
            ], tableView: self.tableView)

        handler = ImmuTableViewHandler(takeOver: self)
        handler.viewModel = tableViewModel()
    }

    fileprivate func tableViewModel() -> ImmuTable {
        let descriptionRow = LoginSocialErrorDescriptionRow(title: errorTitle, detail: errorDescription)

        var buttonRows = [ImmuTableRow]()
        buttonRows.append(LoginSocialErrorButtonRow(buttonText: NSLocalizedString("Try with another email", comment: "When social login fails, this button offers to let the user try again with a differen email address"),
                                                    buttonIcon: Gridicon.iconOfType(.undo),
                                                    action: retryWithEmailAction()))

        if !restrictToWPCom {
            buttonRows.append(LoginSocialErrorButtonRow(buttonText: NSLocalizedString("Try with the site address", comment: "When social login fails, this button offers to let them try tp login using a URL"),
                                                        buttonIcon: Gridicon.iconOfType(.domains),
                                                        action: retryWithAddressAction()))
        }
        buttonRows.append(LoginSocialErrorButtonRow(buttonText: NSLocalizedString("Sign up", comment: "When social login fails, this button offers to let them signup for a new WordPress.com account"),
                                                    buttonIcon: Gridicon.iconOfType(.mySites),
                                                    action: retryAsSignUpAction()))

        return ImmuTable(sections: [
            ImmuTableSection(rows: [descriptionRow]),
            ImmuTableSection(rows: buttonRows)
            ])

    }

    /// MARK: - ImmuTable Actions
    func retryWithEmailAction() -> ImmuTableAction {
        return { [weak self] _ in
            self?.delegate?.retryWithEmail()
        }
    }

    func retryWithAddressAction() -> ImmuTableAction {
        return { [weak self] _ in
            self?.delegate?.retryWithAddress()
        }
    }

    func retryAsSignUpAction() -> ImmuTableAction {
        return { [weak self] _ in
            self?.delegate?.retryAsSignup()
        }
    }
}


// MARK: ImmuTableRows

struct LoginSocialErrorDescriptionRow: ImmuTableRow {
    static let cell = ImmuTableCell.class(LoginSocialErrorCell.self)
    var title: String = ""
    var detail: String = ""
    var action: ImmuTableAction?

    init(title: String, detail: String) {
        self.title = title
        self.detail = detail
    }

    func configureCell(_ cell: UITableViewCell) {
        guard let cell = cell as? LoginSocialErrorCell else {
            return
        }
        cell.configureCell(title, errorDescription: detail)
    }
}

struct LoginSocialErrorButtonRow: ImmuTableRow {
    static let cell = ImmuTableCell.class(UITableViewCell.self)
    var buttonText: String
    var buttonIcon: UIImage
    var action: ImmuTableAction?

    init(buttonText: String, buttonIcon: UIImage, action: @escaping ImmuTableAction) {
        self.buttonText = buttonText
        self.buttonIcon = buttonIcon
        self.action = action
    }

    func configureCell(_ cell: UITableViewCell) {
        cell.textLabel?.text = buttonText
        cell.textLabel?.textColor = WPStyleGuide.darkGrey()
        cell.imageView?.image = buttonIcon.imageWithTintColor(WPStyleGuide.grey())
    }
}
