
import UIKit

extension UIView {

    /// Oftentimes, the readable content guide is used to layout content.
    /// For Site Creation, however, iPhone content is "full bleed."
    /// This computed property implements this fallback logic.
    ///
    var prevailingLayoutGuide: UILayoutGuide {
        let layoutGuide: UILayoutGuide
        if WPDeviceIdentification.isiPad() {
            layoutGuide = readableContentGuide
        } else {
            if #available(iOS 11.0, *) {
                layoutGuide = safeAreaLayoutGuide
            } else {
                layoutGuide = layoutMarginsGuide
            }
        }

        return layoutGuide
    }
}
