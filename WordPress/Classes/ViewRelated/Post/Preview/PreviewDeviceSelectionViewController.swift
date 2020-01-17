import Foundation

class PreviewDeviceSelectionViewController: UIViewController {
    enum PreviewDevice: CaseIterable {
        case desktop
        case `default`

        var title: String {
            switch self {
            case .desktop:
                return "Desktop"
            case .`default`:
                return "Default"
            }
        }
    }

    var selectedOption: PreviewDevice = .default

    var dismissHandler: ((PreviewDevice) -> Void)?

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
        if #available(iOS 13.0, *) {
            blurEffect = UIBlurEffect(style: .systemMaterial)
        } else {
            blurEffect = UIBlurEffect(style: .light)
        }

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
        return PreviewDevice.allCases.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        cell.backgroundColor = .clear

        let device = PreviewDevice.allCases[indexPath.row]

        cell.textLabel?.text = device.title
        cell.textLabel?.font = WPStyleGuide.regularTextFont()


        if device == selectedOption {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
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
        dismissHandler?(PreviewDevice.allCases[indexPath.row])
        dismiss(animated: true, completion: nil)
    }
}
