import SwiftUI
import AsyncImageKit

/// A view component that displays a user profile banner with avatar, name, and email address.
/// Tapping on the banner allows the user to modify their details.
public struct ProfileView: View {

    public typealias Callback = () -> Void

    private let name: String
    private let email: String
    private let avatarImage: Image?
    private let avatarImageUrl: URL?
    private let onTap: Callback?

    /// Initialize a new ProfileView
    /// - Parameters:
    ///   - name: The user's display name
    ///   - email: The user's email address
    ///   - avatarImage: Optional image to display as the user's avatar
    ///   - onTap: Action to perform when the profile banner is tapped
    public init(
        name: String,
        email: String,
        avatarImage: Image? = nil,
        onTap: Callback? = nil
    ) {
        self.name = name
        self.email = email
        self.avatarImage = avatarImage
        self.avatarImageUrl = nil
        self.onTap = onTap
    }

    public init(user: SupportUser, onTap: Callback? = nil) {
        self.name = user.username
        self.email = user.email
        self.avatarImage = nil
        self.avatarImageUrl = user.avatarUrl
        self.onTap = onTap
    }

    public var body: some View {
        Button(action: self.didTapProfile) {
            VStack(alignment: .leading) {
                HStack(spacing: 16) {
                    Group {
                        if let avatarImage {
                            avatarImage
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .clipShape(Circle())
                        } else if let avatarImageUrl {
                            CachedAsyncImage(url: avatarImageUrl) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 60)
                                    .clipShape(Circle())
                            } placeholder: {
                                ProgressView()
                            }.frame(width: 60, height: 60)
                        } else {
                            ZStack {
                                Circle()
                                    .fill(Color.secondary.opacity(0.2))
                                    .frame(width: 60, height: 60)

                                Image(systemName: "person.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }.frame(width: 60, height: 60)

                    // User details
                    VStack(alignment: .leading, spacing: 4) {
                        Text(name)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        Text(email)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func didTapProfile() {
        self.onTap?()
    }
}

#Preview("List") {
    List {
        Section {
            ProfileView(
                name: "Jane Smith",
                email: "jane.smith@example-corporation.com",
                onTap: {}
            )
        }
    }
}

#Preview("Standalone") {
    ProfileView(
        name: "John Doe",
        email: "john.doe@example.com",
        onTap: {}
    )
    .padding()
    .background(Color.gray.opacity(0.1))
}

#Preview("Specific Image") {
    ProfileView(user: SupportUser(
        userId: 1234,
        username: "Alice Roe",
        email: "alice.roe@example.com",
        avatarUrl: URL(string: "https://docs.gravatar.com/wp-content/uploads/2025/02/avatar-default-20250210-256.png")!))
}
