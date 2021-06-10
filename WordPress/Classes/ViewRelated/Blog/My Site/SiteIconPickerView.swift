import SwiftUI
import UIKit

struct SiteIconPickerView: View {
    private let initialIcon = Image(systemName: "globe")

    var onCompletion: ((UIImage) -> Void)? = nil
    var onDismiss: (() -> Void)? = nil

    @SwiftUI.State private var currentIcon: String? = nil
    @SwiftUI.State private var currentBackgroundColor = UIColor.white

    var body: some View {
        ScrollView {
            VStack {
                titleText
                subtitleText
                iconPreview
                VStack(alignment: .leading) {
                    emojiSection
                    colorSection
                }
                Spacer()
                Button(action: { saveIcon() }) {
                    saveButton
                }
            }
            .padding()
        }
        .overlay(dismissButton, alignment: .topTrailing)
    }

    private var titleText: some View {
        Text(TextContent.title)
            .font(Font.system(.largeTitle, design: .serif))
            .fontWeight(.semibold)
            .padding(.top, Metrics.titleTopPadding)
    }

    private var subtitleText: some View {
        Text(TextContent.hint)
            .font(.footnote)
            .foregroundColor(.secondary)
            .lineLimit(5)   // For some reason the text won't wrap unless I set a specific line limit here
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding()
    }

    private var iconPreview: some View {
        RoundedRectangle(cornerRadius: Metrics.cornerRadius)
            .foregroundColor(Color(currentBackgroundColor))
            .frame(width: Metrics.previewSize, height: Metrics.previewSize)
            .overlay(previewOverlay)
            .overlay(
                RoundedRectangle(cornerRadius: Metrics.cornerRadius)
                    .stroke(Color.secondary, lineWidth: 1.0)
            )
            .padding(.vertical, Metrics.previewPadding)
    }

    private var previewOverlay: some View {
        if let currentIcon = currentIcon {
            let renderer = EmojiRenderer(emoji: currentIcon, backgroundColor: currentBackgroundColor)
            return Image(uiImage: renderer.render())
                .resizable()
                .frame(width: Metrics.previewIconSize, height: Metrics.previewIconSize)
                .foregroundColor(nil)
        } else {
            return initialIcon
                .resizable()
                .frame(width: Metrics.previewIconSize, height: Metrics.previewIconSize)
                .foregroundColor(Color.secondary)
        }
    }

    private var emojiSection: some View {
        Group {
            Text(TextContent.emojiSectionTitle)
                .font(.callout)
                .fontWeight(.bold)
            ScrollView(.horizontal, showsIndicators: false) {
                let columnCount = SiteIconPickerView.allEmoji.count / Metrics.emojiRowCount

                if #available(iOS 14.0, *) {
                    LazyHStack(alignment: .top) {
                        ForEach((0..<columnCount)) { index in
                            let startIndex = index * Metrics.emojiRowCount
                            let endIndex = min(startIndex + Metrics.emojiRowCount, SiteIconPickerView.allEmoji.count)

                            let emojis = Array(SiteIconPickerView.allEmoji[startIndex..<endIndex])
                            EmojiColumnView(emojis: emojis) { emoji in
                                currentIcon = emoji
                            }
                        }
                    }
                    .fixedSize()
                    .padding(.horizontal)
                }
                // TODO: Add a more limited selection of emoji for those not
                // on iOS 14 (due to a lack of LazyHStack) @frosty

            }
            .padding(.horizontal, Metrics.emojiSectionHorizontalPadding)
            .padding(.bottom, Metrics.emojiSectionBottomPadding)
        }
    }

    private var colorSection: some View {
        Group {
            Text(TextContent.colorSectionTitle)
                .font(.callout)
                .fontWeight(.bold)
            VStack(alignment: .leading) {
                colorsRow(0..<Metrics.colorColumnCount)
                colorsRow(Metrics.colorColumnCount..<colors.count)
            }
            .padding(.vertical, Metrics.colorSectionVerticalPadding)
        }
    }

    private func colorsRow(_ range: Range<Int>) -> some View {
        HStack {
            ForEach(colors[range], id: \.self) { color in
                ColorCircleView(color: Color(color), isSelected: currentBackgroundColor == color) {
                    currentBackgroundColor = color
                }
            }
        }
    }

    private var saveButton: some View {
        Text(TextContent.saveButtonTitle)
            .font(.body)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: Metrics.saveButtonHeight)
            .background(RoundedRectangle(cornerRadius: Metrics.cornerRadius).fill(Color(.primary)))
    }

    private func saveIcon() {
        if let currentIcon = currentIcon {
            let renderer = EmojiRenderer(emoji: currentIcon,
                                         backgroundColor: currentBackgroundColor)
            onCompletion?(renderer.render())
        }
    }

    private var dismissButton: some View {
        Button(action: {
            onDismiss?()
        }) {
            Image(systemName: "xmark")
                .foregroundColor(.black)
                .padding()
        }
    }

    private static let allEmoji: [String] = {
        do {
            if let url = Bundle.main.url(forResource: "Emoji", withExtension: "txt") {
               let data = try Data(contentsOf: url)
               let string = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
               return string?.components(separatedBy: "\n") ?? []
            }
        } catch {
            print(error)
        }

        return []
    }()

    private enum TextContent {
        static let title = NSLocalizedString("Create a site icon", comment: "")
        static let hint = NSLocalizedString("Your site icon is used across the web: in browser tabs, site previews on social media, and the WordPress.com Reader.", comment: "")
        static let emojiSectionTitle = NSLocalizedString("Emoji", comment: "")
        static let colorSectionTitle = NSLocalizedString("Background Color", comment: "")
        static let saveButtonTitle = NSLocalizedString("Save", comment: "")
    }

    private enum Metrics {
        static let titleTopPadding: CGFloat = 20
        static let cornerRadius: CGFloat = 8.0
        static let previewSize: CGFloat = 80.0
        static let previewIconSize: CGFloat = 60.0
        static let previewPadding: CGFloat = 10.0
        static let emojiRowCount = 3
        static let emojiSectionHorizontalPadding: CGFloat = -20.0
        static let emojiSectionBottomPadding: CGFloat = 10.0
        static let colorSectionVerticalPadding: CGFloat = 10.0
        static let colorColumnCount = 5
        static let saveButtonHeight: CGFloat = 44.0
    }
}

