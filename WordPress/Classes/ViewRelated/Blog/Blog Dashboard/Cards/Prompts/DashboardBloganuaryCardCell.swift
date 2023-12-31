import SwiftUI

class DashboardBloganuaryCardCell: DashboardCollectionViewCell {

    private var blog: Blog? {
        didSet {
            updateUI()
        }
    }

    private weak var presenterViewController: BlogDashboardViewController?

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
        let isDateWithinEligibleMonths: Bool = {
            let components = date.dateAndTimeComponents()
            guard let month = components.month else {
                return false
            }

            // NOTE: For simplicity, we're going to hardcode the date check if the date is within December or January.
            return Constants.eligibleMonths.contains(month)
        }()

        // Check if the blog is marked as a potential blogging site.
        let isPotentialBloggingSite: Bool = context.performAndWait {
            return (try? BloggingPromptSettings.of(blog))?.isPotentialBloggingSite ?? false
        }

        return isDateWithinEligibleMonths && isPotentialBloggingSite
    }

    func configure(blog: Blog, viewController: BlogDashboardViewController?, apiResponse: BlogDashboardRemoteEntity?) {
        self.blog = blog
        self.presenterViewController = viewController

        BlogDashboardAnalytics.shared.track(.dashboardCardShown,
                                            properties: [
                                                "type": DashboardCard.bloganuaryNudge.rawValue,
                                                "subtype": DashboardCard.bloganuaryNudge.rawValue
                                            ])
    }

    // MARK: Private methods

    @MainActor
    private func updateUI() {
        guard let blog,
              let blogID = blog.dotComID?.intValue else {
            return
        }

        contentView.subviews.forEach { $0.removeFromSuperview() }

        let cardView = BloganuaryNudgeCardView(onLearnMoreTapped: { [weak self] in
            // check if the prompts card is enabled in the dashboard.
            let promptsCardEnabled = BlogDashboardPersonalizationService(siteID: blogID).isEnabled(.prompts)
            let overlayView = BloganuaryOverlayViewController(blogID: blogID, promptsEnabled: promptsCardEnabled)

            let navigationController = UINavigationController(rootViewController: overlayView)
            navigationController.modalPresentationStyle = .formSheet
            if let sheet = navigationController.sheetPresentationController {
                sheet.prefersGrabberVisible = WPDeviceIdentification.isiPhone()
            }

            BloganuaryTracker.trackCardLearnMoreTapped(promptsEnabled: promptsCardEnabled)

            self?.presenterViewController?.present(navigationController, animated: true)
        })

        let hostView = UIView.embedSwiftUIView(cardView)
        let frameView = makeCardFrameView()
        frameView.add(subview: hostView)

        contentView.addSubview(frameView)
        contentView.pinSubviewToAllEdges(frameView)
    }

    private func makeCardFrameView() -> BlogDashboardCardFrameView {
        let frameView = BlogDashboardCardFrameView()
        frameView.translatesAutoresizingMaskIntoConstraints = false
        frameView.configureButtonContainerStackView()

        // NOTE: this is intentionally called *before* configuring the ellipsis button action,
        // to avoid additional trailing padding.
        frameView.hideHeader()

        if let blog {
            frameView.onEllipsisButtonTap = {
                BlogDashboardAnalytics.trackContextualMenuAccessed(for: .bloganuaryNudge)
            }
            frameView.ellipsisButton.showsMenuAsPrimaryAction = true
            let action = BlogDashboardHelpers.makeHideCardAction(for: .bloganuaryNudge, blog: blog)
            frameView.ellipsisButton.menu = UIMenu(title: String(), options: .displayInline, children: [action])
        }

        return frameView
    }

    struct Constants {
        // Only show the card in December and January.
        static let eligibleMonths = [1, 12]
    }
}

// MARK: - SwiftUI

private struct BloganuaryNudgeCardView: View {
    let onLearnMoreTapped: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12.0) {
            bloganuaryImage
                .resizable()
                .frame(width: 24.0, height: 24.0)
            textContainer
            Button {
                onLearnMoreTapped?()
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
            Text(cardTitle)
                .font(.headline)
                .fontWeight(.semibold)
            Text(Strings.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    var cardTitle: String {
        let components = Date().dateAndTimeComponents()
        guard let month = components.month,
              DashboardBloganuaryCardCell.Constants.eligibleMonths.contains(month) else {
            return Strings.title
        }

        return month == 1 ? Strings.runningTitle : Strings.title
    }

    struct Strings {
        static let title = NSLocalizedString(
            "bloganuary.dashboard.card.title",
            value: "Bloganuary is coming!",
            comment: "Title for the Bloganuary dashboard card."
        )

        // The card title string to be shown while Bloganuary is running
        static let runningTitle = NSLocalizedString(
            "bloganuary.dashboard.card.runningTitle",
            value: "Bloganuary is here!",
            comment: "Title for the Bloganuary dashboard card while Bloganuary is running."
        )

        static let description = NSLocalizedString(
            "bloganuary.dashboard.card.description",
            value: "For the month of January, blogging prompts will come from Bloganuary — our community challenge to build a blogging habit for the new year.",
            comment: "Short description for the Bloganuary event, shown right below the title."
        )

        static let cta = NSLocalizedString(
            "bloganuary.dashboard.card.button.learnMore",
            value: "Learn more",
            comment: "Title for a button that, when tapped, shows more info about participating in Bloganuary."
        )
    }
}
