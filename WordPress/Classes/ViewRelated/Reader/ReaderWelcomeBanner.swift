import Foundation

class ReaderWelcomeBanner: UIView, NibLoadable {
    @IBOutlet weak var welcomeLabel: UILabel!
    @IBOutlet weak var extraDotsView: UIView!

    static var bannerPresentedKey = "welcomeBannerPresented"

    override func awakeFromNib() {
        super.awakeFromNib()
        applyStyles()
        configureWelcomeLabel()
        showExtraDotsIfNeeded()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        showExtraDotsIfNeeded()
    }

    /// Present the Welcome banner just one time
    class func displayIfNeeded(in tableView: UITableView,
                               database: KeyValueDatabase = UserDefaults.standard) {
        guard !database.bool(forKey: ReaderWelcomeBanner.bannerPresentedKey) else {
            return
        }

        let view: ReaderWelcomeBanner = .loadFromNib()
        tableView.tableHeaderView = view
        database.set(true, forKey: ReaderWelcomeBanner.bannerPresentedKey)
    }

    private func applyStyles() {
        welcomeLabel.font = WPStyleGuide.serifFontForTextStyle(.title2)
        backgroundColor = UIColor(light: .muriel(color: MurielColor(name: .blue, shade: .shade0)), dark: .listForeground)
        welcomeLabel.textColor = UIColor(light: .muriel(color: MurielColor(name: .blue, shade: .shade80)), dark: .white)
    }

    private func configureWelcomeLabel() {
        welcomeLabel.text = NSLocalizedString("Welcome to Reader. Discover millions of blogs at your fingertips.", comment: "Welcome message shown under Discover in the Reader just the 1st time the user sees it")
    }

    private func showExtraDotsIfNeeded() {
        extraDotsView.isHidden = (traitCollection.horizontalSizeClass == .compact)
    }
}
