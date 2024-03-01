import UIKit

extension UILabel {
    func style(_ style: TextStyle) -> Self {
        self.font = UIFont.DS.font(style)
        if style.case == .uppercase {
            self.text = self.text?.uppercased()
        }
        return self
    }
}
