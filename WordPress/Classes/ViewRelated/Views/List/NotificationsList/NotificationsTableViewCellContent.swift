import SwiftUI
import DesignSystem

struct NotificationsTableViewCellContent: View {
    enum Style {
        struct Regular {
            let title: AttributedString?
            let description: String?
            let shouldShowIndicator: Bool
            let avatarStyle: AvatarView<Circle>.Style
            let inlineAction: InlineAction.Configuration?
        }

        struct Altered {
            let text: String
            let action: (() -> Void)?
        }

        case regular(Regular)
        case altered(Altered)
    }

    let style: Style

    init(style: Style) {
        self.style = style
    }

    var body: some View {
        switch style {
        case .regular(let regular):
            Regular(info: regular)
                .padding(.vertical, .DS.Padding.split)
        case .altered(let altered):
            Altered(info: altered)
                .padding(.vertical, .DS.Padding.split)
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
                    .accessibilityHidden(true) // VoiceOver users don't care about the avatar

                textsVStack
                    .offset(
                        x: -info.avatarStyle.leadingOffset * 2,
                        y: -3 * textScale
                    )
                    .padding(.leading, .DS.Padding.split)
                    .saveSize(in: $textsSize)
                    .accessibilitySortPriority(1)
                Spacer()
                if let inlineAction = info.inlineAction {

                    InlineAction(configuration: inlineAction)
                        .padding(.top, actionIconTopPadding())
                        .accessibilityLabel(inlineAction.accessibilityLabel)
                        .accessibilityHint(inlineAction.accessibilityHint)
                        .accessibilitySortPriority(0) // Screenreaders should see the action button last
                }
            }.accessibilityElement(children: .contain)
            .padding(.trailing, .DS.Padding.double)
        }

        private var avatarHStack: some View {
            HStack(spacing: 0) {
                if info.shouldShowIndicator {
                    indicator
                        .padding(.horizontal, .DS.Padding.single)
                    AvatarView(
                        style: info.avatarStyle,
                        placeholderImage: placeholderImage
                    )
                    .offset(x: -info.avatarStyle.leadingOffset)
                } else {
                    AvatarView(
                        style: info.avatarStyle,
                        placeholderImage: placeholderImage
                    )
                    .offset(x: -info.avatarStyle.leadingOffset)
                    .padding(.leading, .DS.Padding.medium)
                }
            }
        }

        private var placeholderImage: Image {
            Image("gravatar")
                .resizable()
        }

        private var indicator: some View {
            Circle()
                .fill(AppColor.primary)
                .frame(width: .DS.Padding.single)
        }

        private var textsVStack: some View {
            VStack(alignment: .leading, spacing: 0) {
                if let title = info.title {
                    Text(title)
                        .style(.bodySmall(.regular))
                        .foregroundStyle(Color.primary)
                        .layoutPriority(1)
                        .lineLimit(2)
                }

                if let description = info.description {
                    Text(description)
                        .style(.bodySmall(.regular))
                        .foregroundStyle(Color.secondary)
                        .layoutPriority(2)
                        .lineLimit(1)
                        .padding(.top, .DS.Padding.half)
                }
            }
        }

        private func actionIconTopPadding() -> CGFloat {
            rootStackAlignment == .center ? 0 : ((info.avatarStyle.diameter * textScale - .DS.Padding.medium) / 2)
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
                        .padding(.leading, .DS.Padding.medium)

                    Spacer()

                    Button(action: {
                        info.action?()
                    }, label: {
                        Text(Strings.undoButtonText)
                            .style(.bodySmall(.regular))
                            .foregroundStyle(Color.white)
                            .accessibilityHint(Strings.undoButtonHint)
                            .padding(.trailing, .DS.Padding.medium)
                    })
                }
            }
            .frame(height: 60)
            .background(Color(UIAppColor.error))
        }
    }
}

// MARK: - Inline Action

extension NotificationsTableViewCellContent {

    struct InlineAction: View {

        class Configuration: ObservableObject {

            @Published var icon: SwiftUI.Image
            @Published var color: Color?

            let action: () -> Void

            let accessibilityLabel: String
            let accessibilityHint: String

            init(icon: SwiftUI.Image, color: Color? = nil, accessibilityLabel: String, accessibilityHint: String, action: @escaping () -> Void) {
                self.icon = icon
                self.color = color
                self.accessibilityLabel = accessibilityLabel
                self.accessibilityHint = accessibilityHint
                self.action = action
            }
        }

        @ObservedObject var configuration: Configuration

        var body: some View {
            Button {
                configuration.action()
            } label: {
                configuration.icon
                    .imageScale(.small)
                    .foregroundStyle(configuration.color ?? Color.secondary)
                    .frame(width: .DS.Padding.medium, height: .DS.Padding.medium)
                    .transaction { transaction in
                        transaction.animation = nil
                    }
            }
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
    VStack(alignment: .leading, spacing: .DS.Padding.medium) {
        NotificationsTableViewCellContent(
            style: .regular(
                .init(
                    title: "John Smith liked your comment more than all other comments as asdf",
                    description: "Here is what I think of all this: Lorem ipsum dolor sit amet, consectetur adipiscing elit",
                    shouldShowIndicator: true,
                    avatarStyle: .single(
                        URL(string: "https://i.pickadummy.com/index.php?imgsize=40x40")!
                    ),
                    inlineAction: .init(icon: .DS.icon(named: .ellipsisHorizontal), accessibilityLabel: "", accessibilityHint: "", action: {})
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
                    inlineAction: .init(icon: .init(systemName: "plus"), accessibilityLabel: "", accessibilityHint: "", action: {})
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
                    inlineAction: .init(icon: .init(systemName: "square.and.arrow.up"), accessibilityLabel: "", accessibilityHint: "", action: {})
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
