import SwiftUI
import DesignSystem
import WordPressUI

protocol NoSitesViewDelegate: AnyObject {
    func didTapAccountAndSettingsButton()
}

struct NoSitesView: View {
    let addSiteViewModel: AddSiteMenuViewModel
    let viewModel: NoSitesViewModel
    weak var delegate: NoSitesViewDelegate?

    /// Whether the view is shown in an expanded split view, where the sidebar links to the account.
    var isInExpandedSplitView = false

    var body: some View {
        ZStack {
            VStack {
                emptyStateView
                    .frame(maxHeight: .infinity, alignment: .center)

                if viewModel.isShowingAccountAndSettings, !isInExpandedSplitView {
                    accountAndSettingsButton
                        .padding(.horizontal, .DS.Padding.large)
                        .padding(.bottom, .DS.Padding.medium)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyStateView: some View {
        EmptyStateView {
            Label(Strings.title, image: "noSitesEmptyStateImage")
        } description: {
            Text(Strings.description)
        } actions: {
            VStack(spacing: 20) {
                ForEach(addSiteViewModel.actions) { action in
                    let button = Button(action.title) {
                        WPAnalytics.track(.mySiteNoSitesViewActionTapped)
                        action.handler()
                    }
                    if action.id == addSiteViewModel.actions.first?.id {
                        button.buttonStyle(.primary)
                    } else {
                        button
                    }
                }
            }
        }
    }

    private var accountAndSettingsButton: some View {
        Button {
            delegate?.didTapAccountAndSettingsButton()
        } label: {
            HStack(alignment: .center, spacing: .DS.Padding.double) {
                makeGravatarIcon(size: 40)
                accountAndSettingsStackView
                Spacer()
                Image(systemName: "chevron.forward")
                    .tint(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(10)
        }
    }

    private var accountAndSettingsStackView: some View {
        VStack(alignment: .leading) {
            Text(viewModel.displayName)
                .foregroundColor(.primary)
                .font(.callout.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text(Strings.accountAndSettings)
                .foregroundColor(.secondary)
                .font(.subheadline.weight(.regular))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
    }

    private func makeGravatarIcon(size: CGFloat) -> some View {
        AsyncImage(url: viewModel.gravatarURL) { phase in
            switch phase {
            case .success(let image):
                image.resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            default:
                Image(uiImage: .gridicon(.userCircle, size: CGSize(width: size, height: size)))
                    .tint(.secondary)
            }
        }
    }
}

/// Hosts `NoSitesView` and keeps `isInExpandedSplitView` up to date.
final class NoSitesHostingController: UIHostingController<NoSitesView> {
    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        updateIsInExpandedSplitView()
    }

    /// The split view collapses or expands after its size class changes, so a trait change
    /// callback still sees the old `isCollapsed`. Layout runs after it has updated.
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        updateIsInExpandedSplitView()
    }

    private func updateIsInExpandedSplitView() {
        let isInExpandedSplitView = splitViewController?.isCollapsed == false
        if rootView.isInExpandedSplitView != isInExpandedSplitView {
            rootView.isInExpandedSplitView = isInExpandedSplitView
        }
    }
}

private enum Strings {
    static let title = NSLocalizedString(
        "mySite.noSites.stateViewTitle",
        value: "Create Your First Site",
        comment: "Title description for when a user has no sites."
    )
    static let description = NSLocalizedString(
        "mySite.noSites.description",
        value:
            "Create a new site for your business, magazine, or personal blog; or connect an existing WordPress installation.",
        comment: "Message description for when a user has no sites."
    )
    static let accountAndSettings = NSLocalizedString(
        "mySite.noSites.button.accountAndSettings",
        value: "Account and settings",
        comment: "Button title. Displays the account and setting screen."
    )
}
