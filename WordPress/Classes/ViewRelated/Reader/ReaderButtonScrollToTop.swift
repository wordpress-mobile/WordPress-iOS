import UIKit

final class ReaderButtonScrollToTop: UIButton {
    private var isButtonHidden = false

    static func make(closure: @escaping () -> Void) -> ReaderButtonScrollToTop {
        var configuration = UIButton.Configuration.bordered()
        configuration.image = UIImage(systemName: "arrow.up")?
                .withConfiguration(UIImage.SymbolConfiguration(pointSize: 12, weight: .regular))
        configuration.cornerStyle = .capsule
        configuration.baseBackgroundColor = .secondarySystemBackground
        configuration.baseForegroundColor = .label
        configuration.contentInsets = .init(top: 10, leading: 10, bottom: 10, trailing: 10)

        return ReaderButtonScrollToTop(configuration: configuration, primaryAction: .init { _ in
            closure()
            WPAnalytics.track(.readerButtonScrollToTopTapped)
        })
    }

    func setButtonHidden(_ isHidden: Bool, animated: Bool) {
        guard isButtonHidden != isHidden else { return }
        isButtonHidden = isHidden

        UIView.animate(withDuration: animated ? 0.33 : 0.0) {
            self.alpha = isHidden ? 0 : 1
            self.isUserInteractionEnabled = !isHidden
        }
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        bounds.insetBy(dx: -8, dy: -10).contains(point)
    }
}
