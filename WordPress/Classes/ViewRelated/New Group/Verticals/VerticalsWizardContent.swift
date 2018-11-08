import UIKit
import WordPressKit

/// Contains the UI corresponsing to the list of verticals
final class VerticalsWizardContent: UIViewController {
    private let segment: SiteSegment?
    private let service: SiteVerticalsService
    private var dataCoordinator: (UITableViewDataSource & UITableViewDelegate)?
    private let selection: (SiteVertical) -> Void

    private let throttle = Scheduler(seconds: 1)

    @IBOutlet weak var search: UITextField!
    @IBOutlet weak var table: UITableView!

    private lazy var headerData: SiteCreationHeaderData = {
        let title = NSLocalizedString("What's the focus of your business?", comment: "Create site, step 2. Select focus of the business. Title")
        let subtitle = NSLocalizedString("We'll use your answer to add sections to your website.", comment: "Create site, step 2. Select focus of the business. Subtitle")

        return SiteCreationHeaderData(title: title, subtitle: subtitle)
    }()



    init(segment: SiteSegment?, service: SiteVerticalsService, selection: @escaping (SiteVertical) -> Void) {
        self.segment = segment
        self.service = service
        self.selection = selection
        super.init(nibName: String(describing: type(of: self)), bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupTable()

        setupSearchField()
    }

    private func setupTable() {
        let cellName = VerticalsCell.cellReuseIdentifier()
        let nib = UINib(nibName: cellName, bundle: nil)
        table.register(nib, forCellReuseIdentifier: cellName)
    }

    private func setupSearchField() {
        search.leftViewMode = .always

        search.addTarget(self, action: #selector(textChanged), for: .editingChanged)
    }

    @objc
    private func textChanged(sender: UITextField) {
        guard let searchTerm = sender.text, searchTerm.isEmpty == false else {
            return
        }

        throttle.throttle { [weak self] in
            self?.fetchVerticals(searchTerm)
        }
    }

    private func fetchVerticals(_ searchTerm: String) {
        guard let segment = segment else {
            return
        }

        service.verticals(for: Locale.current, type: segment) {  [weak self] results in
            switch results {
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

    private func handleData(_ data: [SiteVertical]) {
        dataCoordinator = SiteCreationDataCoordinator(data: data, cellType: VerticalsCell.self, selection: didSelect, headerData: headerData)
        table.dataSource = dataCoordinator
        table.delegate = dataCoordinator
        table.reloadData()
    }

    private func didSelect(_ segment: SiteVertical) {
        selection(segment)
    }
}
