import Foundation

final class SolidColorActivityIndicator: UIView, ActivityIndicatorType {
    init(color: UIColor = .secondarySystemBackground) {
        super.init(frame: .zero)
        backgroundColor = color
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func startAnimating() {
        isHidden = false
    }

    func stopAnimating() {
        isHidden = true
    }
}
