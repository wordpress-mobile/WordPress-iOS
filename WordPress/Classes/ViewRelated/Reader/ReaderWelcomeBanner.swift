import Foundation

class ReaderWelcomeBanner: UIView, NibLoadable {
    @IBOutlet weak var welcomeLabel: UILabel!
    @IBOutlet weak var iPadDotsView: UIView!

    static var bannerPresentedKey = "welcomeBannerPresented"

    override func awakeFromNib() {
        super.awakeFromNib()
        applyStyles()
        configureWelcomeLabel()
        configureDotsForiPad()
    }

    /// Present the Welcome banner just one time
    class func displayIfNeeded(in tableView: UITableView) {
        guard !UserDefaults.standard.bool(forKey: ReaderWelcomeBanner.bannerPresentedKey) else {
            return
        }

        let view: ReaderWelcomeBanner = .loadFromNib()
        tableView.tableHeaderView = view
        UserDefaults.standard.set(true, forKey: ReaderWelcomeBanner.bannerPresentedKey)
    }

    private func applyStyles() {
        welcomeLabel.font = WPStyleGuide.serifFontForTextStyle(.title2)
        backgroundColor = UIColor(light: .muriel(color: MurielColor(name: .blue, shade: .shade0)), dark: .listForeground)
        welcomeLabel.textColor = UIColor(light: .muriel(color: MurielColor(name: .blue, shade: .shade80)), dark: .white)
    }

    private func configureWelcomeLabel() {
        welcomeLabel.text = NSLocalizedString("Welcome to Reader. Discover millions of blogs at your fingertips.", comment: "Welcome message shown under Discover in the Reader just the 1st time the user sees it")
    }

    private func configureDotsForiPad() {
        iPadDotsView.isHidden = !UIDevice.isPad()
    }
}
