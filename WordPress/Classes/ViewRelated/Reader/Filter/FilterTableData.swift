import WordPressUI

struct TableDataItem {
    let topic: ReaderAbstractTopic
    let configure: (UITableViewCell) -> Void
}

class FilterTableViewDataSource: NSObject, UITableViewDataSource {

    let data: [TableDataItem]
    private let reuseIdentifier: String

    init(data: [TableDataItem], reuseIdentifier: String) {
        self.data = data
        self.reuseIdentifier = reuseIdentifier
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = data[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)

        item.configure(cell)

        return cell
    }
}

class SiteTableViewCell: UITableViewCell, GhostableView {

    enum Constants {
        static let preferredSiteIconSize = CGSize(width: 40.0, height: 40.0)
        static let textLabelCharacterWidth = 40 // Number of characters in text label
        static let detailLabelCharacterWidth = 80 // Number of characters in detail label
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        configureStyle()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureStyle() {
        imageView?.image = .siteIconPlaceholder
        imageView?.layer.masksToBounds = true
        imageView?.contentMode = .scaleAspectFill

        textLabel?.font = UIFont.preferredFont(forTextStyle: .callout)
        textLabel?.textColor = .text

        detailTextLabel?.font = UIFont.preferredFont(forTextStyle: .footnote)
        detailTextLabel?.textColor = .textSubtle
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        guard let imageView else {
            return
        }

        // check if the image has a larger width than intended.
        let extraWidth = imageView.frame.width - Constants.preferredSiteIconSize.width

        // when there's extra width, UITableViewCell automatically adjusts the label position.
        // let's shift the labels back by that much.
        if extraWidth > 0 {
            // Note: for RTL, we want to make sure that we're shifting the views to the correct direction.
            textLabel?.frame.origin.x += traitCollection.layoutDirection == .leftToRight ? (-1 * extraWidth) : extraWidth
            detailTextLabel?.frame.origin.x += traitCollection.layoutDirection == .leftToRight ? (-1 * extraWidth) : extraWidth

            if traitCollection.layoutDirection == .rightToLeft {
                imageView.frame.origin.x += extraWidth
            }
        }

        imageView.frame.size = Constants.preferredSiteIconSize
        imageView.layer.cornerRadius = imageView.frame.height * 0.5
    }

    func ghostAnimationWillStart() {
        contentView.subviews.forEach { view in
            view.isGhostableDisabled = true
        }
        textLabel?.text = String(repeating: " ", count: Constants.textLabelCharacterWidth)
        textLabel?.isGhostableDisabled = false
        detailTextLabel?.text = String(repeating: " ", count: Constants.detailLabelCharacterWidth)
        detailTextLabel?.isGhostableDisabled = false
    }
}
