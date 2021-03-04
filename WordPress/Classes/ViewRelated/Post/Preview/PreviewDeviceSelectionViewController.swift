import Foundation

class PreviewDeviceSelectionViewController: UIViewController {
    enum PreviewDevice: String, CaseIterable {
        case desktop = "desktop"
        case tablet = "tablet"
        case mobile = "mobile"

        static var `default`: PreviewDevice {
            return UIDevice.current.userInterfaceIdiom == .pad ? .tablet : .mobile
        }

        var title: String {
            switch self {
            case .desktop:
                return NSLocalizedString("Desktop", comment: "Title for the desktop web preview")
            case .tablet:
                return NSLocalizedString("Tablet", comment: "Title for the tablet web preview")
            case .mobile:
                return NSLocalizedString("Mobile", comment: "Title for the mobile web preview")
            }
        }

        var width: CGFloat {
            switch self {
            case .desktop:
                return 1200
            case .tablet:
                return 800
            case .mobile:
                return 400
            }
        }

        static var available: [PreviewDevice] {
            return [.mobile, .tablet, .desktop]
        }

        var viewportScript: String {
            return String(format: "let parent = document.querySelector('meta[name=viewport]'); parent.setAttribute('content', 'width=%1$d, initial-scale=0');", NSInteger(width))
        }
    }

    var selectedOption: PreviewDevice = PreviewDevice.default

    var onDeviceChange: ((PreviewDevice) -> Void)?

    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView .translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .clear
        tableView.alwaysBounceVertical = false
        tableView.separatorInset = .zero
        return tableView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        let blurEffect: UIBlurEffect
        blurEffect = UIBlurEffect(style: .systemMaterial)

        let effectView = UIVisualEffectView(effect: blurEffect)

        effectView.backgroundColor = .clear
        effectView.translatesAutoresizingMaskIntoConstraints = false

        view.backgroundColor = .clear
        view.addSubview(effectView)
        view.pinSubviewToAllEdges(effectView)

        effectView.contentView.addSubview(tableView)

        effectView.contentView.pinSubviewToAllEdges(tableView)

        tableView.separatorEffect = UIVibrancyEffect(blurEffect: blurEffect)

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }

    override var preferredContentSize: CGSize {
        get {
            tableView.layoutIfNeeded()
            return CGSize(width: 240, height: tableView.contentSize.height)
        }
        set {
            // No-op - Cell is calculated from the table view's contentSize
        }
    }
}

extension PreviewDeviceSelectionViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return PreviewDevice.available.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        cell.backgroundColor = .clear

        let device = PreviewDevice.available[indexPath.row]

        cell.textLabel?.text = device.title
        cell.textLabel?.font = WPStyleGuide.regularTextFont()

        if device == selectedOption {
            cell.accessoryType = .checkmark
            cell.accessibilityTraits = [.button, .selected]
        } else {
            cell.accessoryType = .none
            cell.accessibilityTraits = .button
        }

        return cell
    }

    // This is a "hack" that prevents the bottom cell's separator from being shown.
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.1
    }
}

extension PreviewDeviceSelectionViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let newlySelectedDeviceMode = PreviewDevice.available[indexPath.row]
        if newlySelectedDeviceMode != selectedOption {
            onDeviceChange?(newlySelectedDeviceMode)
        }
        dismiss(animated: true, completion: nil)
    }
}
