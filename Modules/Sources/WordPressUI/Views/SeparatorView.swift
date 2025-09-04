import UIKit

public final class SeparatorView: UIView {
    public static func horizontal(height: CGFloat = 0.33) -> SeparatorView {
        let view = SeparatorView()
        view.heightAnchor.constraint(equalToConstant: height).isActive = true
        return view
    }

    public static func vertical(width: CGFloat = 0.33) -> SeparatorView {
        let view = SeparatorView()
        view.widthAnchor.constraint(equalToConstant: width).isActive = true
        return view
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .separator
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
