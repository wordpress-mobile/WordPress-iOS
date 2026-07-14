import Testing
import UIKit

@testable import WordPress

struct BloggingRemindersScheduleFormatterTests {

    @Test @MainActor func longDescriptionPreservesEmphasisWithoutSpecifyingForegroundColor() {
        let description = BloggingRemindersScheduleFormatter()
            .longScheduleDescription(
                for: .weekdays([.monday]),
                time: "10:00 AM"
            )

        var containsBoldText = false
        description.enumerateAttributes(in: NSRange(location: 0, length: description.length)) { attributes, _, _ in
            #expect(attributes[.foregroundColor] == nil)
            if let font = attributes[.font] as? UIFont {
                containsBoldText = containsBoldText || font.fontDescriptor.symbolicTraits.contains(.traitBold)
            }
        }

        #expect(containsBoldText)
    }
}
