import UIKit

class SiteIntentViewController: CollapsableHeaderViewController {
    private let selection: SiteIntentStep.SiteIntentSelection
    private let table: UITableView

    private var selectedVertical: SiteVertical? {
        didSet {
            itemSelectionChanged(selectedVertical != nil)
        }
    }

    init(_ selection: @escaping SiteIntentStep.SiteIntentSelection) {
        self.selection = selection

        table = UITableView(frame: .zero, style: .grouped)

        super.init(
            scrollableView: table,
            mainTitle: Strings.mainTitle,
            prompt: Strings.prompt,
            primaryActionTitle: Strings.primaryAction,
            secondaryActionTitle: nil,
            defaultActionTitle: nil,
            accessoryView: nil
        )
    }

    // MARK: UIViewController

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.backButtonTitle = NSLocalizedString("Topic", comment: "Shortened version of the main title to be used in back navigation")
        configureTable()
        configureSkipButton()
        configureCloseButton()
        largeTitleView.numberOfLines = 2
        SiteCreationAnalyticsHelper.trackSiteIntentViewed()
    }

    // MARK: Constants

    private enum Strings {
        static let mainTitle: String = NSLocalizedString("What's your website about?", comment: "Select the site's intent. Title")
        static let prompt: String = NSLocalizedString("Choose a topic from the list below or type your own", comment: "Select the site's intent. Subtitle")
        static let primaryAction: String = NSLocalizedString("Continue", comment: "Button to progress to the next step")
    }

    // MARK: UI Setup

    private func configureTable() {
        table.backgroundColor = .basicBackground
    }

    private func configureSkipButton() {
        let skip = UIBarButtonItem(title: NSLocalizedString("Skip", comment: "Continue without making a selection"), style: .done, target: self, action: #selector(skipButtonTapped))
        navigationItem.rightBarButtonItem = skip
    }

    private func configureCloseButton() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Cancel", comment: "Cancel site creation"), style: .done, target: self, action: #selector(closeButtonTapped))
    }

    // MARK: Actions

    override func primaryActionSelected(_ sender: Any) {
        guard let selectedVertical = selectedVertical else {
            return
        }

        SiteCreationAnalyticsHelper.trackSiteIntentSelected(selectedVertical)
        selection(selectedVertical)
    }

    @objc
    private func skipButtonTapped(_ sender: Any) {
        SiteCreationAnalyticsHelper.trackSiteIntentSkipped()
        selection(nil)
    }

    @objc
    private func closeButtonTapped(_ sender: Any) {
        SiteCreationAnalyticsHelper.trackSiteIntentCanceled()
        dismiss(animated: true)
    }
}
