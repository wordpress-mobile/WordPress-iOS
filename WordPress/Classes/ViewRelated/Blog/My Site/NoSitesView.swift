import SwiftUI

protocol NoSitesViewDelegate: AnyObject {
    func didTapAddNewSiteButton()
    func didTapAccountAndSettingsButton()
}

struct NoSitesView: View {

    @SwiftUI.Environment(\.colorScheme) var colorScheme

    let viewModel: NoSitesViewModel
    weak var delegate: NoSitesViewDelegate?

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(uiColor: .listBackground)
                .edgesIgnoringSafeArea(.all)

            makeMainView()
                .padding(.horizontal, 32)

            if viewModel.isShowingAccountAndSettings {
                makeAccountAndSettingsButton()
                    .padding(.horizontal, 32)
                    .padding(.bottom, 20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func makeMainView() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer()
            Image("pagesCardPromoImage")
                .resizable()
                .scaledToFill()
                .frame(width: 110, height: 80)
                .cornerRadius(5)
            makeTextStackView()
            makeAddNewSiteButton()
            Spacer()
        }
    }

    private func makeTextStackView() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Strings.title)
                .font(.title3.weight(.semibold))
                .foregroundColor(.primary)
            Text(Strings.description)
                .font(.subheadline.weight(.regular))
                .foregroundColor(.secondary)
        }
    }

    private func makeAddNewSiteButton() -> some View {
        Button {
            delegate?.didTapAddNewSiteButton()
        } label: {
            Text(Strings.addNewSite)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .foregroundColor(.white)
                .background(colorScheme == .dark ? Color(uiColor: .listForeground) : .black)
                .cornerRadius(5)
                .font(.callout.weight(.semibold))
        }
    }

    private func makeAccountAndSettingsButton() -> some View {
        Button {
            delegate?.didTapAccountAndSettingsButton()
        } label: {
            HStack(alignment: .center, spacing: 16) {
                makeGravatarIcon(size: 40)
                VStack(alignment: .leading) {
                    Text(viewModel.displayName)
                        .foregroundColor(.primary)
                        .font(.callout.weight(.semibold))
                    Text(Strings.accountAndSettings)
                        .foregroundColor(.secondary)
                        .font(.subheadline.weight(.regular))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .tint(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(uiColor: .listForeground))
            .cornerRadius(10)
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

extension NoSitesView {
    private enum Strings {
        static let title = NSLocalizedString("mySite.noSites.title", value: "You don't have any sites", comment: "Message title for when a user has no sites.")
        static let description = NSLocalizedString("mySite.noSites.description", value: "Create a new site for your business, magazine, or personal blog; or connect an existing WordPress installation.", comment: "Message description for when a user has no sites.")
        static let addNewSite = NSLocalizedString("mySite.noSites.button.addNewSite", value: "Add new site", comment: "Button title. Displays a screen to add a new site when tapped.")
        static let accountAndSettings = NSLocalizedString("mySite.noSites.button.accountAndSettings", value: "Account and settings", comment: "Button title. Displays the account and setting screen.")
    }
}

struct NoSitesView_Previews: PreviewProvider {
    static var previews: some View {
        NoSitesView(viewModel: NoSitesViewModel(account: nil))
    }
}
