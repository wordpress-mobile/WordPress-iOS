import UIKit
import Gridicons

/// Displays a simple table view picker list to choose between author filters
/// for a post.
///
class AuthorFilterViewController: UITableViewController {
    private typealias AuthorFilter = PostListFilterSettings.AuthorFilter

    /// An optional gravatar email address. If provided, this will be used to
    /// display a gravatar icon alongside the "Only Me" posts
    var gravatarEmail: String? = nil

    /// The currently selected author filer
    var currentSelection: PostListFilterSettings.AuthorFilter

    /// An optional block, which will be called whenever the user selects an
    /// item in the filter list.
    var onSelectionChanged: ((PostListFilterSettings.AuthorFilter) -> Void)? = nil

    private var selectedIndexPath: IndexPath? {
        guard let row = rows.firstIndex(of: currentSelection) else {
            return nil
        }

        return IndexPath(row: row, section: 0)
    }

    private let rows = [
        AuthorFilter.mine,
        AuthorFilter.everyone
    ]

    private let postType: PostServiceType

    init(initialSelection: PostListFilterSettings.AuthorFilter,
         gravatarEmail: String? = nil,
         postType: PostServiceType,
         onSelectionChanged: ((PostListFilterSettings.AuthorFilter) -> Void)? = nil) {

        self.gravatarEmail = gravatarEmail
        self.onSelectionChanged = onSelectionChanged
        self.currentSelection = initialSelection
        self.postType = postType

        super.init(style: .grouped)

        tableView.register(AuthorFilterCell.self, forCellReuseIdentifier: Identifiers.authorFilterCell)

        tableView.rowHeight = Metrics.rowHeight
        tableView.separatorInset = .zero
        tableView.separatorColor = .clear
        tableView.isScrollEnabled = false
        tableView.showsVerticalScrollIndicator = false
        tableView.contentInset = .zero
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var preferredContentSize: CGSize {
        set {}
        get {
            let height = CGFloat(tableView(self.tableView, numberOfRowsInSection: 0)) * Metrics.rowHeight
            return CGSize(width: Metrics.preferredWidth, height: height)
        }
    }

    // MARK: - Table View Delegate / Data Source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.authorFilterCell, for: indexPath) as! AuthorFilterCell

        if let filter = PostListFilterSettings.AuthorFilter(rawValue: UInt(indexPath.row)) {
            switch filter {
            case .everyone:
                cell.filterType = .everyone
            case .mine:
                cell.filterType = .user(gravatarEmail: gravatarEmail)
            }
            cell.title = makeTitle(for: filter)
            cell.separatorIsHidden = indexPath.row != 0
        }

        return cell
    }

    private func makeTitle(for filter: PostListFilterSettings.AuthorFilter) -> String {
        switch postType {
        case .post:
            switch filter {
            case .mine: return Strings.postsByMe
            case .everyone: return Strings.postsByEveryone
            }
        case .page:
            switch filter {
            case .mine: return Strings.pagesByMe
            case .everyone: return Strings.pagesByEveryone
            }
        default:
            fatalError("Unsupported post type: \(postType)")
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let filter = PostListFilterSettings.AuthorFilter(rawValue: UInt(indexPath.row)) else {
            return
        }

        if let selectedIndexPath = selectedIndexPath {
            setRow(at: selectedIndexPath, selected: false)
        }

        currentSelection = filter

        setRow(at: indexPath, selected: true)

        onSelectionChanged?(filter)
    }

    private func setRow(at indexPath: IndexPath, selected: Bool) {
        if let cell = tableView.cellForRow(at: indexPath) as? AuthorFilterCell {
            cell.accessoryType = selected ? .checkmark : .none
        }
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        // Prevents extra separators being drawn at the bottom of the table
        return UIView()
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return Metrics.topinset
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: Metrics.topinset))
        view.backgroundColor = .listForeground
        return view
    }

    // MARK: - Constants

    private enum Identifiers {
        static let authorFilterCell: String = "AuthorFilterCell"
    }

    private enum Metrics {
        static let rowHeight: CGFloat = 44.0
        static let preferredWidth: CGFloat = 220.0
        static let topinset: CGFloat = 13.0
    }
}

/// Table cell used in the authors filter table. Displays a text label and
/// an optional gravatar in a circular image view.
///
private class AuthorFilterCell: UITableViewCell {
    private let gravatarImageView: CircularImageView = {
        let imageView = CircularImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        imageView.tintColor = Appearance.placeholderTintColor
        return imageView
    }()

    private let titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = Fonts.titleFont
        titleLabel.textColor = .label
        return titleLabel
    }()

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = Metrics.stackViewSpacing
        return stackView
    }()

    private let separator: UIView = {
        let separator = UIView()
        separator.backgroundColor = .divider
        separator.translatesAutoresizingMaskIntoConstraints = false
        return separator
    }()

    var title: String = "" {
        didSet {
            titleLabel.text = title
        }
    }

    var separatorIsHidden: Bool = false {
        didSet {
            separator.isHidden = separatorIsHidden
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(stackView)
        contentView.addSubview(separator)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Metrics.horizontalPadding),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Metrics.horizontalPadding),
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            gravatarImageView.widthAnchor.constraint(equalToConstant: Metrics.gravatarSize.width),
            gravatarImageView.heightAnchor.constraint(equalToConstant: Metrics.gravatarSize.height),
        ])

        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(gravatarImageView)

        NSLayoutConstraint.activate([
            separator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: .hairlineBorderWidth)
        ])

        tintColor = .primary(.shade40)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var filterType: AuthorFilterType = .everyone {
        didSet {
            switch filterType {
            case .everyone:
                gravatarImageView.image = UIImage(named: "icon-people")
                gravatarImageView.contentMode = .center
                accessibilityHint = NSLocalizedString("Select to show everyone's posts.", comment: "Voiceover accessibility hint, informing the user they can select an item to show posts written by all users on the site")
            case .user(let email):
                gravatarImageView.contentMode = .scaleAspectFill

                let placeholder = UIImage(named: "comment-author-gravatar")
                if let email = email {
                    gravatarImageView.downloadGravatarWithEmail(email, placeholderImage: placeholder ?? UIImage())
                } else {
                    gravatarImageView.image = placeholder
                }

                accessibilityHint = NSLocalizedString("Select to just show my posts.", comment: "Voiceover accessibility hint, informing the user they can select an item to filter a list of posts to show only their own posts.")
            }
        }
    }

    // MARK: - Constants

    private enum Fonts {
        static let titleFont = UIFont.systemFont(ofSize: 17)
    }

    private enum Appearance {
        static let placeholderTintColor = UIColor.neutral(.shade70)
    }

    private enum Metrics {
        static let stackViewSpacing: CGFloat = 10
        static let horizontalPadding: CGFloat = 16
        static let gravatarSize = CGSize(width: 24, height: 24)
    }
}

private enum Strings {
    static let postsByMe = NSLocalizedString("postsList.postsByMe", value: "Posts by me", comment: "Menu option for filtering posts by me")
    static let postsByEveryone = NSLocalizedString("postsList.postsByEveryone", value: "Posts by everyone", comment: "Menu option for filtering posts by everyone")
    static let pagesByMe = NSLocalizedString("pagesList.pagesByMe", value: "Pages by me", comment: "Menu option for filtering posts by me")
    static let pagesByEveryone = NSLocalizedString("pagesList.pagesByEveryone", value: "Pages by everyone", comment: "Menu option for filtering posts by everyone")
}
