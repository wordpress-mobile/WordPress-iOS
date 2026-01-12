import SwiftUI
import WordPressShared

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
                    .multilineTextAlignment(.center)
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

extension EmptyStateView where Label == EmptyStateScaledImageLabel, Description == Text?, Actions == EmptyView {
    public init(_ title: String, scaledImage: String, description: String? = nil) {
        self.init {
            EmptyStateScaledImageLabel(title, imageName: scaledImage)
        } description: {
            description.map { Text($0) }
        } actions: {
            EmptyView()
        }
    }
}

/// A label designed to work with vector graphics from the assets catalog.
public struct EmptyStateScaledImageLabel: View {
    let title: String
    let imageName: String

    public init(_ title: String, imageName: String) {
        self.title = title
        self.imageName = imageName
    }

    public var body: some View {
        VStack(alignment: .center, spacing: 8) {
            ScaledImage(imageName, height: largeImageHeight)
                .foregroundColor(.secondary)
            Text(title)
        }
    }
}

private struct EmptyStateViewLabelStyle: LabelStyle {
    @ScaledMetric(relativeTo: .title) var iconSize = largeImageHeight

    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .center, spacing: 16) {
            configuration.icon
                .font(.system(size: iconSize).weight(.medium))
                .foregroundColor(.secondary)
            configuration.title
        }
    }
}

private let largeImageHeight: CGFloat = 56

extension EmptyStateView where Label == SwiftUI.Label<Text, Image>, Description == Text?, Actions == EmptyView {
    public static func search() -> Self {
        EmptyStateView(
            AppLocalizedString("emptyStateView.noSearchResult.title", value: "No Results", comment: "Shared empty state view"),
            systemImage: "magnifyingglass",
            description: AppLocalizedString("emptyStateView.noSearchResult.description", value: "Try a new search", comment: "Shared empty state view")
        )
    }
}

extension EmptyStateView where Label == SwiftUI.Label<Text, Image>, Description == Text?, Actions == Button<Text>? {
    public static func failure(error: Error, onRetry: (() -> Void)? = nil) -> Self {
        EmptyStateView {
            Label(AppLocalizedString("shared.error.generic", value: "Something went wrong", comment: "A generic error message"), systemImage: "exclamationmark.circle")
        } description: {
            Text(error.localizedDescription)
        } actions: {
            if let onRetry {
                Button(AppLocalizedString("shared.button.retry", value: "Retry", comment: "A shared button title used in different contexts"), action: onRetry)
            }
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
