import UIKit

class JetpackScanThreatDetailsViewController: UIViewController {

    // MARK: - Properties

    private let threat: JetpackScanThreat

    // MARK: - Init

    init(threat: JetpackScanThreat) {
        self.threat = threat
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = Strings.title
        configureThreatDetailsView()
    }

    // MARK: - Configure

    private func configureThreatDetailsView() {
        let threatDetailsView = ThreatDetailsView.loadFromNib()
        threatDetailsView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(threatDetailsView)
        view.pinSubviewToAllEdges(threatDetailsView)
    }
}

extension JetpackScanThreatDetailsViewController {

    private enum Strings {
        static let title = NSLocalizedString("Threat details", comment: "Title for the Jetpack Scan Threat Details screen")
    }
}
