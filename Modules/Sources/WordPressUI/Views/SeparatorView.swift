import UIKit

public final class SeparatorView: UIView {
    public static func horizontal() -> SeparatorView {
        let view = SeparatorView()
        view.heightAnchor.constraint(equalToConstant: 0.33).isActive = true
        return view
    }

    public static func vertical() -> SeparatorView {
        let view = SeparatorView()
        view.widthAnchor.constraint(equalToConstant: 0.33).isActive = true
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
