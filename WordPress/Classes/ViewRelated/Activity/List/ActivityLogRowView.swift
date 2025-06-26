import SwiftUI
import WordPressUI
import WordPressKit

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

                Text(viewModel.title.isEmpty ? "—" : viewModel.title)
                    .font(.subheadline)
                    .lineLimit(2)
                    .foregroundColor(viewModel.title.isEmpty ? .secondary : .primary)

                if let actor = viewModel.activity.actor {
                    HStack(spacing: 6) {
                        ActivityActorAvatarView(actor: actor, diameter: 16)
                        HStack(spacing: 4) {
                            Text(actor.displayName.isEmpty ? Activity.Strings.unknownUser : actor.displayName)
                                .font(.footnote)
                                .foregroundColor(.secondary)
                            if let subtitle = viewModel.actorSubtitle {
                                Text("·")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                Text(subtitle)
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
