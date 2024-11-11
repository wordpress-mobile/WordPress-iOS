import SwiftUI

public struct EmptyStateView<Label: View, Description: View, Actions: View>: View {
    @ViewBuilder let label: () -> Label
    @ViewBuilder var description: () -> Description
    @ViewBuilder var actions: () -> Actions

    @ScaledMetric(relativeTo: .title) var maxWidthCompact = 320
    @ScaledMetric(relativeTo: .title) var maxWidthRegular = 420
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    public init(
        @ViewBuilder label: @escaping () -> Label,
        @ViewBuilder description: @escaping () -> Description,
        @ViewBuilder actions: @escaping () -> Actions
    ) {
        self.label = label
        self.description = description
        self.actions = actions
    }

    public var body: some View {
        VStack(alignment: .center, spacing: 40) {
            VStack(alignment: .center, spacing: 6) {
                label()
                    .font(.title2.weight(.medium))
                    .labelStyle(EmptyStateViewLabelStyle())
                description()
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .lineLimit(4)
            }
            actions()
        }
        .frame(maxWidth: horizontalSizeClass == .compact ? maxWidthCompact : maxWidthRegular)
        .padding()
    }
}

extension EmptyStateView where Label == SwiftUI.Label<Text, Image>, Description == Text?, Actions == EmptyView {
    public init(_ title: String, image name: String, description: String? = nil) {
        self.init {
            Label(title, image: name)
        } description: {
            description.map { Text($0) }
        } actions: {
            EmptyView()
        }
    }

    public init(_ title: String, systemImage name: String, description: String? = nil) {
        self.init {
            Label(title, systemImage: name)
        } description: {
            description.map { Text($0) }
        } actions: {
            EmptyView()
        }
    }
}

private struct EmptyStateViewLabelStyle: LabelStyle {
    @ScaledMetric(relativeTo: .title) var iconSize = 50

    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .center, spacing: 16) {
            configuration.icon
                .font(.system(size: iconSize).weight(.medium))
                .foregroundColor(.secondary)
            configuration.title
        }
    }
}

#Preview("Standard") {
    EmptyStateView("You don't have any tags", systemImage: "magnifyingglass", description: "Tags created here can be easily added to new posts")
}

#Preview("Custom") {
    EmptyStateView {
        Text("You don't have any tags")
    } description: {
        Text("Tags created here can be easily added to new posts")
    } actions: {
        Button {

        } label: {
            Text("Create Tag")
        }
        .buttonStyle(.borderedProminent)
    }
}
