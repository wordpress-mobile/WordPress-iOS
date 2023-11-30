import SwiftUI

class DashboardBloganuaryCardCell: DashboardCollectionViewCell {

    private var blog: Blog? {
        didSet {
            configureEllipsisMenu(for: cardFrameView)
        }
    }

    private lazy var cardFrameView: BlogDashboardCardFrameView = {
        let frameView = BlogDashboardCardFrameView()
        frameView.translatesAutoresizingMaskIntoConstraints = false
        frameView.configureButtonContainerStackView()

        // NOTE: this is intentionally called *before* configuring the ellipsis button action,
        // to avoid additional trailing padding.
        frameView.hideHeader()
        configureEllipsisMenu(for: frameView)

        return frameView
    }()

    /// Checks whether the Bloganuary nudge card should be shown on the dashboard.
    ///
    /// The card is only going to be shown in December, and will be hidden in January.
    /// It's also going to be shown for blogs that are marked as potential blogs by the backend, regardless
    /// of whether the user has manually disabled the blogging prompts.
    ///
    /// - Parameters:
    ///   - blog: The current `Blog` instance.
    ///   - date: The date to check. Defaults to today.
    /// - Returns: `true` if the Bloganuary card should be shown. `false` otherwise.
    static func shouldShowCard(for blog: Blog, date: Date = Date()) -> Bool {
        guard RemoteFeatureFlag.bloganuaryDashboardNudge.enabled(),
              let context = blog.managedObjectContext else {
            return false
        }

        // Check for date eligibility.
        let isDateInDecember: Bool = {
            let components = date.dateAndTimeComponents()
            guard let month = components.month,
                  let year = components.year else {
                return false
            }

            // NOTE: For simplicity, we're going to hardcode the date check if the date is within December 2023.
            // revisit this later so this doesn't have to be changed every year.
            return month == 12 && year == 2023
        }()

        // Check if the blog is marked as a potential blogging site.
        let isPotentialBloggingSite: Bool = context.performAndWait {
            return (try? BloggingPromptSettings.of(blog))?.isPotentialBloggingSite ?? false
        }

        return isDateInDecember && isPotentialBloggingSite
    }

    func configure(blog: Blog, viewController: BlogDashboardViewController?, apiResponse: BlogDashboardRemoteEntity?) {
        self.blog = blog
        // TODO: Tracks for card shown. No extra properties needed.
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        let hostView = UIView.embedSwiftUIView(BloganuaryNudgeCardView())
        cardFrameView.add(subview: hostView)

        contentView.addSubview(cardFrameView)
        contentView.pinSubviewToAllEdges(cardFrameView)
    }

    private func configureEllipsisMenu(for frameView: BlogDashboardCardFrameView) {
        guard let blog else {
            return
        }

        frameView.onEllipsisButtonTap = { }
        frameView.ellipsisButton.showsMenuAsPrimaryAction = true
        let action = BlogDashboardHelpers.makeHideCardAction(for: .bloganuaryNudge, blog: blog)
        frameView.ellipsisButton.menu = UIMenu(title: String(), options: .displayInline, children: [action])
    }
}

// MARK: - SwiftUI

private struct BloganuaryNudgeCardView: View {

    var body: some View {
        VStack(alignment: .leading, spacing: 12.0) {
            bloganuaryImage
                .resizable()
                .frame(width: 24.0, height: 24.0)
            textContainer
            Button {
                // TODO: Show the Learn More modal.
            } label: {
                Text(Strings.cta)
                    .font(.subheadline)
            }
        }
        .padding(.top, 12.0)
        .padding([.horizontal, .bottom], 16.0)
    }

    var bloganuaryImage: Image {
        if let uiImage = UIImage(named: "logo-bloganuary")?.withRenderingMode(.alwaysTemplate).withTintColor(.label) {
            return Image(uiImage: uiImage)
        }
        return Image("logo-bloganuary", bundle: .main)
    }

    var textContainer: some View {
        VStack(alignment: .leading, spacing: 8.0) {
            Text(Strings.title)
                .font(.headline)
                .fontWeight(.semibold)
            Text(Strings.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    struct Strings {
        static let title = NSLocalizedString(
            "bloganuary.dashboard.card.title",
            value: "Bloganuary is coming!",
            comment: "Title for the Bloganuary dashboard card."
        )

        static let description = NSLocalizedString(
            "bloganuary.dashboard.card.description",
            value: """
            For the month of January, blogging prompts will come from Bloganuary - \
            our community challenge to build a blogging habit for the new year.
            """,
            comment: "Short description for the Bloganuary event, shown right below the title."
        )

        static let cta = NSLocalizedString(
            "bloganuary.dashboard.card.button.learnMore",
            value: "Learn more",
            comment: "Title for a button that, when tapped, shows more info about participating in Bloganuary."
        )
    }
}
