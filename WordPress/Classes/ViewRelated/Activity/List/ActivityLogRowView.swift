import SwiftUI
import WordPressUI
import WordPressKit

struct ActivityLogRowView: View {
    let viewModel: ActivityLogRowViewModel

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            icon
                .offset(y: -2)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text(viewModel.title)
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    Spacer(minLength: 9)
                    Text(viewModel.time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Details text
                if !viewModel.subtitle.isEmpty {
                    Text(viewModel.subtitle)
                        .font(.subheadline)
                        .lineLimit(2)
                        .foregroundColor(.secondary)
                }

                metadata
                    .padding(.top, 4)
            }
        }
    }

    @ViewBuilder
    private var metadata: some View {
        if let actor = viewModel.activity.actor {
            HStack(alignment: .center, spacing: 0) {
                HStack(spacing: 6) {
                    ActivityActorAvatarView(actor: actor, diameter: 16)
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
        }
    }

    private var icon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(viewModel.tintColor.opacity(0.15))
                .frame(width: 32, height: 32)

            if let iconImage = viewModel.icon {
                Image(uiImage: iconImage)
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 18, height: 18)
                    .foregroundColor(viewModel.tintColor)
            }
        }
    }
}
