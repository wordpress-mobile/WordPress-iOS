import UIKit
import WordPressUI
import DesignSystem
import SwiftUI

final class AllDomainsListEmptyView: UIView {

    typealias ViewModel = DomainsStateViewModel

    // MARK: - Views

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.backgroundColor = .clear
        return stackView
    }()

    // MARK: - Init

    init(viewModel: ViewModel? = nil) {
        super.init(frame: .zero)
        self.render(with: viewModel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Rendering

    private func render(with viewModel: ViewModel?) {
        self.addSubview(stackView)
        self.pinSubviewToAllEdges(stackView)
        self.update(with: viewModel)
    }

    func update(with viewModel: ViewModel?) {
        stackView.removeAllSubviews()

        if let viewModel {

            let stateView = EmptyStateView {
                Label(viewModel.title, systemImage: "network")
            } description: {
                Text(viewModel.description)
            } actions: {
                if let button = viewModel.button {
                    Button(button.title, action: button.action)
                        .buttonStyle(.primary)
                }
            }
            stackView.addArrangedSubview(UIHostingView(view: stateView))
        }
    }
}
