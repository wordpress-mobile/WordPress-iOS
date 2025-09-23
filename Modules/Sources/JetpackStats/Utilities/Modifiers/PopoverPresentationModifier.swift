import SwiftUI

struct PopoverPresentationModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.presentationCompactAdaptation(.popover)
    }
}
