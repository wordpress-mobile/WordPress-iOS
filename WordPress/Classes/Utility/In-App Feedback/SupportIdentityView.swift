import SwiftUI
import Gravatar

struct SupportIdentityView: View {

    let name: String
    let email: String

    private let profilePictureUrl: URL?

    init(name: String?, email: String?) {
        self.name = name ?? "Unknown Name"
        self.email = email ?? "Unknown Email"
        self.profilePictureUrl = ProfileURL(with: ProfileIdentifier.email(self.email))?.avatarURL?.url
    }

    var body: some View {
        NavigationLink {
            // TODO
        } label: {
            VStack(alignment: .leading) {
                Text("Support Profile").font(.headline)
                HStack(alignment: .top) {

                    if let url = self.profilePictureUrl {
                        AsyncImage(url: url, content: {
                            $0.resizable().clipShape(.rect(cornerRadius: 5))
                        }, placeholder: {
                            ProgressView()
                        }).frame(width: 32, height: 32)
                    } else {
                        Image(systemName: "person.crop.circle.fill").frame(width: 32, height: 32)
                    }

                    VStack(alignment: .leading) {
                        Text(name)
                            .font(.caption)
                        Text(email)
                            .font(.caption)
                    }
                }
            }
        }
    }

    private enum Strings {
        static let support_profile_title = NSLocalizedString("support.zendesk.support_profile_label", value: "Support Profile", comment: "The label for a button that allows a user to modify their support profile")
    }
}

#Preview {
    SupportIdentityView(name: "John Appleseed", email: "john.appleseed@example.com")
}
