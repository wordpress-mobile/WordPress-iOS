import UIKit


@objc class BloggingRemindersCell: UITableViewCell {
    @objc static let reuseIdentifier = "BloggingRemindersCell"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none

        /// - TODO: inject actions here
        let bloggingRemindersCardView = UIView.embedSwiftUIView(BloggingRemindersCard(getStartedButtonAction: {
            let blogService = BlogService(managedObjectContext: ContextManager.shared.mainContext)
            guard let blog = blogService.lastUsedOrFirstBlog(), let controller = self.window?.rootViewController else {
                return
            }

            BloggingRemindersFlow.present(from: controller, for: blog, source: .blogSettings)
        }, ellipsisButtonAction: {}))
        bloggingRemindersCardView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(bloggingRemindersCardView)
        contentView.pinSubviewToAllEdges(bloggingRemindersCardView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


extension BlogDetailsViewController {
    static let rowAccessibilityIdentifier = "BloggingRemindersCard"

    @objc func bloggingRemindersSectionViewModel() -> BlogDetailsSection {
        var rows = [Any]()
        rows.append(BlogDetailsRow(title: "",
                                   identifier: BloggingRemindersCell.reuseIdentifier,
                                   accessibilityIdentifier: Self.rowAccessibilityIdentifier,
                                   accessibilityHint: nil,
                                   image: UIImage(),
                                   callback: {}))

        return BlogDetailsSection(title: nil, andRows: rows, category: .reminders)
    }

    @objc var shouldShowBloggingRemindersCard: Bool {
        get {
            FeatureFlag.bloggingReminders.enabled && UserDefaults.standard.showBloggingRemindersCard
        }

        set {
            UserDefaults.standard.showBloggingRemindersCard = newValue
        }
    }
}


private extension UserDefaults {

    private static let showBloggingRemindersCardKey = "showBloggingRemindersCardKey"

    var showBloggingRemindersCard: Bool {
        get {
            if object(forKey: UserDefaults.showBloggingRemindersCardKey) == nil {
                set(true, forKey: UserDefaults.showBloggingRemindersCardKey)
            }
            return bool(forKey: UserDefaults.showBloggingRemindersCardKey)
        }
        set {
            set(newValue, forKey: UserDefaults.showBloggingRemindersCardKey)
        }
    }
}
