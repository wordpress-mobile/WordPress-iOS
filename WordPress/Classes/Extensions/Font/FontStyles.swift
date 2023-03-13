import UIKit

struct FontStyles {

    // MARK: - Display Set

    var prominent: (_ style: UIFont.TextStyle, _ weight: UIFont.Weight) -> UIFont
}

extension FontStyles {

    func prominent(textStyle: UIFont.TextStyle, weight: UIFont.Weight) -> UIFont {
        return prominent(textStyle, weight)
    }
}
