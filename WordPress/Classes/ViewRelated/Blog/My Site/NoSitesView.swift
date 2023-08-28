import SwiftUI

protocol NoSitesViewDelegate: AnyObject {
    func didTapAddNewSiteButton()
}

final class NoSitesViewConfiguration {
    weak var delegate: NoSitesViewDelegate?
}

struct NoSitesView: View {

    let configuration: NoSitesViewConfiguration

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            Image("pagesCardPromoImage")
                .cornerRadius(4)

            Text(Strings.title)
                .font(.headline)
                .foregroundColor(.primary)

            Text(Strings.description)
                .font(.subheadline)
                .foregroundColor(.secondary)

            addNewSiteButton
        }
        .padding(30)
    }

    var addNewSiteButton: some View {
        Button(Strings.addNewSite) {
            configuration.delegate?.didTapAddNewSiteButton()
        }
        .buttonStyle(.borderedProminent)
        .tint(.black)
        .font(.subheadline.weight(.semibold))
    }
}

extension NoSitesView {
    private enum Strings {
        static let title = NSLocalizedString("mySite.noSites.title", value: "You don't have any sites", comment: "Message title for when a user has no sites.")
        static let description = NSLocalizedString("mySite.noSites.description", value: "Create a new site for your business, magazine, or personal blog; or connect an existing WordPress installation.", comment: "Message description for when a user has no sites.")
        static let addNewSite = NSLocalizedString("mySite.noSites.button.addNewSite", value: "Add new site", comment: "Button title. Displays a screen to add a new site when tapped.")
    }
}

struct NoSitesView_Previews: PreviewProvider {
    static var previews: some View {
        NoSitesView(configuration: NoSitesViewConfiguration())
    }
}
