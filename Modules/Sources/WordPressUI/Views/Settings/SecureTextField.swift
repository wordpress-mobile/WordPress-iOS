import SwiftUI
import UIKit

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
        textField.delegate = context.coordinator
        textField.isSecureTextEntry = isSecure
        textField.borderStyle = .none
        textField.isSecureTextEntry = true
        textField.textContentType = .password
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.spellCheckingType = .no
        textField.adjustsFontForContentSizeCategory = true
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
            textField.becomeFirstResponder()
        }
        return textField
    }
    
    public func updateUIView(_ textView: UITextField, context: Context) {
        textView.text = text
        textView.isSecureTextEntry = isSecure
        textView.font = {
            if isSecure {
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
    
    public class Coordinator: NSObject, UITextFieldDelegate {
        let parent: SecureTextField
        
        init(_ parent: SecureTextField) {
            self.parent = parent
        }
        
        public func textFieldDidChangeSelection(_ textField: UITextField) {
            parent.text = textField.text ?? ""
        }
        
        public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            if let currentText = textField.text,
               let textRange = Range(range, in: currentText) {
                let updatedText = currentText.replacingCharacters(in: textRange, with: string)
                parent.text = updatedText
            }
            return true
        }
    }
}
