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

        if let viewModel = viewModel,
           let stateView = UIHostingController(rootView: DomainsStateView(viewModel: viewModel)).view {
            stateView.backgroundColor = .clear
            stackView.addArrangedSubview(stateView)
        }
    }
}
