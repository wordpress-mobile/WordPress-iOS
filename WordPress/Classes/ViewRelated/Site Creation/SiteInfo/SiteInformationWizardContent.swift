import UIKit

final class SiteInformationWizardContent: UIViewController {
    private let service: SiteInformationService
    private let completion: (SiteInformationCollectedData) -> Void

    @IBOutlet weak var table: UITableView!
    @IBOutlet weak var nextStep: UIButton!

    init(service: SiteInformationService, completion: @escaping (SiteInformationCollectedData) -> Void) {
        self.service = service
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
        service.information(for: Locale.current) { [weak self] result in
            switch result {
            case .error(let error):
                self?.handleError(error)
            case .success(let data):
                self?.handleData(data)
            }
        }
    }

    private func handleError(_ error: Error) {
        debugPrint("=== handling error===")
    }

    private func handleData(_ data: SiteInformation) {
        let headerData = SiteCreationHeaderData(title: data.title, subtitle: data.subtitle)
        setupHeader(headerData)
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
        // This object is used to pass all user-entered data. I am not sure how we are goind to do that yet
        let collectedData = SiteInformationCollectedData()
        completion(collectedData)
    }
}
