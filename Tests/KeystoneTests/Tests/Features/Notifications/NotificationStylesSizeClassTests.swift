import Testing
import UIKit
@testable import WordPress
@testable import FormattableContentKit
import WordPressSharedUI

@MainActor
@Suite("Notification styles follow the window's horizontal size class")
struct NotificationStylesSizeClassTests {
    @Test(
        "rich text uses the larger metrics only in a regular-width window",
        arguments: [
            (UIUserInterfaceSizeClass.compact, CGFloat(14), CGFloat(21)),
            (.regular, 16, 24),
            (.unspecified, 14, 21)
        ]
    )
    func richTextMetrics(sizeClass: UIUserInterfaceSizeClass, fontSize: CGFloat, lineHeight: CGFloat) throws {
        let text = FormattableContentFormatter()
            .render(
                content: FormattableTextContent(text: "Hello", ranges: []),
                with: RichTextContentStyles(horizontalSizeClass: sizeClass)
            )

        let font = try #require(text.attribute(.font, at: 0, effectiveRange: nil) as? UIFont)
        let paragraph = try #require(text.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle)
        #expect(font.pointSize == fontSize)
        #expect(paragraph.minimumLineHeight == lineHeight)
    }

    @Test(
        "the subject's notification icon is larger only in a regular-width window",
        arguments: [(UIUserInterfaceSizeClass.compact, CGFloat(14)), (.regular, 15)]
    )
    func subjectNoticonSize(sizeClass: UIUserInterfaceSizeClass, iconSize: CGFloat) throws {
        let noticon = FormattableNoticonRange(value: "\u{f442}", range: NSRange(location: 0, length: 0))
        let text = FormattableContentFormatter()
            .render(
                content: FormattableTextContent(text: "Hello", ranges: [noticon]),
                with: SubjectContentStyles(horizontalSizeClass: sizeClass)
            )

        let font = try #require(text.attribute(.font, at: 0, effectiveRange: nil) as? UIFont)
        #expect(font.fontName == "Noticons")
        #expect(font.pointSize == iconSize)
    }

    @Test(
        "fonts and paragraph styles are built once per size class",
        arguments: [UIUserInterfaceSizeClass.compact, .regular]
    )
    func stylesAreReused(sizeClass: UIUserInterfaceSizeClass) throws {
        typealias Style = WPStyleGuide.Notifications
        #expect(Style.contentBlockRegularFont(for: sizeClass) === Style.contentBlockRegularFont(for: sizeClass))
        let first = try #require(Style.contentBlockRegularStyle(for: sizeClass)[.paragraphStyle] as? NSParagraphStyle)
        let second = try #require(Style.contentBlockRegularStyle(for: sizeClass)[.paragraphStyle] as? NSParagraphStyle)
        #expect(first === second)
    }

    @Test("one formatter keeps a separate cached rendering for each size class")
    func cacheIsKeyedBySizeClass() throws {
        let formatter = FormattableContentFormatter()
        let content = FormattableTextContent(text: "Hello", ranges: [])
        func fontSize(_ sizeClass: UIUserInterfaceSizeClass) throws -> CGFloat {
            let text = formatter.render(content: content, with: RichTextContentStyles(horizontalSizeClass: sizeClass))
            return try #require(text.attribute(.font, at: 0, effectiveRange: nil) as? UIFont).pointSize
        }

        #expect(try fontSize(.compact) == 14)
        #expect(try fontSize(.regular) == 16)
        #expect(try fontSize(.compact) == 14)
    }
}
