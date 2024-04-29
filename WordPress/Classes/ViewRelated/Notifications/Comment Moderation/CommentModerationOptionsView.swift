import SwiftUI
import DesignSystem

struct CommentModerationOptionsView: View {

    private var options: [Option] = [
        .approve,
        .pending,
        .trash,
        .spam
    ]

    var optionSelected: ((Option) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: .DS.Padding.medium) {
            title
            optionsVStack
        }
        .padding(.horizontal, .DS.Padding.double)
        .background(Color.DS.Background.primary)
    }

    private var title: some View {
        Text(Strings.title)
            .font(.DS.Body.Emphasized.large)
            .foregroundStyle(Color.DS.Foreground.primary)
    }

    private var optionsVStack: some View {
        VStack(spacing: .DS.Padding.medium) {
            ForEach(options, id: \.title) { option in
                Button {
                    optionSelected?(option)
                } label: {
                    optionHStack(option: option)
                }
            }
        }
    }

    private func optionHStack(option: Option) -> some View {
        HStack(spacing: .DS.Padding.double) {
            Image.DS.icon(named: option.iconName)
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(option.tintColor)
                .frame(
                    width: .DS.Padding.medium,
                    height: .DS.Padding.medium
                )

            Text(option.title)
                .font(.DS.Body.large)
                .foregroundStyle(
                    Color.DS.Foreground.primary
                )

            Spacer()
        }
    }
}

extension CommentModerationOptionsView {
    enum Strings {
        static let title = NSLocalizedString(
            "comment.moderation.sheet.title",
            value: "Choose comment status",
            comment: "Title for the comment moderation sheet."
        )
    }
}

extension CommentModerationOptionsView {
    enum Option {
        case approve
        case pending
        case trash
        case spam

        var title: String {
            switch self {
            case .approve:
                return Strings.approveTitle
            case .pending:
                return Strings.pendingTitle
            case .trash:
                return Strings.trashTitle
            case .spam:
                return Strings.spamTitle
            }
        }

        var iconName: IconName {
            switch self {
            case .approve:
                return .checkmarkCircle
            case .pending:
                return .clock
            case .trash:
                return .trash
            case .spam:
                return .exclamationCircle
            }
        }

        var tintColor: Color {
            switch self {
            case .approve:
                return .DS.Foreground.brand(isJetpack: true)
            case .pending:
                return .DS.Foreground.secondary
            case .trash:
                return .DS.Foreground.warning
            case .spam:
                return .DS.Foreground.error
            }
        }
    }
}

private extension CommentModerationOptionsView.Option {
    enum Strings {
        static let approveTitle = NSLocalizedString(
            "comment.moderation.sheet.approve.title",
            value: "Approve",
            comment: "Approve option title for the comment moderation sheet."
        )
        static let pendingTitle = NSLocalizedString(
            "comment.moderation.sheet.pending.title",
            value: "Pending",
            comment: "Pending option title for the comment moderation sheet."
        )
        static let trashTitle = NSLocalizedString(
            "comment.moderation.sheet.trash.title",
            value: "Trash",
            comment: "Trash option title for the comment moderation sheet."
        )
        static let spamTitle = NSLocalizedString(
            "comment.moderation.sheet.spam.title",
            value: "Spam",
            comment: "Spam option title for the comment moderation sheet."
        )
    }
}

#Preview {
    CommentModerationOptionsView()
}
