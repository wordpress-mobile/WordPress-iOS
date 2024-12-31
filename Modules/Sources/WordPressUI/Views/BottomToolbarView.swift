import UIKit
import Combine

/// A custom bottom toolbar implementation that, unlike the native toolbar,
/// can accommodate larger buttons but shares a lot of its behavior including
/// edge appearance.
public class BottomToolbarView: UIView {
    private let separator = SeparatorView.horizontal()
    private let effectView = UIVisualEffectView()
    private var isEdgeAppearanceEnabled = false
    private weak var scrollView: UIScrollView?
    private var cancellable: AnyCancellable?

    public let contentView = UIView()

    public override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(effectView)
        addSubview(separator)

        separator.pinEdges([.top, .horizontal])
        effectView.pinEdges()

        effectView.contentView.addSubview(contentView)

        contentView.pinEdges(to: effectView.contentView.safeAreaLayoutGuide, insets: UIEdgeInsets(.all, 20))
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        updateScrollViewContentInsets()
    }

    public override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()

        updateScrollViewContentInsets()
    }

    /// - warning: If you use this view, you'll typically need to take over the
    /// scroll view content inset adjustment.
    public func configure(in viewController: UIViewController, scrollView: UIScrollView) {
        viewController.view.addSubview(self)
        pinEdges([.horizontal, .bottom])
        self.scrollView = scrollView

        cancellable = scrollView.publisher(for: \.contentOffset, options: [.new]).sink { [weak self] offset in
            self?.updateEdgeAppearance(animated: true)
        }
        updateScrollViewContentInsets()
        updateEdgeAppearance(animated: false)
    }

    private func updateEdgeAppearance(animated: Bool) {
        guard let scrollView, let superview else { return }

        let isContentOverlapping = superview.convert(scrollView.contentLayoutGuide.layoutFrame, from: scrollView).maxY > (frame.minY + 16)
        setEdgeAppearanceEnabled(!isContentOverlapping, animated: animated)
    }

    private func setEdgeAppearanceEnabled(_ isEnabled: Bool, animated: Bool) {
        guard isEdgeAppearanceEnabled != isEnabled else { return }
        isEdgeAppearanceEnabled = isEnabled

        UIView.animate(withDuration: animated ? 0 : 0.33, delay: 0.0, options: [.allowUserInteraction, .beginFromCurrentState]) {
            self.effectView.effect = isEnabled ? nil : UIBlurEffect(style: .extraLight)
            self.separator.alpha = isEnabled ? 0 : 1
        }
    }

    // The toolbar does no extend the safe area because it itself depends on it,
    // so it resorts to changing `contentInset` instead.
    private func updateScrollViewContentInsets() {
        guard let scrollView else { return }
        let bottomInset = bounds.height - safeAreaInsets.bottom
        if scrollView.contentInset.bottom != bottomInset {
            scrollView.contentInset.bottom = bottomInset
        }
    }
}
