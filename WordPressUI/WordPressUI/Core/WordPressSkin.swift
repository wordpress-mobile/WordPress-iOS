import Foundation

class WordPressSkin: Skin {
    func configureFancyAlertCancelButton(_ cancel: UIButton) {
        cancel.titleLabel?.font = Style.fontForTextStyle(.headline)
    }
}
