
import UIKit

final class SiteSegmentsWizardContent: UIViewController {
    private let service: SiteSegmentsService

    @IBOutlet weak var table: UITableView!

    init(service: SiteSegmentsService) {
        self.service = service
        super.init(nibName: String(describing: type(of: self)), bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        fetchSegments()
    }

    private func fetchSegments() {
        service.siteSegments(for: Locale.current) { [weak self] results in
            switch results {
            case .error(let error):
                self?.handleError(error)
            case .success(let data):
                self?.handleData(data)
            }
        }
    }

    private func handleError(_ error: Error) {
        print("=== handling error===")
    }

    private func handleData(_ data: [SiteSegment]) {
        print("handling data")
    }
}

final class SegmentsDataSource: NSObject, UITableViewDataSource {
    private let data: [SiteSegment]

    init(data: [SiteSegment]) {
        self.data = data
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }
}
