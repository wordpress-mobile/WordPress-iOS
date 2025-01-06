import UIKit
import SwiftUI
import AsyncImageKit

public struct SiteIconView: View {
    public let viewModel: SiteIconViewModel

    @Environment(\.siteIconBackgroundColor) private var backgroundColor

    public init(viewModel: SiteIconViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        contents
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    @ViewBuilder
    private var contents: some View {
        if let imageURL = viewModel.imageURL {
            CachedAsyncImage(url: imageURL, host: viewModel.host) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fit)
                case .failure:
                    failureStateView
                default:
                    backgroundColor
                }
            }
        } else {
            noIconView
        }
    }

    private var noIconView: some View {
        backgroundColor.overlay {
            if let firstLetter = viewModel.firstLetter {
                // - warning: important to use `.foregroundColor` and not
                // `.foregroundStyle` to avoid it changing in sidebar on selection
                Text(firstLetter.uppercased())
                    .font(.system(size: iconFontSize(for: viewModel.size), weight: .medium, design: .rounded))
                    .foregroundColor(.secondary.opacity(0.8))
            } else {
                failureStateView
            }
        }
    }

    private func iconFontSize(for size: SiteIconViewModel.Size) -> CGFloat {
        switch size {
        case .small: 18
        case .regular: 24
        case .large: 34
        }
    }

    private var failureStateView: some View {
        backgroundColor.overlay {
            Image("vector", bundle: .module)
                .resizable()
                .frame(width: 18, height: 18)
                .tint(Color(.tertiaryLabel))
        }
    }
}

private struct SiteIconViewBackgroundColorKey: EnvironmentKey {
    static let defaultValue = Color(.secondarySystemBackground)
}

extension EnvironmentValues {
    public var siteIconBackgroundColor: Color {
        get { self[SiteIconViewBackgroundColorKey.self] }
        set { self[SiteIconViewBackgroundColorKey.self] = newValue }
    }
}

// MARK: - SiteIconViewModel

public struct SiteIconViewModel {
    public var imageURL: URL?
    public var firstLetter: Character?
    public var size: Size
    public var host: MediaHostProtocol?

    public enum Size {
        case small
        case regular
        case large

        public var width: CGFloat {
            switch self {
            case .small: 28
            case .regular: 40
            case .large: 72
            }
        }

        public var size: CGSize {
            CGSize(width: width, height: width)
        }
    }

    public init(imageURL: URL? = nil, firstLetter: Character? = nil, size: Size = .regular, host: MediaHostProtocol? = nil) {
        self.imageURL = imageURL
        self.firstLetter = firstLetter
        self.size = size
        self.host = host
    }
}

// MARK: - SiteIconHostingView (UIKit)

public final class SiteIconHostingView: UIView {
    private let viewModel = SiteIconHostingViewModel()

    public override init(frame: CGRect) {
        super.init(frame: frame)

        let host = UIHostingController(rootView: _SiteIconHostingView(viewModel: viewModel))
        addSubview(host.view)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        host.view.backgroundColor = .clear // important
        host.view.pinSubviewToAllEdges(self)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func setIcon(with viewModel: SiteIconViewModel) {
        self.viewModel.icon = viewModel
    }
}

private final class SiteIconHostingViewModel: ObservableObject {
    @Published var icon: SiteIconViewModel?
}

private struct _SiteIconHostingView: View {
    @ObservedObject var viewModel: SiteIconHostingViewModel

    var body: some View {
        viewModel.icon
            .map(SiteIconView.init)
            .environment(\.siteIconBackgroundColor, Color(.systemBackground))
    }
}
