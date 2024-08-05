import UIKit
import SwiftUI
import DesignSystem
import WordPressShared

struct SiteIconView: View {
    let viewModel: SiteIconViewModel

    var body: some View {
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
                    viewModel.background
                }
            }
        } else {
            noIconView
        }
    }

    private var noIconView: some View {
        viewModel.background.overlay {
            if let firstLetter = viewModel.firstLetter {
                Text(firstLetter.uppercased())
                    .font(.system(size: 24, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary.opacity(0.8))
            } else {
                failureStateView
            }
        }
    }

    private var failureStateView: some View {
        viewModel.background.overlay {
            Image.DS.icon(named: .vector)
                .resizable()
                .frame(width: 18, height: 18)
                .tint(.DS.Foreground.tertiary)
        }
    }
}

// MARK: - SiteIconHostingView (UIKit)

final class SiteIconHostingView: UIView {
    private let viewModel = SiteIconHostingViewModel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        let host = UIHostingController(rootView: _SiteIconHostingView(viewModel: viewModel))
        addSubview(host.view)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        host.view.backgroundColor = .clear // important
        host.view.pinSubviewToAllEdges(self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setIcon(with viewModel: SiteIconViewModel) {
        self.viewModel.icon = viewModel
    }
}

private final class SiteIconHostingViewModel: ObservableObject {
    @Published var icon: SiteIconViewModel?
}

private struct _SiteIconHostingView: View {
    @ObservedObject var viewModel: SiteIconHostingViewModel

    var body: some View {
        viewModel.icon.map(SiteIconView.init)
    }
}
