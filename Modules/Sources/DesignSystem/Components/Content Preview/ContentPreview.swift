import SwiftUI

public struct ContentPreview: View {

    // MARK: - Constants

    public enum Constants {
        public static let imageSize: CGFloat = 32
    }

    // MARK: - Metrics

    @ScaledMetric private var imageSize: CGFloat = Constants.imageSize
    @ScaledMetric private var height: CGFloat = 40

    private var leadingPadding: CGFloat {
        return image == nil ? CGFloat.DS.Padding.double : CGFloat.DS.Padding.single
    }

    // MARK: - Properties

    private let image: ImageConfiguration?
    private let text: String
    private let action: () -> Void

    // MARK: - Init

    public init(image: ImageConfiguration? = nil, text: String, action: @escaping () -> Void) {
        self.image = image
        self.text = text
        self.action = action
    }

    // MARK: - Body

    public var body: some View {
        Button(action: action) {
            HStack(spacing: CGFloat.DS.Padding.half) {
                if let configuration = image {
                    image(configuration: configuration)
                }
                Text(text)
                    .style(.bodyLarge(.regular))
                    .lineLimit(1)
                    .foregroundStyle(Color.DS.Foreground.primary)
                Spacer()
                Image.DS.icon(named: .chevronRight)
                    .foregroundStyle(Color.DS.Foreground.tertiary)
            }
            .padding(.trailing, CGFloat.DS.Padding.single)
            .padding(.leading, leadingPadding)
            .frame(height: height)
            .background(Color.DS.Background.secondary)
            .clipShape(Capsule())
        }
    }

    private func image(configuration: ImageConfiguration) -> some View {
        AsyncImage(url: configuration.url) { phase in
            Group {
                switch phase {
                case .success(let image):
                    image.resizable()
                default:
                    if let placeholder = configuration.placeholder {
                        placeholder
                            .resizable()
                    } else {
                        Color.DS.Background.tertiary
                    }
                }
            }
            .frame(width: imageSize, height: imageSize)
            .clipShape(Circle())
        }
    }

    // MARK: - Types

    public struct ImageConfiguration {
        
        let url: URL?
        let placeholder: Image?

        public init(url: URL?, placeholder: Image? = nil) {
            self.url = url
            self.placeholder = placeholder
        }

        public init(url: String?, placeholder: Image? = nil) {
            self.init(url: URL(string: url ?? ""), placeholder: placeholder)
        }
    }
}

#Preview {
    VStack {
        ContentPreview(image: .init(url: "https://i.pravatar.cc/300"),
                       text: "Great post! ❤️",
                       action: {})
        ContentPreview(text: "The Beauty of Off-the-Beaten-Path Adventures",
                       action: {})
        ContentPreview(image: .init(url: "https://i.pravatar.cc/300"),
                       text: "Absolutely loved the tips in your latest post! 😊",
                       action: {})
        ContentPreview(image: .init(url: URL(string: "invalid-url")),
                       text: "Just stumbled upon your latest art piece and wow, I'm blown away!",
                       action: {})
    }
        .padding(.horizontal, CGFloat.DS.Padding.double)
}
