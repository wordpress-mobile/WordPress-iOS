import SwiftUI
import Testing
@testable import WordPressComments

@MainActor
struct CommentDetailViewTests {
    @Test(arguments: DynamicTypeSize.allCases)
    func compactHeightUsesMenuForAccessibilitySizes(_ size: DynamicTypeSize) {
        #expect(
            CommentDetailView.usesModerationMenu(verticalSizeClass: .compact, dynamicTypeSize: size)
                == size.isAccessibilitySize
        )
    }

    @Test(arguments: DynamicTypeSize.allCases)
    func regularOrUnspecifiedHeightUsesMenuOnlyForLargestSizes(_ size: DynamicTypeSize) {
        let usesMenu = [DynamicTypeSize.accessibility4, .accessibility5].contains(size)
        for sizeClass in [UserInterfaceSizeClass.regular, nil] {
            #expect(
                CommentDetailView.usesModerationMenu(verticalSizeClass: sizeClass, dynamicTypeSize: size)
                    == usesMenu
            )
        }
    }
}
