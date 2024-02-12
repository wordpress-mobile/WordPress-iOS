import UIKit
import SwiftUI

final class PagingFooterView: UIView {
    enum State {
        case loading, error
    }

    let buttonRetry: UIButton = {
        let button = UIButton(type: .system)
        var configuration = UIButton.Configuration.plain()
        configuration.title = Strings.retry
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
        button.configuration = configuration
        return button
    }()

    private lazy var errorView: UIView = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.textColor = .secondaryLabel
        label.adjustsFontForContentSizeCategory = true
        label.text = Strings.errorMessage
        return UIStackView(arrangedSubviews: [label, UIView(), buttonRetry])
    }()

    private let spinner = UIActivityIndicatorView(style: .medium)

    init(state: State) {
        super.init(frame: .zero)

        // Add errorView to ensure the footer has the same height in both states
        addSubview(errorView)
        errorView.translatesAutoresizingMaskIntoConstraints = false
        errorView.isHidden = true
        pinSubviewToAllEdges(errorView, insets: UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0), priority: .init(999))

        switch state {
        case .error:
            errorView.isHidden = false
        case .loading:
            addSubview(spinner)
            spinner.startAnimating()
            spinner.translatesAutoresizingMaskIntoConstraints = false
            pinSubviewAtCenter(spinner)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private struct Strings {
        static let errorMessage = NSLocalizedString("general.pagingFooterView.errorMessage", value: "An error occurred", comment: "A generic error message for a footer view in a list with pagination")
        static let retry = NSLocalizedString("general.pagingFooterView.retry", value: "Retry", comment: "A footer retry button")
    }
}

struct PagingFooterWrapperView: UIViewRepresentable {
    let state: PagingFooterView.State

    func makeUIView(context: Context) -> PagingFooterView {
        PagingFooterView(state: state)
    }

    func updateUIView(_ uiView: PagingFooterView, context: Context) {
        // Do nothing
    }
}
