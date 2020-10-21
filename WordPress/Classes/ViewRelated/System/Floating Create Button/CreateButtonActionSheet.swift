/// The Action Sheet containing action buttons to create new content to be displayed from the Create Button.
class CreateButtonActionSheet: ActionSheetViewController {

    enum Constants {
        static let title = NSLocalizedString("Create New", comment: "Create New header text")

        enum Badge {
            static let font = UIFont.preferredFont(forTextStyle: .caption1)
            static let insets = UIEdgeInsets(top: 2, left: 8, bottom: 2, right: 8)
            static let cornerRadius: CGFloat = 2
            static let backgroundColor = UIColor.muriel(color: MurielColor(name: .red, shade: .shade50))
        }
    }

    init(newPost: @escaping () -> Void, newPage: @escaping () -> Void, newStory: (() -> Void)?) {
        let postsButton = CreateButtonActionSheet.makePostsButton(handler: newPost)
        let pagesButton = CreateButtonActionSheet.makePagesButton(handler: newPage)
        let storiesButton = CreateButtonActionSheet.makeStoriesButton(handler: { newStory?() })
        let shouldShowStories = newStory != nil
        let buttons = shouldShowStories ? [postsButton, pagesButton, storiesButton] : [postsButton, pagesButton]

        super.init(headerTitle: Constants.title, buttons: buttons)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Button Constructors

    private static func makePostsButton(handler: @escaping () -> Void) -> ActionSheetButton {
        let highlight: Bool = QuickStartTourGuide.find()?.shouldSpotlight(.newpost) ?? false

        return ActionSheetButton(title: NSLocalizedString("Blog post", comment: "Create new Blog Post button title"),
                                 image: .gridicon(.posts),
                                 identifier: "blogPostButton",
                                 highlight: highlight,
                                 action: handler)
    }

    private static func makePagesButton(handler: @escaping () -> Void) -> ActionSheetButton {
        return ActionSheetButton(title: NSLocalizedString("Site page", comment: "Create new Site Page button title"),
                                            image: .gridicon(.pages),
                                            identifier: "sitePageButton",
                                            action: handler)
    }

    private static func makeStoriesButton(handler: @escaping () -> Void) -> ActionSheetButton {
        let badge = CreateButtonActionSheet.newBadge(title: NSLocalizedString("New", comment: "New button badge on Stories Post button"))
        return ActionSheetButton(title: NSLocalizedString("Story post", comment: "Create new Story button title"),
                                            image: .gridicon(.book),
                                            identifier: "storyButton",
                                            badge: badge,
                                            action: handler)
    }

    private static func newBadge(title: String) -> UIButton {
        let badge = UIButton(type: .custom)
        badge.translatesAutoresizingMaskIntoConstraints = false
        badge.setTitle(title, for: .normal)
        badge.titleLabel?.font = Constants.Badge.font
        badge.contentEdgeInsets = Constants.Badge.insets
        badge.layer.cornerRadius = Constants.Badge.cornerRadius
        badge.isUserInteractionEnabled = false
        badge.backgroundColor = Constants.Badge.backgroundColor
        return badge
    }
}
