import Foundation

class VCItem: FilterTabBarItem {

    let title: String
    let accessibilityIdentifier: String

    init(title: String, accessibilityIdentifier: String) {
        self.title = title
        self.accessibilityIdentifier = accessibilityIdentifier
    }
}

class TabbedViewController: UIViewController {

    typealias Item = (String, UIViewController)

    private let items: [Item]

    private lazy var tabBar: FilterTabBar = {
        let bar = FilterTabBar()
        WPStyleGuide.configureFilterTabBar(bar)
        bar.tabSizingStyle = .equalWidths
        bar.translatesAutoresizingMaskIntoConstraints = false
        bar.addTarget(self, action: #selector(changedItem(sender:)), for: .valueChanged)
        return bar
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        return stackView
    }()

    private weak var child: UIViewController? {
        didSet {
            oldValue?.remove()

            if let child = child {
                addChild(child)
                stackView.addArrangedSubview(child.view)
                child.didMove(toParent: self)
            }
        }
    }

    init(items: [Item]) {
        self.items = items
        super.init(nibName: nil, bundle: nil)
        tabBar.items = items.map({ (title, vc) in
            return VCItem(title: title, accessibilityIdentifier: "")
        })

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(donePressed))

        stackView.addArrangedSubview(tabBar)

        view.backgroundColor = .white
        view.addSubview(stackView)
        view.pinSubviewToAllEdges(stackView)
    }

    @objc func donePressed() {
        dismiss(animated: true, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        child = items.first?.1
    }

    @objc func changedItem(sender: FilterTabBar) {
        let item = items[sender.selectedIndex]
        child = item.1
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
