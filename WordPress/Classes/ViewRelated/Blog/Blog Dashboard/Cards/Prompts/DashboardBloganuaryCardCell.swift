import SwiftUI

class DashboardBloganuaryCardCell: DashboardCollectionViewCell {

    private var blog: Blog?

    private lazy var cardFrameView: BlogDashboardCardFrameView = {
        let frameView = BlogDashboardCardFrameView()
        frameView.translatesAutoresizingMaskIntoConstraints = false
        frameView.configureButtonContainerStackView()

        // NOTE: this is intentionally called *before* setting the ellipsis button action,
        // to avoid additional trailing padding.
        frameView.hideHeader()

        if let blog {
            frameView.onEllipsisButtonTap = { }
            frameView.ellipsisButton.showsMenuAsPrimaryAction = true
            let action = BlogDashboardHelpers.makeHideCardAction(for: .bloganuaryNudge, blog: blog)
            frameView.ellipsisButton.menu = UIMenu(title: String(), options: .displayInline, children: [action])
        }

        return frameView
    }()

    static func shouldShowCard() -> Bool {
        guard RemoteFeatureFlag.bloganuaryDashboardNudge.enabled() else {
            return false
        }

        // TODO: Check if date is within December 2023.
        // TODO: Further check if prompts can be enabled.
        return true
    }

    func configure(blog: Blog, viewController: BlogDashboardViewController?, apiResponse: BlogDashboardRemoteEntity?) {
        self.blog = blog

        let hostView = UIView.embedSwiftUIView(BloganuaryNudgeCardView())
        cardFrameView.add(subview: hostView)

        contentView.addSubview(cardFrameView)
        contentView.pinSubviewToAllEdges(cardFrameView)

        // TODO: Tracks for card shown. No extra properties needed.
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
        .padding([.leading, .bottom, .trailing], 16.0)
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
