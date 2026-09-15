import SwiftUI

public struct FAB: View {
    let title: String?
    let image: Image
    let action: (() -> Void)?

    public init(title: String? = nil, image: Image = Image(systemName: "plus"), action: (() -> Void)? = nil) {
        self.title = title
        self.image = image
        self.action = action
    }

    public var body: some View {
        if #available(iOS 26, *) {
            Button(action: action ?? {}) {
                HStack(spacing: 6) {
                    image
                        .font(.system(size: 24, weight: .semibold))
                    if let title {
                        Text(title)
                            .font(.headline)
                    }
                }
                .frame(minWidth: 38, minHeight: 38)
                .padding(.horizontal, title == nil ? 0 : 8)
                .foregroundStyle(Color(.systemBackground))
            }
            .buttonStyle(.glassProminent)
            .buttonBorderShape(title == nil ? .circle : .capsule)
            .tint(Color(.label).opacity(0.8))
        } else {
            legacy
        }
    }

    @ViewBuilder
    private var legacy: some View {
        Group {
            if let action {
                Button(action: action) {
                    FABContentView(title: title, image: image)
                }
            } else {
                FABContentView(title: title, image: image)
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility1) // important to be attached from the outside
    }
}

private struct FABContentView: View {
    let title: String?
    let image: Image

    @ScaledMetric(relativeTo: .title2) private var size = 54.0
    @ScaledMetric(relativeTo: .title2) private var shadowRadios = 4.0
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 6) {
            image
                .font(.title2)
            if let title {
                Text(title)
                    .font(.headline)
            }
        }
        .foregroundStyle(Color.white)
        .frame(minWidth: size, minHeight: size)
        .padding(.horizontal, title == nil ? 0 : 16)
        .background(colorScheme == .light ? Color(.label) : Color(.systemGray2))
        .cornerRadius(size / 2)
        .shadow(radius: shadowRadios)
    }
}

#Preview(traits: .fixedLayout(width: 200, height: 200)) {
    FAB(action: {})
}

#Preview("With title", traits: .fixedLayout(width: 200, height: 200)) {
    FAB(title: "Write", action: {})
}
