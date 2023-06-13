import SwiftUI

struct SettingsTextEditView: UIViewControllerRepresentable {
    let value: String?
    let placeholder: String
    var hint: String?
    let onCommit: ((String)) -> Void

    func makeUIViewController(context: Context) -> SettingsTextViewController {
        let viewController = SettingsTextViewController(text: value ?? "", placeholder: placeholder, hint: hint ?? "")
        viewController.onValueChanged = onCommit
        return viewController
    }

    func updateUIViewController(_ uiViewController: SettingsTextViewController, context: Context) {
        // Do nothing
    }
}
