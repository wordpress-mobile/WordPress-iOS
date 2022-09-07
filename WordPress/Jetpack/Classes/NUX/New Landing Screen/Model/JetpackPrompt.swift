import SwiftUI

struct JetpackPrompt: Identifiable {
    var id = UUID()
    let index: Int
    let text: String
    let color: Color
    var frameHeight: CGFloat
    var initialOffset: CGFloat
}
