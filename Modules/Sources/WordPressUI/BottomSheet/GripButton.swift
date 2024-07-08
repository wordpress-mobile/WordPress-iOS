import Foundation
import UIKit

// A UIView with a centered "grip" view (like in Apple Maps)
public class GripButton: UIButton {

    private enum Constants {
        static let width: CGFloat = 32
        static let height: CGFloat = 5
    }

    private var color: UIColor {
        if #available(iOS 13, *) {
            if traitCollection.userInterfaceStyle == .dark {
                return .systemGray4
            } else {
                return .systemGray5
            }
        } else {
            return UIColor(red: 0.764706, green: 0.768627, blue: 0.780392, alpha: 1)
        }
    }

    convenience init() {
        let gripView = UIView()
        gripView.layer.cornerRadius = Constants.height / 2
        gripView.translatesAutoresizingMaskIntoConstraints = false
        gripView.isUserInteractionEnabled = false
        self.init(frame: .zero)

        addSubview(gripView)

        gripView.backgroundColor = color

        NSLayoutConstraint.activate([
            gripView.widthAnchor.constraint(equalToConstant: Constants.width),
            gripView.heightAnchor.constraint(equalToConstant: Constants.height),
            gripView.centerXAnchor.constraint(equalTo: centerXAnchor),
            gripView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
