import Foundation
import Gridicons
import WordPressUI

class RestoreStatusView: UIView, NibLoadable {

    // MARK: - Properties

    @IBOutlet private weak var icon: UIImageView!
    @IBOutlet private weak var title: UILabel!
    @IBOutlet private weak var body: UILabel!
    @IBOutlet private weak var progressTitle: UILabel!
    @IBOutlet private weak var progressValue: UILabel!
    @IBOutlet private weak var progressView: UIProgressView!
    @IBOutlet private weak var progressDescription: UILabel!
    @IBOutlet private weak var notifyMeButton: UIButton!
    @IBOutlet private weak var hint: UILabel!

    var notifyMeHandler: (() -> Void)?

    // MARK: - Initialization

    override func awakeFromNib() {
        super.awakeFromNib()
        applyStyles()
        configure()
    }

    // MARK: - Styling

    private func applyStyles() {
        backgroundColor = .white

        icon.tintColor = .success

        title.font = WPStyleGuide.fontForTextStyle(.title3, fontWeight: .semibold)
        title.textColor = .text

        body.font = WPStyleGuide.fontForTextStyle(.body)
        body.textColor = .textSubtle
        body.numberOfLines = 0

        progressTitle.font = WPStyleGuide.fontForTextStyle(.body)
        progressTitle.textColor = .text

        progressValue.font = WPStyleGuide.fontForTextStyle(.body)
        progressTitle.textColor = .text

        progressDescription.font = WPStyleGuide.fontForTextStyle(.subheadline)
        progressDescription.textColor = .textSubtle

        hint.font = WPStyleGuide.fontForTextStyle(.subheadline)
        hint.textColor = .textSubtle
        hint.numberOfLines = 0
    }

    // MARK: - Configuration

    func configure() {
        icon.image = .gridicon(.history)
        title.text = Strings.title
        body.text = String(format: Strings.bodyFormat, "placeholder date")
        notifyMeButton.setTitle(Strings.notifyMeButtonTitle, for: .normal)
        hint.text = Strings.hint
    }

    // MARK: - IBAction

    @IBAction func notifyMeButtonTapped(_ sender: Any) {
        notifyMeHandler?()
    }

    private enum Strings {
        static let title = NSLocalizedString("Currently restoring site", comment: "Title for the Jetpack Restore Status screen.")
        static let bodyFormat = NSLocalizedString("We're restoring your site back to %1$@.", comment: "Description for the restore action. %1$@ is a placeholder for the selected date.")
        static let notifyMeButtonTitle = NSLocalizedString("OK, notify me!", comment: "Title for the button that will dismiss this view.")
        static let hint = NSLocalizedString("No need to wait around. We'll notify you when your site has been fully restored.", comment: "A hint to users about restoring their site.")
    }

}
