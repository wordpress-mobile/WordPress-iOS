import SwiftUI
import DesignSystem

protocol NoSitesViewDelegate: AnyObject {
    func didTapAccountAndSettingsButton()
}

struct AddNewSiteConfiguration {
    let canCreateWPComSite: Bool
    let canAddSelfHostedSite: Bool
    let launchSiteCreation: () -> Void
    let launchLoginForSelfHostedSite: () -> Void
}

struct NoSitesView: View {

    @SwiftUI.Environment(\.colorScheme) var colorScheme

    @State private var isShowingDialog = false

    let viewModel: NoSitesViewModel
    let addNewSiteConfiguration: AddNewSiteConfiguration

    weak var delegate: NoSitesViewDelegate?

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(uiColor: .listBackground)
                .edgesIgnoringSafeArea(.all)

            mainView
                .padding(.horizontal, Length.Padding.large)

            if viewModel.isShowingAccountAndSettings {
                accountAndSettingsButton
                    .padding(.horizontal, Length.Padding.large)
                    .padding(.bottom, Length.Padding.medium)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var mainView: some View {
        VStack(alignment: .leading, spacing: Length.Padding.double) {
            Spacer()
            Image("noSitesEmptyStateImage")
                .resizable()
                .scaledToFill()
                .frame(width: 210, height: 120)
                .cornerRadius(5)
            textStackView
            addNewSiteButton
                .padding(.bottom, 80)
            Spacer()
        }
    }

    private var textStackView: some View {
        VStack(alignment: .leading, spacing: Length.Padding.single) {
            Text(Strings.title)
                .font(.title3.weight(.semibold))
                .foregroundColor(.primary)
            Text(Strings.description)
                .font(.subheadline.weight(.regular))
                .foregroundColor(.secondary)
        }
    }

    private var addNewSiteButton: some View {
        Button {
            handleAddNewSiteButtonTapped()
        } label: {
            Text(Strings.addNewSite)
                .padding(.horizontal, Length.Padding.medium)
                .padding(.vertical, Length.Padding.single)
                .foregroundColor(.white)
                .background(colorScheme == .dark ? Color(uiColor: .listForeground) : .black)
                .cornerRadius(5)
                .font(.callout.weight(.semibold))
        }
        .confirmationDialog("", isPresented: $isShowingDialog) {
            addNewSitesDialog
        }
    }

    private var accountAndSettingsButton: some View {
        Button {
            delegate?.didTapAccountAndSettingsButton()
        } label: {
            HStack(alignment: .center, spacing: Length.Padding.double) {
                makeGravatarIcon(size: 40)
                accountAndSettingsStackView
                Spacer()
                Image(systemName: "chevron.right")
                    .tint(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(uiColor: .listForeground))
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

// MARK: - Add new site

extension NoSitesView {

    /// If the account can't add a self-hosted site, launch site creation for a WordPress.com site.
    /// Otherwise, show options to create a WordPress.com site or add a self-hosted site.
    ///
    /// In compact size classes, the system shows a dialog sheet with a cancel button.
    /// In regular size classes, the system shows a popover without a cancel button.
    ///
    func handleAddNewSiteButtonTapped() {
        WPAnalytics.track(.mySiteNoSitesViewActionTapped)

        guard addNewSiteConfiguration.canCreateWPComSite else {
            return
        }

        guard addNewSiteConfiguration.canAddSelfHostedSite else {
            addNewSiteConfiguration.launchSiteCreation()
            return
        }

        self.isShowingDialog = true
    }

    @ViewBuilder private var addNewSitesDialog: some View {
        Button(Strings.createWPComSite) {
            addNewSiteConfiguration.launchSiteCreation()
        }
        Button(Strings.addSelfHostedSite) {
            addNewSiteConfiguration.launchLoginForSelfHostedSite()
        }
    }
}

extension NoSitesView {
    private enum Strings {
        static let title = NSLocalizedString("mySite.noSites.title", value: "You don't have any sites", comment: "Message title for when a user has no sites.")
        static let description = NSLocalizedString("mySite.noSites.description", value: "Create a new site for your business, magazine, or personal blog; or connect an existing WordPress installation.", comment: "Message description for when a user has no sites.")
        static let addNewSite = NSLocalizedString("mySite.noSites.button.addNewSite", value: "Add new site", comment: "Button title. Displays a screen to add a new site when tapped.")
        static let accountAndSettings = NSLocalizedString("mySite.noSites.button.accountAndSettings", value: "Account and settings", comment: "Button title. Displays the account and setting screen.")
        static let createWPComSite = NSLocalizedString("mySite.noSites.actionSheet.createWPComSite", value: "Create WordPress.com site", comment: "Action sheet button title. Launches the flow to create a WordPress.com site.")
        static let addSelfHostedSite = NSLocalizedString("mySite.noSites.actionSheet.addSelfHostedSite", value: "Add self-hosted site", comment: "Action sheet button title. Launches the flow to a add self-hosted site.")
    }
}

struct NoSitesView_Previews: PreviewProvider {
    static var previews: some View {
        let configuration = AddNewSiteConfiguration(
            canCreateWPComSite: true,
            canAddSelfHostedSite: true,
            launchSiteCreation: {},
            launchLoginForSelfHostedSite: {}
        )
        NoSitesView(
            viewModel: NoSitesViewModel(appUIType: .simplified, account: nil),
            addNewSiteConfiguration: configuration
        )
    }
}