private struct EmojiColumnView: View {
    var emojis: [String]
    var action: (String) -> Void

    var body: some View {
        VStack {
            ForEach(emojis, id: \.self) { emoji in
                EmojiButton(emoji) {
                    action(emoji)
                }
            }
        }
    }
}

private struct ColorCircleView: View {
    var color: Color
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Circle()
                .foregroundColor(color)
                .frame(width: 44, height: 44)
                .padding(2)
                .overlay(isSelected ? Circle().stroke(Color.gray, lineWidth: 1.0) : Circle().stroke(Color(white: 0.8), lineWidth: 1.0))
                .padding(.bottom, 8)
                .padding(.trailing, 8)
        }
    }
}

struct EmojiRenderer {
    let emoji: String
    let backgroundColor: UIColor
    let imageSize: CGSize
    let insetSize: CGFloat

    init(emoji: String, backgroundColor: UIColor, imageSize: CGSize = CGSize(width: 512.0, height: 512.0), insetSize: CGFloat = 16.0) {
        self.emoji = emoji
        self.backgroundColor = backgroundColor
        self.imageSize = imageSize
        self.insetSize = insetSize
    }

    func render() -> UIImage {
        let rect = CGRect(origin: .zero, size: imageSize)
        let insetRect = rect.insetBy(dx: insetSize, dy: insetSize)

        // The size passed in here doesn't matter, we just need the descriptor
        let font = UIFont.fontFittingText(emoji, in: insetRect.size, fontDescriptor: UIFont.systemFont(ofSize: 100).fontDescriptor)

        let renderer = UIGraphicsImageRenderer(size: rect.size)
        let img = renderer.image { ctx in
            backgroundColor.setFill()
            ctx.fill(rect)

            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center

            let attrs: [NSAttributedString.Key : Any] = [.font: font, .paragraphStyle: paragraphStyle]
            emoji.draw(with: insetRect, options: .usesLineFragmentOrigin, attributes: attrs, context: nil)
        }

        return img
    }
}

struct EmojiButton: View {
    let emoji: String
    let action: () -> Void

    init(_ emoji: String, action: @escaping () -> Void) {
        self.emoji = emoji
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(emoji)
                .font(.largeTitle)
                .padding(2)
        }
    }
}


let colors = [
    UIColor(hex: "#d1e4dd"),
    UIColor(hex: "#d1dfe4"),
    UIColor(hex: "#d1d1e4"),
    UIColor(hex: "#e4d1d1"),
    UIColor(hex: "#e4dad1"),
    UIColor(hex: "#eeeadd"),
    UIColor(hex: "#ffffff"),
    UIColor(hex: "#39414d"),
    UIColor(hex: "#28303d"),
    UIColor.black
]
