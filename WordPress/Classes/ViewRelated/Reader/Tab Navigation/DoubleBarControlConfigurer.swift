import UIKit

// Where to place this file?
enum DoubleBarControlConfigurer {
    static func stackView(with leftControl: UIControl?, rightControl: UIControl?) -> UIStackView {
        let stackView = UIStackView(arrangedSubviews: [leftControl, rightControl].compactMap({ $0 }))
        stackView.distribution = .equalSpacing
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 0

        setupBarButtonConstraints(leftControl: leftControl, rightControl: rightControl)

        return stackView
    }

    private static func setupBarButtonConstraints(leftControl: UIControl?, rightControl: UIControl?) {
        setupConstraints(for: leftControl)
        setupConstraints(for: rightControl)
    }

    private static func setupConstraints(for control: UIControl?) {
        guard let control = control else {
            return
        }

        // TODO: Check if a common/global constant exists
        let minimumTappableLength: CGFloat = 44

        control.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            control.widthAnchor.constraint(equalToConstant: minimumTappableLength),
            control.heightAnchor.constraint(equalToConstant: minimumTappableLength)
        ])
    }
}
