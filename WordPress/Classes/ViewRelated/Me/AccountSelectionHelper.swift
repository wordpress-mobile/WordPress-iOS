import Foundation

@objc class Account: NSObject {
    var userId: NSNumber
    var username: String
    var email: String

    init(userId: NSNumber, username: String, email: String) {
        self.userId = userId
        self.username = username
        self.email = email
    }
}

protocol AccountSelectionHelperDelegate: class {
    func selectedAccount(account: Account)
}

class AccountSelectionHelper: NSObject {

    var accountsListView: UIView?
    var titleView: UIView
    weak var delegate: AccountSelectionHelperDelegate?
    let parentView: UIView
    var accounts: [Account]
    let height: CGFloat = 44.0

    var tableViewController = UITableViewController()
    var handler: ImmuTableViewHandler!

    let chevronImageView: UIImageView = { () -> UIImageView in
        let chevron = UIImage.init(named: "theme-type-chevron")
        return UIImageView.init(image: chevron)
    }()

    let disclosureChevronImageView: UIImageView = {
        let chevron = UIImage.init(named: "disclosure-chevron")
        return UIImageView.init(image: chevron)
    }()

    var titleLabel: UILabel = {
        let label = UILabel()
        label.text =  NSLocalizedString("Me", comment: "Me page title")
        label.font = UIFont.init(name: "Helvetica-Bold", size: 17)
        label.textColor = UIColor.whiteColor()
        label.textAlignment = NSTextAlignment.Center
        return label
    }()

    convenience init(parentView: UIView, accounts: [Account], delegate: AccountSelectionHelperDelegate, height: CGFloat) {

        self.init(frame: CGRectMake(0, 0, parentView.frame.size.width * 0.5, height),
                  parentView: parentView,
                  accounts: accounts,
                  delegate: delegate)

        setupTitleLabel()
        setupChevronFrames()
        setupSwitchButton()
        setupAccountTableView()
    }

    init(frame: CGRect, parentView: UIView, accounts: [Account], delegate: AccountSelectionHelperDelegate) {
        self.parentView = parentView
        self.accounts = accounts
        self.delegate = delegate
        self.titleView = UIView.init(frame: frame)
        super.init()
    }

    func setupSwitchButton() {
        let showListButton = UIButton(frame: CGRectMake(0, 0, self.titleView.frame.size.width, height))
        showListButton.addTarget(self,
                                 action: #selector(AccountSelectionHelper.showAccountSelectionView),
                                 forControlEvents: UIControlEvents.TouchUpInside)
        self.titleView.addSubview(showListButton)
    }

    func setupTitleLabel() {
        titleLabel.frame = CGRectMake(0, 0, self.titleView.frame.size.width, height)
        self.titleView.addSubview(self.titleLabel)
    }

    func setupAccountTableView() {
        ImmuTable.registerRows([
            AccountItemRow.self
            ], tableView: (self.tableViewController.tableView))

        self.tableViewController.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableViewController.tableView.estimatedRowHeight = 44

        handler = ImmuTableViewHandler(takeOver: self.tableViewController)
    }

    func setupChevronFrames() {
        self.chevronImageView.frame = CGRectMake(self.titleView.frame.size.width * 0.6,
                                                 self.titleLabel.frame.origin.y + 15,
                                                 self.chevronImageView.frame.size.width,
                                                 self.chevronImageView.frame.size.height)

        self.disclosureChevronImageView.frame = CGRectMake(self.titleView.frame.size.width * 0.65,
                                                           self.titleLabel.frame.origin.y + 13,
                                                           self.disclosureChevronImageView.frame.size.width,
                                                           self.disclosureChevronImageView.frame.size.height)
        self.titleView.addSubview(self.disclosureChevronImageView)
    }

    // MARK: - Account Selection
    func showAccountSelectionView() {

        if self.accountsListView != nil {
            UIView.animateWithDuration(0.3, animations: {
                self.chevronImageView.removeFromSuperview()
                self.titleView.addSubview(self.disclosureChevronImageView)
                self.accountsListView?.alpha = 0
                }, completion: { (true) in
                    self.accountsListView?.removeFromSuperview()
                    self.accountsListView = nil
            })
            return
        }

        self.accountsListView = accountsFloatingListView(CGPointMake(self.parentView.frame.size.width/2, 0))
        guard let accountLV = self.accountsListView else { return }
        accountLV.alpha = 0
        self.parentView.addSubview(accountLV)
        UIView.animateWithDuration(0.3, animations: {
            self.disclosureChevronImageView.removeFromSuperview()
            self.titleView.addSubview(self.chevronImageView)
            accountLV.alpha = 1
        })
    }

    func accountSelection() -> ImmuTableAction {
        return { [unowned self] row in

            guard let accountItemRow = row as? AccountItemRow else { return }
            guard let delegate = self.delegate else { return }
            delegate.selectedAccount(accountItemRow.account)
            self.removeView()
        }
    }

    // MARK: - Private Methods

    private func removeView() {
        guard let accountsListView = self.accountsListView else { return }
        UIView.animateWithDuration(0.5, animations: {
            self.chevronImageView.removeFromSuperview()
            self.titleView.addSubview(self.disclosureChevronImageView)
            accountsListView.alpha = 0
        }) { (true) in
            accountsListView.removeFromSuperview()
            self.accountsListView = nil
        }
    }

    private func backgroundView() -> UIView {
        let screenHeight = self.parentView.frame.size.height
        let screenWidth = self.parentView.frame.size.width
        let backgroundView = UIView.init(frame: CGRectMake(0, 0, screenWidth, screenHeight))
        return backgroundView
    }

    private func accountsFloatingListView(at: CGPoint) -> UIView {
        let backgroundView = self.backgroundView()
        let viewHeight: CGFloat = self.height * CGFloat(self.accounts.count)
        let view = UIView.init(frame: CGRectMake(0, 0, 250, viewHeight))

        view.layer.borderWidth = 1
        view.center.x = at.x

        self.tableViewController.tableView.frame = CGRectMake(0, 0, view.frame.size.width, viewHeight)
        handler.viewModel = tableViewAccountModel()

        view.addSubview(self.tableViewController.tableView)
        backgroundView.addSubview(view)
        return backgroundView
    }

    private func tableViewAccountModel() -> ImmuTable {

        let placeholder = UIImage(named: "gravatar.png")
        var accountItemRows: [ImmuTableRow] = []
        for account in accounts {
            let accountItemRow = AccountItemRow(
                account: account,
                action: accountSelection(),
                placeholder: placeholder!
            )
            accountItemRows.append(accountItemRow)
        }
        
        return ImmuTable( sections: [ImmuTableSection(rows: accountItemRows)])
    }
}
