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
        /// - TODO: update app ui
    }

}
