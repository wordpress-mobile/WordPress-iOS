class RevisionOperationViewController: UIViewController {
    var revision: Revision? {
        didSet {
            update()
        }
    }

    private var addView: RevisionOperationView!
    private var delView: RevisionOperationView!
    private var stack: UIStackView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }

    private func setupViews() {
        view.backgroundColor = .listForeground

        addView = RevisionOperation(.add).internalView
        delView = RevisionOperation(.del).internalView

        stack = UIStackView(arrangedSubviews: [addView, delView])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = Constants.operationSpacing

        view.addSubview(stack)
        view.pinSubviewAtCenter(stack)
    }

    private func update() {
        addView.total = revision?.diff?.totalAdditions.intValue ?? 0
        delView.total = revision?.diff?.totalDeletions.intValue ?? 0
    }

    private enum Constants {
        static let operationSpacing: CGFloat = 8.0
    }
}
