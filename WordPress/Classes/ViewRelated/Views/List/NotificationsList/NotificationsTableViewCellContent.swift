import SwiftUI
import DesignSystem

struct NotificationsTableViewCellContent: View {
    static let reuseIdentifier = String(describing: Self.self)

    enum Style {
        struct Regular {
            let title: AttributedString?
            let description: String?
            let shouldShowIndicator: Bool
            let avatarStyle: AvatarsView.Style
            let inlineAction: InlineAction?
        }

        struct Altered {
            let text: String
            let action: (() -> Void)?
        }

        case regular(Regular)
        case altered(Altered)
    }

    struct InlineAction {
        let icon: SwiftUI.Image
        let action: () -> Void
    }

    private let style: Style

    init(style: Style) {
        self.style = style
    }

    var body: some View {
        switch style {
        case .regular(let regular):
            Regular(info: regular)
                .padding(.top, Length.Padding.split)
                .padding(.bottom, Length.Padding.split)
        case .altered(let altered):
            Altered(info: altered)
                .padding(.top, Length.Padding.split)
                .padding(.bottom, Length.Padding.split)
        }
    }
}

// MARK: - Regular Style
fileprivate extension NotificationsTableViewCellContent {
    struct Regular: View {

        @State private var avatarSize: CGSize = .zero
        @State private var textsSize: CGSize = .zero
        @ScaledMetric(relativeTo: .subheadline) private var textScale = 1

        private var rootStackAlignment: VerticalAlignment {
            return textsSize.height >= avatarSize.height ? .top : .center
        }

        private let info: Style.Regular

        fileprivate init(info: Style.Regular) {
            self.info = info
        }

        var body: some View {
            HStack(alignment: rootStackAlignment, spacing: 0) {
                avatarHStack
                    .saveSize(in: $avatarSize)
                textsVStack
                    .offset(
                        x: -info.avatarStyle.leadingOffset * 2,
                        y: -3 * textScale
                    )
                    .padding(.leading, Length.Padding.split)
                    .saveSize(in: $textsSize)
                Spacer()
                if let inlineAction = info.inlineAction {
                    Button {
                        inlineAction.action()
                    } label: {
                        inlineAction.icon
                            .imageScale(.medium)
                            .foregroundStyle(Color.DS.Foreground.secondary)
                            .frame(width: Length.Padding.medium, height: Length.Padding.medium)
                    }
                }
            }
            .padding(.trailing, Length.Padding.double)
        }

        private var avatarHStack: some View {
            HStack(spacing: 0) {
                if info.shouldShowIndicator {
                    indicator
                        .padding(.horizontal, Length.Padding.single)
                    AvatarsView(style: info.avatarStyle)
                        .offset(x: -info.avatarStyle.leadingOffset)
                } else {
                    AvatarsView(style: info.avatarStyle)
                        .offset(x: -info.avatarStyle.leadingOffset)
                        .padding(.leading, Length.Padding.medium)
                }
            }
        }

        private var indicator: some View {
            Circle()
                .fill(Color.DS.Background.brand(isJetpack: AppConfiguration.isJetpack))
                .frame(width: Length.Padding.single)
        }

        private var textsVStack: some View {
            VStack(alignment: .leading, spacing: 0) {
                if let title = info.title {
                    Text(title)
                        .style(.bodySmall(.regular))
                        .foregroundStyle(Color.DS.Foreground.primary)
                        .layoutPriority(1)
                        .lineLimit(2)
                }

                if let description = info.description {
                    Text(description)
                        .style(.bodySmall(.regular))
                        .foregroundStyle(Color.DS.Foreground.secondary)
                        .layoutPriority(2)
                        .lineLimit(1)
                        .padding(.top, Length.Padding.half)
                }
            }
        }
    }
}

// MARK: - Regular Style
fileprivate extension NotificationsTableViewCellContent {
    private enum Strings {
        static let undoButtonText = NSLocalizedString(
            "Undo",
            comment: "Revert an operation"
        )
        static let undoButtonHint = NSLocalizedString(
            "Reverts the action performed on this notification.",
            comment: "Accessibility hint describing what happens if the undo button is tapped."
        )
    }
    struct Altered: View {
        private let info: Style.Altered

        fileprivate init(info: Style.Altered) {
            self.info = info
        }

        var body: some View {
            // To not pollute the init too much, colors are uncustomizable
            // If a need arises, they can be added to the `Altered.Info` struct.
            HStack(spacing: 0) {
                Group {
                    Text(info.text)
                        .style(.bodySmall(.regular))
                        .foregroundStyle(Color.white)
                        .lineLimit(2)
                        .padding(.leading, Length.Padding.medium)

                    Spacer()

                    Button(action: {
                        info.action?()
                    }, label: {
                        Text(Strings.undoButtonText)
                            .style(.bodySmall(.regular))
                            .foregroundStyle(Color.white)
                            .accessibilityHint(Strings.undoButtonHint)
                            .padding(.trailing, Length.Padding.medium)
                    })
                }
            }
            .frame(height: 60)
            .background(Color.DS.Foreground.error)
        }
    }
}

// MARK: - Helpers

private struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

private struct SizeModifier: ViewModifier {
    @Binding var size: CGSize

    private var sizeView: some View {
        GeometryReader { geometry in
            Color.clear.preference(key: SizePreferenceKey.self, value: geometry.size)
        }
    }

    func body(content: Content) -> some View {
        content.background(
            sizeView
                .onPreferenceChange(SizePreferenceKey.self, perform: { value in
                    size = value
                })
        )
    }
}

private extension View {
    func saveSize(in size: Binding<CGSize>) -> some View {
        modifier(SizeModifier(size: size))
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    VStack(alignment: .leading, spacing: Length.Padding.medium) {
        NotificationsTableViewCellContent(
            style: .regular(
                .init(
                    title: "John Smith liked your comment more than all other comments as asdf",
                    description: "Here is what I think of all this: Lorem ipsum dolor sit amet, consectetur adipiscing elit",
                    shouldShowIndicator: true,
                    avatarStyle: .single(
                        URL(string: "https://i.pickadummy.com/index.php?imgsize=40x40")!
                    ),
                    inlineAction: .init(icon: .DS.icon(named: .ellipsisHorizontal), action: {})
                )
            )
        )

        NotificationsTableViewCellContent(
            style: .regular(
                .init(
                    title: "Albert Einstein and Marie Curie liked your comment on Quantum Mechanical solution for Hydrogen",
                    description: "Mary Carpenter • marycarpenter.com",
                    shouldShowIndicator: true,
                    avatarStyle: .double(
                        URL(string: "https://i.pickadummy.com/index.php?imgsize=34x34")!,
                        URL(string: "https://i.pickadummy.com/index.php?imgsize=34x34")!
                    ),
                    inlineAction: .init(icon: .init(systemName: "plus"), action: {})
                )
            )
        )
        NotificationsTableViewCellContent(
            style: .regular(
                .init(
                    title: "New likes on Night Time in Tokyo",
                    description: nil,
                    shouldShowIndicator: true,
                    avatarStyle: .triple(
                        URL(string: "https://i.pickadummy.com/index.php?imgsize=28x28")!,
                        URL(string: "https://i.pickadummy.com/index.php?imgsize=28x28")!,
                        URL(string: "https://i.pickadummy.com/index.php?imgsize=28x28")!
                    ),
                    inlineAction: .init(icon: .init(systemName: "square.and.arrow.up"), action: {})
                )
            )
        )

        NotificationsTableViewCellContent(
            style: .altered(
                .init(
                    text: "Comment has been marked as Spam",
                    action: nil
                )
            )
        )
    }
}
#endif
