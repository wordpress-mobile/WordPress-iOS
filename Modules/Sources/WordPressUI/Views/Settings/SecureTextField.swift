import SwiftUI
import UIKit

/// - note: The SwiftUI version of the secure text field does not allow you to
/// change to the "view password" mode while preserving the focus – you have
/// to create a separate (regular) text field for that, and it loses focus.
public struct SecureTextField: UIViewRepresentable {
    @Binding var text: String
    var isSecure: Bool
    let placeholder: String

    public init(text: Binding<String>, isSecure: Bool, placeholder: String) {
        self._text = text
        self.isSecure = isSecure
        self.placeholder = placeholder
    }

    public func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.placeholder = placeholder
        textField.isSecureTextEntry = isSecure
        textField.borderStyle = .none
        textField.isSecureTextEntry = true
        textField.textContentType = .password
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.spellCheckingType = .no
        textField.adjustsFontForContentSizeCategory = true
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textFieldDidChange), for: .editingChanged)
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
            textField.becomeFirstResponder()
        }
        return textField
    }

    public func updateUIView(_ textView: UITextField, context: Context) {
        textView.text = text
        textView.isSecureTextEntry = isSecure
        textView.font = {
            if isSecure || text.isEmpty {
                return UIFont.preferredFont(forTextStyle: .body)
            }
            guard let font = UIFont(name: "Menlo", size: 17) else {
                return UIFont.preferredFont(forTextStyle: .body)
            }
            return UIFontMetrics(forTextStyle: .body).scaledFont(for: font)
        }()
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public class Coordinator: NSObject {
        let parent: SecureTextField

        init(_ parent: SecureTextField) {
            self.parent = parent
        }

        @objc func textFieldDidChange(_ textField: UITextField) {
            parent.text = textField.text ?? ""
        }
    }
}
