import SwiftUI
import UIKit

@available(iOS 14.0, *)
struct SiteIconPickerView: View {
    private let initialIcon = Image("blavatar-default")

    var onCompletion: ((UIImage) -> Void)? = nil
    var onDismiss: (() -> Void)? = nil

    @SwiftUI.State private var currentIcon: String? = nil
    @SwiftUI.State private var currentBackgroundColor = UIColor(hex: "#969CA1")
    @SwiftUI.State private var scrollOffsetColumn: Int? = nil

    private var hasMadeSelection: Bool {
        currentIcon != nil
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: Metrics.mainStackSpacing) {
                    titleText
                    subtitleText
                    iconPreview
                    VStack(alignment: .leading, spacing: Metrics.mainStackSpacing) {
                        emojiSection
                        colorSection
                    }
                }
                .padding()
            }
            ZStack {
                Color(UIColor.basicBackground)
                Button(action: { saveIcon() }) {
                    saveButton
                }
                .padding()
                .disabled(!hasMadeSelection)
            }
            .fixedSize(horizontal: false, vertical: true)
            .overlay(saveButtonTopShadow, alignment: .top)
        }
        .overlay(dismissButton, alignment: .topTrailing)
    }

    // MARK: - Subviews

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
            let renderer = EmojiRenderer(emoji: currentIcon, backgroundColor: currentBackgroundColor,
                                         imageSize: CGSize(width: Metrics.previewSize, height: Metrics.previewSize),
                                         insetSize: 0)
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
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(alignment: .top) {
                        emojiStackContent
                    }
                    .fixedSize()
                    .padding(.horizontal)
                }
                .padding(.leading, -Metrics.emojiSectionHorizontalPadding)
                .padding(.trailing, -Metrics.emojiSectionHorizontalPadding)
                .padding(.bottom, Metrics.emojiSectionBottomPadding)
                .onAppear(perform: {
                    proxy.scrollTo(0, anchor: .leading)
                })

                emojiGroupPicker(proxy)
            }
        }
    }

    private var emojiStackContent: some View {
        Group {
            let columnCount = SiteIconPickerView.allEmoji.count / Metrics.emojiRowCount

            ForEach((0..<columnCount)) { index in
                let startIndex = index * Metrics.emojiRowCount
                let endIndex = min(startIndex + Metrics.emojiRowCount, SiteIconPickerView.allEmoji.count)

                let emojis = Array(SiteIconPickerView.allEmoji[startIndex..<endIndex])
                HStack() {
                    // Spacer used to pad content out from the leading edge when we
                    // scroll to a specific section
                    Spacer()
                        .frame(width: Metrics.emojiSectionHorizontalPadding)
                    EmojiColumnView(emojis: emojis) { emoji in
                        currentIcon = emoji
                    }
                }
                .id(index)  // Id allows us to scroll to a specific section
            }
        }
    }

    private func emojiGroupPicker(_ proxy: ScrollViewProxy) -> some View {
        Group {
            HStack(spacing: Metrics.emojiGroupPickerSpacing) {
                ForEach(SiteIconPickerView.emojiGroupIcons.indices, id: \.self) { index in
                    Button(action: {
                        proxy.scrollTo(SiteIconPickerView.emojiGroups[index], anchor: .leading)
                    }, label: {
                        let icon = SiteIconPickerView.emojiGroupIcons[index]

                        // Icons with a - prefix are custom icons, otherwise system icons
                        let image = icon.hasPrefix("-") ?
                            Image(String(icon.dropFirst())) : Image(systemName: icon)
                        image
                            .foregroundColor(Colors.emojiGroupPickerForeground)
                            .frame(width: Metrics.emojiGroupPickerSize, height: Metrics.emojiGroupPickerSize)
                            .padding(Metrics.emojiGroupPickerPadding)
                    })
                }
            }
            .padding(Metrics.emojiGroupPickerPadding)
            .frame(maxWidth: .infinity)
            .background(Capsule().foregroundColor(Colors.emojiGroupPickerBackground))
            .padding(.bottom, Metrics.emojiGroupPickerBottomPadding)
        }
    }

    private var colorSection: some View {
        Group {
            Text(TextContent.colorSectionTitle)
                .font(.callout)
                .fontWeight(.bold)
            VStack(alignment: .leading) {
                colorsRow(0..<Metrics.colorColumnCount)
                colorsRow(Metrics.colorColumnCount..<SiteIconPickerView.backgroundColors.count)
            }
            .padding(.vertical, Metrics.colorSectionVerticalPadding)
        }
    }

    private func colorsRow(_ range: Range<Int>) -> some View {
        HStack {
            ForEach(SiteIconPickerView.backgroundColors[range], id: \.self) { color in
                ColorCircleView(color: Color(color), isSelected: currentBackgroundColor == color) {
                    currentBackgroundColor = color
                }
            }
        }
    }

    private var saveButton: some View {
        Text(TextContent.saveButtonTitle)
            .font(.body)
            .foregroundColor(hasMadeSelection ? .white : .secondary)
            .frame(maxWidth: .infinity)
            .frame(height: Metrics.saveButtonHeight)
            .background(
                RoundedRectangle(cornerRadius: Metrics.cornerRadius)
                    .fill(hasMadeSelection ? Color(.primary) : Colors.disabledButton)
            )
    }

    private var saveButtonTopShadow: some View {
        LinearGradient(gradient: Gradient(colors: [
            Color(.sRGB, white: 0.0, opacity: 0.1),
            .clear
        ]), startPoint: .bottom, endPoint: .top)
        .frame(height: Metrics.saveButtonTopShadowHeight)
        .offset(x: 0, y: -Metrics.saveButtonTopShadowHeight)
    }

    // MARK: - Actions

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

    // MARK: - Emoji definitions

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

    // Some of these are only available in iOS 15, so we've added them to the
    // asset catalog as custom symbols. Those are marked with a - prefix,
    // so we know how to load them later.
    private static let emojiGroupIcons: [String] = [
        "face.smiling",
        "-pawprint",
        "-fork.knife",
        "gamecontroller",
        "building.2",
        "lightbulb",
        "x.squareroot",
        "flag"
    ]

    // Column number where this group of emoji begins
    private static let emojiGroups: [Int] = [
        0,      // smilies & people
        153,    // animals and nature
        217,    // food
        260,    // activities
        298,    // places
        342,    // objects
        414,    // symbols
        512     // flags
    ]

    // MARK: - Constants

    private enum TextContent {
        static let title = NSLocalizedString("Create a site icon", comment: "Title for the Site Icon Picker")
        static let hint = NSLocalizedString("Your site icon is used across the web: in browser tabs, site previews on social media, and the WordPress.com Reader.", comment: "Subtitle for the Site Icon Picker")
        static let emojiSectionTitle = NSLocalizedString("Emoji", comment: "Title for the Emoji section")
        static let colorSectionTitle = NSLocalizedString("Background Color", comment: "Title for the Background Color section")
        static let saveButtonTitle = NSLocalizedString("Save", comment: "Title for the button that will save the site icon")
    }

    private enum Metrics {
        static let titleTopPadding: CGFloat = 20

        static let mainStackSpacing: CGFloat = 10.0
        static let cornerRadius: CGFloat = 8.0

        static let previewSize: CGFloat = 80.0
        static let previewIconSize: CGFloat = 70.0
        static let previewPadding: CGFloat = 10.0

        static let emojiRowCount = 3
        static let emojiSectionHorizontalPadding: CGFloat = 20.0
        static let emojiSectionBottomPadding: CGFloat = 10.0

        static let emojiGroupPickerSpacing: CGFloat = 10.0
        static let emojiGroupPickerSize: CGFloat = 22.0
        static let emojiGroupPickerPadding: CGFloat = 2.0
        static let emojiGroupPickerBottomPadding: CGFloat = 10.0

        static let colorSectionVerticalPadding: CGFloat = 10.0
        static let colorColumnCount = 5

        static let saveButtonHeight: CGFloat = 44.0
        static let saveButtonTopShadowHeight: CGFloat = 6.0
    }

    private enum Colors {
        static let emojiGroupPickerForeground = Color(white: 0.5)
        static let emojiGroupPickerBackground = Color(white: 0.95)
        static let disabledButton = Color(white: 0.95)
    }

    private static let backgroundColors = [
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
}

private struct EmojiColumnView: View {
    let emojis: [String]
    let action: (String) -> Void

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

/// Displays a single emoji character in a button
///
private struct EmojiButton: View {
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

/// A circle filled with the specified color, and outlined with various
/// styles depending on whether or not it is currently selected
///
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
