import SwiftUI

extension Text {

    /// This initializer constructs a Text from a String that contains simple markers to delineate
    /// a section to highlight in bold. It can only handle a single bold section. For example:
    /// "This is my *example string* with one bold section."
    ///
    init(string: String, boldMarker: String = "*") {
        self.init("")

        let parts = string.components(separatedBy: boldMarker)
        guard parts.count == 3 else {
            // This only works with exactly one bold substring, enclosed by * characters
            self = Text(string)
            return
        }

        var text = Text("")

        parts.enumerated().forEach { (index, part) in
            let partText = Text(part)

            if index == parts.count-2 { // last-but-one part
                text = text + partText.bold()
            } else {
                text = text + partText
            }
        }

        self = text
    }
}
