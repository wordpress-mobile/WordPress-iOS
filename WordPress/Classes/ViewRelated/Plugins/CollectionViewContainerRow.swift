/// A `ImmuTableRow` that contains a `UICollectionView`.
/// Currently the `CollectionViewContainerCell` is fairly specific to needs of Plugin Directory,
/// but it should be possible to make it more generic in the future if there's a need to — it was deliberately
/// not made as generic as possible, in case it won't be used.

private let CellReuseIdentifier = "CollectionViewContainerRowReuseIdentifier"

struct CollectionViewContainerRow<CollectionViewCellType: UICollectionViewCell, Item>: ImmuTableRow {
    typealias CellType = CollectionViewContainerCell

    static var cell: ImmuTableCell {
        return .class(CollectionViewContainerCell.self)
    }

    let title: String
    var action: ImmuTableAction? = nil
    private let helper: CollectionViewContainerRowHelper

    init(data: [Item],
         title: String,
         configureCollectionCell: @escaping ((CollectionViewCellType, Item) -> Void),
         collectionCellSelected: @escaping ((Item) -> Void)) {

        self.title = title

        let configurationBlock = { (cell: UICollectionViewCell, item: Any) in
            configureCollectionCell(cell as! CollectionViewCellType, item as! Item)
        }

        let selectionBlock = { (item: Any) in
            collectionCellSelected(item as! Item)
        }

        helper = CollectionViewContainerRowHelper(dataSourceItems: data,
                                                  configureCollectionCellBlock: configurationBlock,
                                                  collectionCellSeletectedBlock: selectionBlock)
    }


    func configureCell(_ cell: UITableViewCell) {
        let cell = cell as! CellType

        if nil != Bundle.main.path(forResource: String(describing: CollectionViewCellType.self), ofType: "nib") {
            cell.collectionView.register(UINib(nibName: String(describing: CollectionViewCellType.self), bundle: nil),
                                         forCellWithReuseIdentifier: CellReuseIdentifier)
        } else {
            cell.collectionView.register(CollectionViewCellType.self, forCellWithReuseIdentifier: CellReuseIdentifier)
        }

        cell.titleLabel.text = title

        cell.collectionView.delegate = helper
        cell.collectionView.dataSource = helper
    }


}

/// Generic Swift classes can't be made `@objc`, so we're using this helper object to be a `UICollectionView[DataSource|Delegate]`
@objc private class CollectionViewContainerRowHelper: NSObject, UICollectionViewDelegate, UICollectionViewDataSource {

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
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CellReuseIdentifier, for: indexPath)

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

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }


    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {

        titleLabel = UILabel(frame: .zero)
        titleLabel.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .title2).pointSize,
                                            weight: .bold)
        titleLabel.textColor = WPStyleGuide.darkGrey()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(titleLabel)

        titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 18).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 16).isActive = true

        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        flowLayout.itemSize = CGSize(width: 98, height: 98*2)
        flowLayout.minimumLineSpacing = 16
        flowLayout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .clear

        contentView.addSubview(collectionView)

        collectionView.topAnchor.constraint(equalTo: titleLabel.lastBaselineAnchor, constant: 8).isActive = true
        collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
    }

}
