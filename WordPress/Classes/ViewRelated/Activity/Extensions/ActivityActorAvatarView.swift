import SwiftUI
import WordPressKit
import WordPressUI
import Gridicons

struct ActivityActorAvatarView: View {
    let actor: ActivityActor?
    let diameter: CGFloat

    init(actor: ActivityActor?, diameter: CGFloat = 40) {
        self.actor = actor
        self.diameter = diameter
    }

    var body: some View {
        Group {
            if let actor {
                if let url = URL(string: actor.avatarURL) {
                    AvatarView(style: .single(url), diameter: diameter)
                } else if actor.type == "Application" {
                    applicationAvatar
                } else {
                    placeholder(for: actor)
                }
            } else {
                defaultPlaceholder
            }
        }
        .frame(width: diameter, height: diameter)
    }

    private func placeholder(for actor: ActivityActor) -> some View {
        Circle()
            .fill(Color(.secondarySystemFill))
            .overlay(
                Text(actor.displayName.prefix(1).uppercased())
                    .font(.system(size: fontSize, weight: .medium))
                    .foregroundStyle(.secondary)
            )
    }

    private var defaultPlaceholder: some View {
        Circle()
            .fill(Color(.secondarySystemFill))
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: iconSize))
                    .foregroundStyle(.tertiary)
            )
    }

    private var applicationAvatar: some View {
        ZStack {
            Circle()
                .fill(AppColor.primary)
            Image(uiImage: .gridicon(.plugins, size: CGSize(width: iconSize, height: iconSize)))
                .foregroundColor(.white)
        }
    }

    private var fontSize: CGFloat {
        switch diameter {
        case 0..<20:
            return 9
        case 20..<30:
            return 12
        case 30..<50:
            return 16
        default:
            return 20
        }
    }

    private var iconSize: CGFloat {
        switch diameter {
        case 0..<20:
            return 10
        case 20..<30:
            return 14
        case 30..<50:
            return 18
        default:
            return 24
        }
    }
}
