import SwiftUI
import WordPressUI

struct ActivityLogRowView: View {
    let viewModel: ActivityLogRowViewModel

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            icon

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(viewModel.subtitle)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(viewModel.time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Text(viewModel.title)
                    .font(.subheadline)
                    .lineLimit(2)

                if let actor = viewModel.actor {
                    HStack(spacing: 6) {
                        avatar
                        HStack(spacing: 4) {
                            Text(actor)
                                .font(.footnote)
                                .foregroundColor(.secondary)
                            if let role = viewModel.actorRole {
                                Text("·")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                Text(role)
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
    }

    private var avatar: some View {
        Group {
            if let avatarURL = viewModel.actorAvatarURL {
                AvatarView(style: .single(avatarURL), diameter: 16)
            } else if viewModel.actor?.lowercased() == "jetpack" {
                Image("icon-jetpack")
                    .resizable()
            } else {
                Circle()
                    .fill(Color(.secondarySystemBackground))
                    .overlay(
                        Text((viewModel.actor ?? "").prefix(1).uppercased())
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.secondary)
                    )
            }
        }
        .frame(width: 16, height: 16)
    }

    private var icon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(viewModel.tintColor.opacity(0.15))
                .frame(width: 36, height: 36)

            if let iconImage = viewModel.icon {
                Image(uiImage: iconImage)
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
                    .foregroundColor(viewModel.tintColor)
            }
        }
    }
}
