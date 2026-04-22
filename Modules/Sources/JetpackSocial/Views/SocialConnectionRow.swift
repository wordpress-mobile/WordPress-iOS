import SwiftUI

struct SocialConnectionRow: View {
    let connection: SocialConnection

    var body: some View {
        HStack(spacing: 12) {
            avatar
            VStack(alignment: .leading, spacing: 2) {
                Text(connection.displayName)
                    .font(.body)
                HStack(spacing: 6) {
                    Text(connection.serviceLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if connection.isShared {
                        Text(Strings.ManageConnections.sharedBadge)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.15), in: Capsule())
                    }
                }
            }
            Spacer()
            if connection.status.isBroken {
                Text(Strings.ManageConnections.brokenStatus)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    private var avatar: some View {
        profileImage
            .frame(width: 42, height: 42)
            .clipShape(Circle())
            .overlay(alignment: .bottomTrailing) {
                serviceBadge
                    .offset(x: 4, y: 4)
            }
    }

    @ViewBuilder
    private var profileImage: some View {
        if let url = connection.profilePictureURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    Color.secondary.opacity(0.15)
                }
            }
        } else {
            Color.secondary.opacity(0.15)
        }
    }

    @ViewBuilder
    private var serviceBadge: some View {
        if let icon = SocialServiceIcon.image(forServiceID: connection.serviceName) {
            icon
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .padding(2)
                .background(Circle().fill(Color(.systemBackground)))
        }
    }
}
