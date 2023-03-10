import SwiftUI

final class AppColorPickerViewModel: ObservableObject {

    @Published var color = AppColor.color {
        didSet {
            if color != oldValue {
                updateAppColor(color)
            }
        }
    }

    func restoreDefaultColor() {
        color = AppColor.defaultColor
    }

    private func updateAppColor(_ color: Color) {
        AppColor.update(with: color)

        let appDelegate = UIApplication.shared.delegate as? WordPressAppDelegate
        appDelegate?.customizeAppearance()

        /// - TODO: at this point some parts of the UI still use the previous color
        /// find a way to update all UI globally when user changes "App Color" in Settings 🤔
    }

}
