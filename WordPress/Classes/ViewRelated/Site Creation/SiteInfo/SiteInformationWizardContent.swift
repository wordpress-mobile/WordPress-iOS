import UIKit

final class SiteInformationWizardContent: UIViewController {
    private let completion: (SiteInformation) -> Void

    @IBOutlet weak var table: UITableView!
    @IBOutlet weak var nextStep: UIButton!

    init(completion: @escaping (SiteInformation) -> Void) {
        self.completion = completion
        super.init(nibName: String(describing: type(of: self)), bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        applyTitle()
        setupBackground()
        setupTable()
        setupNextButton()
        render()
    }

    private func applyTitle() {
        title = NSLocalizedString("2 of 3", comment: "Site creation. Step 2. Screen title")
    }

    private func setupBackground() {
        view.backgroundColor = WPStyleGuide.greyLighten30()
    }

    private func setupTable() {
        setupTableBackground()
        hideSeparators()
    }

    private func setupTableBackground() {
        table.backgroundColor = WPStyleGuide.greyLighten30()
    }

    private func hideSeparators() {
        table.tableFooterView = UIView(frame: .zero)
    }

    private func setupNextButton() {
        nextStep.addTarget(self, action: #selector(goNext), for: .touchUpInside)

        let buttonTitle = NSLocalizedString("Next", comment: "Button to progress to the next step")
        nextStep.setTitle(buttonTitle, for: .normal)
        nextStep.accessibilityLabel = buttonTitle
        nextStep.accessibilityHint = NSLocalizedString("Navigates to the next step", comment: "Site creation. Navigates tot he next step")
    }

    private func render() {
    }

    private func setupHeader(_ headerData: SiteCreationHeaderData) {
        let header = TitleSubtitleHeader(frame: .zero)
        header.setTitle(headerData.title)
        header.setSubtitle(headerData.subtitle)

        table.tableHeaderView = header

        // This is the only way I found to insert a stack view into the header without breaking the autolayout constraints. We do something similar in Reader
        header.centerXAnchor.constraint(equalTo: table.centerXAnchor).isActive = true
        header.widthAnchor.constraint(equalTo: table.layoutMarginsGuide.widthAnchor).isActive = true
        header.topAnchor.constraint(equalTo: table.layoutMarginsGuide.topAnchor).isActive = true

        table.tableHeaderView?.layoutIfNeeded()
        table.tableHeaderView = table.tableHeaderView
    }

    @objc
    private func goNext() {
        let collectedData = SiteInformation(title: "Change me", tagLine: "Change me")
        completion(collectedData)
    }
}
