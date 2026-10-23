import Testing
import UIKit
import WordPressShared
@testable import WordPress
@testable import FormattableContentKit

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

    @Test("the size class comes from the window, not from the view")
    func sizeClassComesFromTheWindow() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 1024, height: 768))
        window.traitOverrides.horizontalSizeClass = .regular
        // Stands in for a split view column, which reports a compact size class inside a wide window.
        let column = UIView()
        column.traitOverrides.horizontalSizeClass = .compact
        let view = UIView()
        window.addSubview(column)
        column.addSubview(view)
        view.updateTraitsIfNeeded()

        #expect(view.traitCollection.horizontalSizeClass == .compact)
        #expect(WPStyleGuide.Notifications.horizontalSizeClass(for: view) == .regular)
    }

    @Test("a view outside a window uses its own size class")
    func sizeClassWithoutAWindow() {
        let view = UIView()
        view.traitOverrides.horizontalSizeClass = .regular
        view.updateTraitsIfNeeded()

        #expect(WPStyleGuide.Notifications.horizontalSizeClass(for: view) == .regular)
    }
}
