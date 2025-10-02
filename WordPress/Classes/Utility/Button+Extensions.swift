import SwiftUI

extension Button where Label == Text {
    @ViewBuilder
    public static func make(role: BackportButtonRole, action: @escaping () -> Void) -> some View {
        if #available(iOS 26, *) {
            SwiftUI.Button(role: ButtonRole(role), action: action)
        } else {
            SwiftUI.Button(role.title) {
                action()
            }
        }
    }
}

public enum BackportButtonRole {
    case cancel
    case close
    case confirm

    var title: String {
        switch self {
        case .cancel: SharedStrings.Button.cancel
        case .close: SharedStrings.Button.close
        case .confirm: SharedStrings.Button.done
        }
    }
}

@available(iOS 26, *)
private extension ButtonRole {
    init(_ role: BackportButtonRole) {
        switch role {
        case .cancel: self = .cancel
        case .close: self = .close
        case .confirm: self = .confirm
        }
    }
}
