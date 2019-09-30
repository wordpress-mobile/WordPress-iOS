/// A `ImmuTableRow` that contains a `UICollectionView`.
/// Currently the `CollectionViewContainerCell` is fairly specific to needs of Plugin Directory,
/// but it should be possible to make it more generic in the future if there's a need to — it was deliberately
/// not made as generic as possible, in case it won't be used.


struct CollectionViewContainerRow<CollectionViewCellType: UICollectionViewCell, Item>: ImmuTableRow {

    typealias CellType = CollectionViewContainerCell

    static var cell: ImmuTableCell {
        return .class(CollectionViewContainerCell.self)
    }

    let title: String
    let secondaryTitle: String?
    let action: ImmuTableAction?
    let noResultsView: NoResultsViewController?

    private let helper: CollectionViewHandler

    init(data: [Item],
         title: String,
         secondaryTitle: String?,
         action: ImmuTableAction?,
         configureCollectionCell: @escaping ((CollectionViewCellType, Item) -> Void),
         collectionCellSelected: @escaping ((Item) -> Void)) {

        self.title = title
        self.secondaryTitle = secondaryTitle
        self.action = action
        self.noResultsView = nil

        let configurationBlock = { (cell: UICollectionViewCell, item: Any) in
            configureCollectionCell(cell as! CollectionViewCellType, item as! Item)
        }

        let selectionBlock = { (item: Any) in
            collectionCellSelected(item as! Item)
        }

        helper = CollectionViewHandler(dataSourceItems: data,
                                                  configureCollectionCellBlock: configurationBlock,
                                                  collectionCellSeletectedBlock: selectionBlock)
    }

    init(title: String,
         secondaryTitle: String?,
         action: ImmuTableAction?,
         noResultsView: NoResultsViewController) {
        self.title = title
        self.secondaryTitle = secondaryTitle
        self.action = action
        self.noResultsView = noResultsView

        let configurationBlock = { (_: UICollectionViewCell, _: Any) in return }
        let selectionBlock = { (_: Any) in return }

        helper = CollectionViewHandler(dataSourceItems: [],
                                       configureCollectionCellBlock: configurationBlock,
                                       collectionCellSeletectedBlock: selectionBlock)
    }

    func configureCell(_ cell: UITableViewCell) {
        let cell = cell as! CellType

        cell.titleLabel.text = title

        cell.actionButton.setTitle(secondaryTitle, for: .normal)
        cell.buttonTappedAction = { self.action?(self) }

        cell.noResultsView = noResultsView

        if nil != Bundle.main.path(forResource: String(describing: CollectionViewCellType.self), ofType: "nib") {
            cell.collectionView.register(UINib(nibName: String(describing: CollectionViewCellType.self), bundle: nil),
                                         forCellWithReuseIdentifier: CollectionViewHandler.CellReuseIdentifier)
        } else {
            cell.collectionView.register(CollectionViewCellType.self, forCellWithReuseIdentifier: CollectionViewHandler.CellReuseIdentifier)
        }

        cell.collectionView.delegate = helper
        cell.collectionView.dataSource = helper
    }

}

/// Generic Swift classes can't be made `@objc`, so we're using this helper object to be a `UICollectionView[DataSource|Delegate]`
@objc private class CollectionViewHandler: NSObject, UICollectionViewDelegate, UICollectionViewDataSource {
    fileprivate static let CellReuseIdentifier = "CollectionViewContainerRowReuseIdentifier"

    let dataSourceItems: [Any]
    let configureCollectionCellBlock: ((UICollectionViewCell, Any) -> Void)
    let collectionCellSeletectedBlock: ((Any) -> Void)

    init(dataSourceItems: [Any],
         configureCollectionCellBlock: @escaping ((UICollectionViewCell, Any) -> Void),
         collectionCellSeletectedBlock: @escaping ((Any) -> Void)) {

        self.dataSourceItems = dataSourceItems
        self.configureCollectionCellBlock = configureCollectionCellBlock
        self.collectionCellSeletectedBlock = collectionCellSeletectedBlock
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSourceItems.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CollectionViewHandler.CellReuseIdentifier, for: indexPath)

        let dataItem = dataSourceItems[indexPath.item]
        configureCollectionCellBlock(cell, dataItem)

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionCellSeletectedBlock(dataSourceItems[indexPath.item])
    }

}

class CollectionViewContainerCell: UITableViewCell {

    private(set) var collectionView: UICollectionView!
    private(set) var titleLabel: UILabel!
    private(set) var actionButton: UIButton!
    fileprivate var noResultsView: NoResultsViewController? {
        didSet {
            oldValue?.removeFromView()

            guard let noResultsView = noResultsView else {
                    return
            }

            let containerView = UIView(frame: collectionView.frame)
            containerView.translatesAutoresizingMaskIntoConstraints = false

            noResultsView.view.backgroundColor = .clear
            noResultsView.view.frame = containerView.frame
            noResultsView.view.frame.origin.y = 0

            containerView.addSubview(noResultsView.view)
            addSubview(containerView)

            NSLayoutConstraint.activate([
                containerView.topAnchor.constraint(equalTo: collectionView.topAnchor),
                containerView.bottomAnchor.constraint(equalTo: collectionView.bottomAnchor),
                containerView.leadingAnchor.constraint(equalTo: collectionView.leadingAnchor),
                containerView.trailingAnchor.constraint(equalTo: collectionView.trailingAnchor)
                ])
        }
    }

    var buttonTappedAction: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }


    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        selectionStyle = .none

        titleLabel = UILabel(frame: .zero)
        titleLabel.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .title2).pointSize,
                                            weight: .bold)
        titleLabel.textColor = .neutral(.shade70)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        self.addSubview(titleLabel)

        titleLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: Constants.spacing).isActive = true

        titleLabel.leadingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.leadingAnchor, constant: Constants.spacing).isActive = true

        actionButton = UIButton(type: .custom)
        actionButton.setTitleColor(.primary(.shade40), for: .normal)
        actionButton.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
        actionButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        actionButton.translatesAutoresizingMaskIntoConstraints = false

        self.addSubview(actionButton)

        actionButton.trailingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.trailingAnchor, constant: -Constants.spacing).isActive = true

        actionButton.lastBaselineAnchor.constraint(equalTo: titleLabel.lastBaselineAnchor).isActive = true
        actionButton.setContentHuggingPriority(.required, for: .horizontal)

        titleLabel.trailingAnchor.constraint(greaterThanOrEqualTo: actionButton.leadingAnchor).isActive = true

        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        flowLayout.itemSize = CGSize(width: Constants.cellWidth, height: Constants.cellHeight)
        flowLayout.minimumLineSpacing = Constants.spacing
        flowLayout.sectionInset = UIEdgeInsets(top: 0, left: Constants.spacing, bottom: 0, right: Constants.spacing)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .clear

        self.addSubview(collectionView)

        collectionView.topAnchor.constraint(equalTo: titleLabel.lastBaselineAnchor, constant: Constants.labelVerticalSpacing).isActive = true
        collectionView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
    }

    override func prepareForReuse() {
        noResultsView?.removeFromView()
        noResultsView = nil
    }

    @objc private func actionButtonTapped() {
        buttonTappedAction?()
    }

    private enum Constants {
        static var cellWidth: CGFloat = 98
        static var cellHeight: CGFloat = cellWidth * 2
        static var spacing: CGFloat = 18
        static var labelVerticalSpacing: CGFloat = 8
    }

}
