// Composes the App Store screenshots from the raw screenshots the `AppStoreScreenshots` UI test
// captures: a headline over a soft background, and the screenshot in a device frame.
//
// Run by `bundle exec fastlane create_jetpack_promo_screenshots` and `create_promo_screenshots`, as:
//
//     xcrun swift compose.swift [--logo <pdf>] <raw screenshots> <headlines> <output> [<overview>]
//
// - --logo is the PDF drawn above the title screen's headline: the app's logo. Without it, the
//   title screen has the headline alone.
// - <raw screenshots> has a folder per locale holding `<device>-<index>-<name>.png`.
// - <headlines> has a folder per locale holding the headline strings (see `Headlines`). A locale
//   without all of them is skipped, so the App Store shows the English screenshots there rather
//   than an English headline over a translated app.
// - <output> gets a folder per locale holding `<iPhone|iPad>-<index>-<name>.png`. The App Store
//   orders screenshots by file name, and tells which device they're for by their size.
// - <overview>, when given, gets one image per locale and device showing all its screenshots side
//   by side, for reviewing the layout of every language at a glance.
//
// Every headline is fitted to its language: see `HeadlineLayout`. See also
// docs/app-store-screenshots.md.

import AppKit
import CoreText
import Foundation
import ImageIO
import NaturalLanguage
import UniformTypeIdentifiers

// MARK: - Headlines

/// The text drawn on one locale's screenshots, read from its folder:
///
/// - `screenshot_title.txt`: the title screen's headline.
/// - `screenshot_<n>_feature.txt`: the feature screenshot `n` shows, in bold: "Stats."
/// - `screenshot_<n>_headline.txt`: what follows it: "Your metrics, wherever you are."
///
/// The feature and headline are separate strings, rather than one with markup or a rule for where
/// the bold ends, so that translators can't break the formatting and every language gets its bold
/// lead.
struct Headlines {
    let title: String
    let features: [Int: (feature: String, headline: String)]

    init?(folder: URL, indices: [Int], missing: inout [String]) {
        func read(_ name: String) -> String? {
            let text = (try? String(contentsOf: folder.appending(path: name), encoding: .utf8))?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if text?.isEmpty ?? true {
                missing.append(name)
                return nil
            }
            return text
        }

        let title = read("screenshot_title.txt")
        var features: [Int: (String, String)] = [:]
        for index in indices {
            let feature = read("screenshot_\(index)_feature.txt")
            let headline = read("screenshot_\(index)_headline.txt")
            if let feature, let headline {
                features[index] = (feature, headline)
            }
        }
        guard let title, missing.isEmpty else { return nil }
        self.title = title
        self.features = features
    }
}

// MARK: - Fonts

/// The headline fonts for a language: the system serif, New York, with a serif fallback for the
/// scripts it doesn't cover. Every font here ships with macOS, so CI renders the same as a Mac
/// does. (The Nanum fonts, for instance, are a download, so Korean uses AppleMyungjo.)
struct Typeface {
    let language: String

    /// The fallback for the language's script, as PostScript names: regular, then bold. A font
    /// without a bold has the same name twice, and is emboldened by stroking it.
    private var fallback: (regular: String, bold: String)? {
        switch language.prefix(2) {
        case "ja": ("HiraMinProN-W3", "HiraMinProN-W6")
        case "zh":
            language.contains("Hant")
                ? ("STSongti-TC-Regular", "STSongti-TC-Bold") : ("STSongti-SC-Regular", "STSongti-SC-Bold")
        case "ko": ("AppleMyungjo", "AppleMyungjo")
        case "ar": ("TimesNewRomanPSMT", "TimesNewRomanPS-BoldMT")
        case "he": ("NewPeninimMT", "NewPeninimMT-Bold")
        default: nil
        }
    }

    /// Whether the script's bold has to be faked, by stroking the regular weight.
    var synthesizesBold: Bool { fallback.map { $0.regular == $0.bold } ?? false }

    /// Scripts with tall marks need more room between lines.
    var lineHeightMultiple: CGFloat {
        switch language.prefix(2) {
        case "ja", "zh", "ko": 1.05
        case "ar", "he": 1.15
        default: 0.98
        }
    }

    /// Japanese and Chinese are set in their own serif throughout, with proportional punctuation,
    /// rather than falling back to it from New York: full-width punctuation leaves wide gaps.
    private var usesScriptFontThroughout: Bool { ["ja", "zh"].contains(String(language.prefix(2))) }

    /// Whether the language puts a space between sentences.
    var separatesSentences: Bool { !["ja", "zh"].contains(String(language.prefix(2))) }

    /// Whether lines can only break between words, at spaces.
    var breaksAtSpaces: Bool { !["ja", "zh"].contains(String(language.prefix(2))) }

    func font(size: CGFloat, bold: Bool) -> CTFont {
        if usesScriptFontThroughout, let fallback {
            let descriptor = CTFontDescriptorCreateWithAttributes(
                [
                    kCTFontNameAttribute: bold ? fallback.bold : fallback.regular,
                    kCTFontFeatureSettingsAttribute: [
                        [kCTFontOpenTypeFeatureTag: "palt", kCTFontOpenTypeFeatureValue: 1]
                    ]
                ] as CFDictionary
            )
            return CTFontCreateWithFontDescriptor(descriptor, size, nil)
        }
        let system = NSFont.systemFont(ofSize: size, weight: bold ? .bold : .regular)
        let serif = system.fontDescriptor.withDesign(.serif) ?? system.fontDescriptor
        var descriptor = serif as CTFontDescriptor
        if let fallback {
            let name = bold ? fallback.bold : fallback.regular
            descriptor = CTFontDescriptorCreateCopyWithAttributes(
                descriptor,
                [kCTFontCascadeListAttribute: [CTFontDescriptorCreateWithNameAndSize(name as CFString, size)]]
                    as CFDictionary
            )
        }
        return CTFontCreateWithFontDescriptor(descriptor, size, nil)
    }
}

// MARK: - Headline layout

/// A headline set at one size, as CoreText lays it out.
struct SetHeadline {
    let text: NSAttributedString
    let size: CGFloat

    /// Lays the text out in a column `width` wide.
    func lines(width: CGFloat) -> [CTLine] {
        let framesetter = CTFramesetterCreateWithAttributedString(text)
        let path = CGPath(rect: CGRect(x: 0, y: 0, width: width, height: 100_000), transform: nil)
        let frame = CTFramesetterCreateFrame(framesetter, CFRange(), path, nil)
        return CTFrameGetLines(frame) as! [CTLine]
    }

    func height(width: CGFloat) -> CGFloat {
        let framesetter = CTFramesetterCreateWithAttributedString(text)
        let size = CTFramesetterSuggestFrameSizeWithConstraints(
            framesetter,
            CFRange(),
            nil,
            CGSize(width: width, height: .greatestFiniteMagnitude),
            nil
        )
        return ceil(size.height)
    }
}

/// Fits headlines to a language: the size, and where the lines break.
///
/// - Each headline is set as large as it can be, up to `maxSize`, within `maxLines` lines,
///   without breaking a word in two.
/// - All of a locale's feature headlines share the smallest of those sizes, so they look like a set.
/// - The lines are then balanced: the column is narrowed as far as it goes without adding a line,
///   so a headline doesn't end with one word on a line of its own.
/// - A headline that doesn't fit even at `minSize` is set at `minSize` on as many lines as it
///   needs, and reported, so that someone can ask for a shorter translation.
struct HeadlineLayout {
    let typeface: Typeface
    let width: CGFloat
    let maxSize: CGFloat
    let minSize: CGFloat
    let maxLines: Int

    func set(_ feature: String?, _ headline: String, size: CGFloat) -> SetHeadline {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineHeightMultiple = typeface.lineHeightMultiple
        paragraph.lineBreakMode = .byWordWrapping

        let regular: [NSAttributedString.Key: Any] = [
            .font: typeface.font(size: size, bold: false),
            .foregroundColor: Palette.text,
            .paragraphStyle: paragraph,
            .kern: typeface.breaksAtSpaces ? -size * 0.015 : 0,
            .languageIdentifier: typeface.language
        ]
        let text = NSMutableAttributedString()
        if let feature {
            var bold = regular
            bold[.font] = typeface.font(size: size, bold: true)
            if typeface.synthesizesBold {
                bold[.strokeWidth] = -3.0
                bold[.strokeColor] = Palette.text
            }
            text.append(NSAttributedString(string: feature, attributes: bold))
            if typeface.separatesSentences {
                text.append(NSAttributedString(string: " ", attributes: regular))
            }
        }
        text.append(NSAttributedString(string: headline, attributes: regular))
        if !typeface.breaksAtSpaces {
            gluePhrases(in: text)
        }
        return SetHeadline(text: text, size: size)
    }

    /// Keeps each phrase of a language without spaces on one line.
    ///
    /// CoreText can break Japanese and Chinese between any two characters, which splits words:
    /// "サ / イト". This joins the characters of each word, as `NLTokenizer` finds them, with word
    /// joiners, and attaches to the word before them the tokens that can't start a line on their
    /// own: Japanese particles and endings, which are all hiragana, and punctuation. What's left
    /// are breaks between phrases.
    func gluePhrases(in text: NSMutableAttributedString) {
        let string = text.string
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = string
        tokenizer.setLanguage(NLLanguage(rawValue: String(typeface.language.prefix(2))))

        var tokens: [Range<String.Index>] = []
        tokenizer.enumerateTokens(in: string.startIndex..<string.endIndex) { range, _ in
            tokens.append(range)
            return true
        }

        // The places a line may break: the starts of tokens that can start a line.
        var breaks = Set<String.Index>()
        for (previous, token) in zip(tokens, tokens.dropFirst()) {
            let word = string[token]
            let attaches = word.unicodeScalars.allSatisfy { (0x3040...0x309F).contains($0.value) || $0.value == 0x30FC }
            // The honorific prefixes お and ご belong to the word after them: お知らせ.
            let followsPrefix = ["お", "ご"].contains(String(string[previous]))
            if typeface.language.hasPrefix("zh") || (!attaches && !followsPrefix) {
                breaks.insert(token.lowerBound)
            }
        }
        // Text between tokens is punctuation, which stays with what comes before it; a break can
        // come after it, where the next token starts.

        // Insert a word joiner everywhere else, from the end so the indices stay valid.
        let joiner = NSAttributedString(string: "\u{2060}", attributes: text.attributes(at: 0, effectiveRange: nil))
        var index = string.index(before: string.endIndex)
        while index > string.startIndex {
            if !breaks.contains(index) {
                let offset = NSRange(index..<index, in: string).location
                text.insert(joiner, at: offset)
            }
            index = string.index(before: index)
        }
    }

    /// Whether the headline fits in `width` within `lines` lines, without breaking a word.
    func fits(_ headline: SetHeadline, width: CGFloat, lines maxLines: Int) -> Bool {
        let lines = headline.lines(width: width)
        guard lines.count <= maxLines else { return false }
        guard typeface.breaksAtSpaces else { return true }

        // CoreText breaks a word that's wider than the column. Every line but the last must end
        // at a space or a hyphen.
        let string = headline.text.string as NSString
        for line in lines.dropLast() {
            let range = CTLineGetStringRange(line)
            let last = string.substring(with: NSRange(location: range.location + range.length - 1, length: 1))
            if !(last == " " || last == "-" || last == "\u{2010}" || last == "\n") {
                return false
            }
        }
        return true
    }

    /// The largest size the headline fits at, or nil when it doesn't fit even at `minSize`.
    func largestSize(_ feature: String?, _ headline: String) -> CGFloat? {
        var size = maxSize
        while size >= minSize {
            if fits(set(feature, headline, size: size), width: width, lines: maxLines) {
                return size
            }
            size = (size * 0.97).rounded(.down)
        }
        return nil
    }

    /// The narrowest column that keeps the headline on as few lines as it takes at full width.
    func balancedWidth(_ headline: SetHeadline) -> CGFloat {
        let lineCount = headline.lines(width: width).count
        guard lineCount > 1 else { return width }

        var low = width * 0.4
        var high = width
        while high - low > 2 {
            let mid = (low + high) / 2
            if fits(headline, width: mid, lines: lineCount) {
                high = mid
            } else {
                low = mid
            }
        }
        return high
    }
}

// MARK: - Drawing

enum Palette {
    static let background = CGColor(srgbRed: 0.965, green: 0.965, blue: 0.95, alpha: 1)
    static let green = CGColor(srgbRed: 0.76, green: 0.91, blue: 0.68, alpha: 1)
    static let blue = CGColor(srgbRed: 0.75, green: 0.84, blue: 0.95, alpha: 1)
    static let text = CGColor(srgbRed: 0.06, green: 0.08, blue: 0.09, alpha: 1)
    static let frameLight = CGColor(srgbRed: 0.87, green: 0.87, blue: 0.88, alpha: 1)
    static let frameDark = CGColor(srgbRed: 0.56, green: 0.57, blue: 0.59, alpha: 1)
}

let sRGB = CGColorSpace(name: CGColorSpace.sRGB)!

/// Where things go on the canvas, in fractions of its width.
struct Layout {
    /// The canvas, in pixels. It's the raw screenshot's size, which the App Store accepts.
    let canvas: CGSize
    let headlineTop: CGFloat
    let headlineWidth: CGFloat
    let headlineSizes: ClosedRange<CGFloat>
    let titleSizes: ClosedRange<CGFloat>
    /// The device's width, including its frame.
    let deviceWidth: CGFloat
    /// The gap between the headline and the device.
    let deviceSpacing: CGFloat
    let bezel: CGFloat
    /// The radius of the screen's corners, as a fraction of the screen's width.
    let screenCornerRadius: CGFloat
    let logoHeight: CGFloat

    func px(_ fraction: CGFloat) -> CGFloat { (fraction * canvas.width).rounded() }

    /// The layout for a raw screenshot, by its size, and the name its composed files start with.
    ///
    /// The App Store orders a device's screenshots by file name. An iPhone Duo's outer and inner
    /// display share one set, so their names put the inner display, the larger, first.
    static func forScreenshot(of size: CGSize) -> (kind: String, layout: Layout) {
        let aspect = size.width / size.height
        switch (Int(size.width), Int(size.height)) {
        case (2007, 2853):
            // iPhone Duo, inner display: nearly as square as an iPad, with smaller corners than a phone.
            return ("DuoInner", Layout(
                canvas: size,
                headlineTop: 0.065,
                headlineWidth: 0.8,
                headlineSizes: 0.045...0.068,
                titleSizes: 0.06...0.09,
                deviceWidth: 0.78,
                deviceSpacing: 0.045,
                bezel: 0.018,
                screenCornerRadius: 0.035,
                logoHeight: 0.15
            ))
        case (1398, 2034):
            // iPhone Duo, outer display: a short phone.
            return ("DuoOuter", Layout(
                canvas: size,
                headlineTop: 0.065,
                headlineWidth: 0.82,
                headlineSizes: 0.05...0.075,
                titleSizes: 0.065...0.095,
                deviceWidth: 0.74,
                deviceSpacing: 0.045,
                bezel: 0.024,
                screenCornerRadius: 0.09,
                logoHeight: 0.17
            ))
        default:
            break
        }
        if aspect > 0.6 {
            return ("iPad", Layout(
                canvas: size,
                headlineTop: 0.065,
                headlineWidth: 0.8,
                headlineSizes: 0.04...0.062,
                titleSizes: 0.055...0.085,
                deviceWidth: 0.8,
                deviceSpacing: 0.045,
                bezel: 0.016,
                screenCornerRadius: 0.025,
                logoHeight: 0.14
            ))
        }
        return ("iPhone", Layout(
            canvas: size,
            headlineTop: 0.075,
            headlineWidth: 0.86,
            headlineSizes: 0.06...0.088,
            titleSizes: 0.075...0.11,
            deviceWidth: 0.86,
            deviceSpacing: 0.05,
            bezel: 0.026,
            screenCornerRadius: 0.13,
            logoHeight: 0.2
        ))
    }
}

func drawBackground(_ context: CGContext, size: CGSize) {
    context.setFillColor(Palette.background)
    context.fill(CGRect(origin: .zero, size: size))

    // Two soft washes of colour: green from the top right, blue from the bottom left. The
    // context's origin is at the bottom left.
    let washes: [(CGColor, CGPoint, CGFloat)] = [
        (Palette.green, CGPoint(x: size.width, y: size.height * 0.92), size.width * 0.95),
        (Palette.blue, CGPoint(x: 0, y: size.height * 0.3), size.width * 0.8)
    ]
    for (color, center, radius) in washes {
        let gradient = CGGradient(
            colorsSpace: sRGB,
            colors: [color.copy(alpha: 0.9)!, color.copy(alpha: 0)!] as CFArray,
            locations: [0, 1]
        )!
        context.drawRadialGradient(
            gradient,
            startCenter: center,
            startRadius: 0,
            endCenter: center,
            endRadius: radius,
            options: []
        )
    }
}

/// Draws the headline centred, in a column `width` wide with its top `top` from the canvas's top,
/// and returns the distance from the canvas's top to its bottom.
@discardableResult
func draw(_ headline: SetHeadline, width: CGFloat, top: CGFloat, context: CGContext, canvas: CGSize) -> CGFloat {
    let height = headline.height(width: width)
    // Spare room below the text, so that CoreText doesn't drop the last line for want of a pixel.
    let slack = headline.size
    let rect = CGRect(
        x: (canvas.width - width) / 2,
        y: canvas.height - top - height - slack,
        width: width,
        height: height + slack
    )
    let framesetter = CTFramesetterCreateWithAttributedString(headline.text)
    let frame = CTFramesetterCreateFrame(framesetter, CFRange(), CGPath(rect: rect, transform: nil), nil)
    CTFrameDraw(frame, context)
    return top + height
}

/// Draws the screenshot in a device frame, with the frame's top edge `top` from the canvas's top.
func drawDevice(_ screenshot: CGImage, top: CGFloat, layout: Layout, context: CGContext) {
    let canvas = layout.canvas
    let bezel = layout.px(layout.bezel)
    let rim = max(2, (bezel * 0.22).rounded())
    let aspect = CGFloat(screenshot.height) / CGFloat(screenshot.width)
    var screenWidth = layout.px(layout.deviceWidth) - 2 * bezel
    var screenHeight = screenWidth * aspect

    // Keep the whole device on the canvas, with a margin below it.
    let available = canvas.height - top - layout.px(0.05) - 2 * bezel
    if screenHeight > available {
        screenHeight = available
        screenWidth = screenHeight / aspect
    }
    let device = CGRect(
        x: ((canvas.width - screenWidth) / 2 - bezel).rounded(),
        y: (canvas.height - top - screenHeight - 2 * bezel).rounded(),
        width: screenWidth + 2 * bezel,
        height: screenHeight + 2 * bezel
    )
    let screen = device.insetBy(dx: bezel, dy: bezel)
    let screenRadius = screenWidth * layout.screenCornerRadius
    let deviceRadius = screenRadius + bezel
    func roundedRect(_ rect: CGRect, _ radius: CGFloat) -> CGPath {
        CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
    }

    // A soft shadow under the device.
    context.saveGState()
    context.setShadow(
        offset: CGSize(width: 0, height: -bezel * 0.8),
        blur: bezel * 3,
        color: CGColor(gray: 0, alpha: 0.22)
    )
    context.setFillColor(CGColor(gray: 0, alpha: 1))
    context.addPath(roundedRect(device, deviceRadius))
    context.fillPath()
    context.restoreGState()

    // The metal rim.
    context.saveGState()
    context.addPath(roundedRect(device, deviceRadius))
    context.clip()
    let metal = CGGradient(
        colorsSpace: sRGB,
        colors: [Palette.frameLight, Palette.frameDark, Palette.frameLight] as CFArray,
        locations: [0, 0.5, 1]
    )!
    context.drawLinearGradient(
        metal,
        start: CGPoint(x: device.minX, y: 0),
        end: CGPoint(x: device.maxX, y: 0),
        options: []
    )
    context.restoreGState()

    // The black border around the screen.
    context.setFillColor(CGColor(gray: 0, alpha: 1))
    context.addPath(roundedRect(device.insetBy(dx: rim, dy: rim), deviceRadius - rim))
    context.fillPath()

    // The screen.
    context.saveGState()
    context.addPath(roundedRect(screen, screenRadius))
    context.clip()
    context.interpolationQuality = .high
    context.draw(screenshot, in: screen)
    context.restoreGState()
}

func drawLogo(_ page: CGPDFPage, in rect: CGRect, context: CGContext) {
    let box = page.getBoxRect(.mediaBox)
    context.saveGState()
    context.translateBy(x: rect.minX, y: rect.minY)
    context.scaleBy(x: rect.width / box.width, y: rect.height / box.height)
    context.translateBy(x: -box.minX, y: -box.minY)
    context.drawPDFPage(page)
    context.restoreGState()
}

/// Draws into a canvas without an alpha channel, which the App Store requires.
func render(size: CGSize, _ draw: (CGContext) -> Void) -> CGImage {
    let context = CGContext(
        data: nil,
        width: Int(size.width),
        height: Int(size.height),
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: sRGB,
        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
    )!
    draw(context)
    return context.makeImage()!
}

func loadImage(_ url: URL) -> CGImage? {
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
    return CGImageSourceCreateImageAtIndex(source, 0, nil)
}

func writePNG(_ image: CGImage, to url: URL) throws {
    guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)
    else {
        throw CocoaError(.fileWriteUnknown, userInfo: [NSFilePathErrorKey: url.path])
    }
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else {
        throw CocoaError(.fileWriteUnknown, userInfo: [NSFilePathErrorKey: url.path])
    }
}

/// The screenshots side by side, scaled down, with a gap between them.
func overview(of images: [CGImage]) -> CGImage {
    let height: CGFloat = 900
    let gap: CGFloat = 30
    let widths = images.map { CGFloat($0.width) * height / CGFloat($0.height) }
    let size = CGSize(width: widths.reduce(0, +) + gap * CGFloat(images.count + 1), height: height + 2 * gap)
    return render(size: size) { context in
        context.setFillColor(CGColor(gray: 0.3, alpha: 1))
        context.fill(CGRect(origin: .zero, size: size))
        context.interpolationQuality = .high
        var x = gap
        for (image, width) in zip(images, widths) {
            context.draw(image, in: CGRect(x: x, y: gap, width: width, height: height))
            x += width + gap
        }
    }
}

// MARK: - Main

struct RawScreenshot {
    let file: URL
    let device: String
    let index: Int
    let name: String

    /// Parses `<device>-<index>-<name>.png`. The device's name can itself contain hyphens.
    init?(file: URL) {
        guard file.pathExtension == "png" else { return nil }
        let parts = file.deletingPathExtension().lastPathComponent.split(separator: "-")
        guard parts.count >= 3, let index = Int(parts[parts.count - 2]) else { return nil }
        self.file = file
        self.device = parts.dropLast(2).joined(separator: "-")
        self.index = index
        self.name = String(parts[parts.count - 1])
    }
}

var arguments = CommandLine.arguments
var logoURL: URL?
if let option = arguments.firstIndex(of: "--logo"), option + 1 < arguments.count {
    logoURL = URL(filePath: arguments[option + 1])
    arguments.removeSubrange(option...(option + 1))
}
guard (4...5).contains(arguments.count) else {
    FileHandle.standardError.write(
        Data("Usage: compose.swift [--logo <pdf>] <raw screenshots> <headlines> <output> [<overview>]\n".utf8)
    )
    exit(64)
}
let rawRoot = URL(filePath: arguments[1])
let headlinesRoot = URL(filePath: arguments[2])
let outputRoot = URL(filePath: arguments[3])
let overviewRoot = arguments.count > 4 ? URL(filePath: arguments[4]) : nil
let fileManager = FileManager.default

let logo = logoURL.flatMap { CGPDFDocument($0 as CFURL)?.page(at: 1) }
if let logoURL, logo == nil {
    print("Warning: couldn't load the logo from \(logoURL.standardized.path)")
}

var written = 0
var warnings: [String] = []
let locales = ((try? fileManager.contentsOfDirectory(atPath: rawRoot.path(percentEncoded: false))) ?? []).sorted()

for locale in locales {
    let files =
        (try? fileManager.contentsOfDirectory(at: rawRoot.appending(path: locale), includingPropertiesForKeys: nil))
        ?? []
    let screenshots = files.compactMap(RawScreenshot.init(file:))
        .sorted { ($0.device, $0.index) < ($1.device, $1.index) }
    guard !screenshots.isEmpty else { continue }

    var missing: [String] = []
    guard
        let headlines = Headlines(
            folder: headlinesRoot.appending(path: locale),
            indices: Set(screenshots.map(\.index)).sorted(),
            missing: &missing
        )
    else {
        print("Skipping \(locale): missing \(missing.joined(separator: ", "))")
        continue
    }

    let outputFolder = outputRoot.appending(path: locale)
    try fileManager.createDirectory(at: outputFolder, withIntermediateDirectories: true)
    let typeface = Typeface(language: locale)

    for device in Set(screenshots.map(\.device)).sorted() {
        let deviceScreenshots = screenshots.filter { $0.device == device }
        let images = deviceScreenshots.compactMap { screenshot in loadImage(screenshot.file).map { (screenshot, $0) } }
        guard let first = images.first?.1 else { continue }
        let (kind, layout) = Layout.forScreenshot(of: CGSize(width: first.width, height: first.height))
        var composed: [CGImage] = []

        // The feature headlines share one size: the largest every one of them fits at.
        let headlineLayout = HeadlineLayout(
            typeface: typeface,
            width: layout.px(layout.headlineWidth),
            maxSize: layout.px(layout.headlineSizes.upperBound),
            minSize: layout.px(layout.headlineSizes.lowerBound),
            maxLines: 2
        )
        var sizes: [CGFloat] = []
        for (screenshot, _) in images {
            let (feature, headline) = headlines.features[screenshot.index]!
            if let size = headlineLayout.largestSize(feature, headline) {
                sizes.append(size)
            } else {
                sizes.append(headlineLayout.minSize)
                warnings.append(
                    "\(locale) \(kind) \(screenshot.index): \"\(feature) \(headline)\" needs more than 2 lines"
                )
            }
        }
        let headlineSize = sizes.min() ?? headlineLayout.maxSize

        // Every device sits at the same height, below a band as tall as the tallest headline.
        let headlineBand =
            images.map { screenshot, _ in
                let (feature, headline) = headlines.features[screenshot.index]!
                let text = headlineLayout.set(feature, headline, size: headlineSize)
                return text.height(width: headlineLayout.balancedWidth(text))
            }
            .max() ?? 0

        // The title screen.
        let titleLayout = HeadlineLayout(
            typeface: typeface,
            width: layout.px(layout.headlineWidth * 0.9),
            maxSize: layout.px(layout.titleSizes.upperBound),
            minSize: layout.px(layout.titleSizes.lowerBound),
            maxLines: 3
        )
        let titleSize =
            titleLayout.largestSize(nil, headlines.title)
            ?? {
                warnings.append("\(locale) \(kind) title: \"\(headlines.title)\" needs more than 3 lines")
                return titleLayout.minSize
            }()
        let title = render(size: layout.canvas) { context in
            drawBackground(context, size: layout.canvas)
            var top = layout.canvas.height * 0.26
            if let logo {
                let box = logo.getBoxRect(.mediaBox)
                let height = layout.px(layout.logoHeight)
                let width = height * box.width / box.height
                let rect = CGRect(
                    x: (layout.canvas.width - width) / 2,
                    y: layout.canvas.height - top - height,
                    width: width,
                    height: height
                )
                drawLogo(logo, in: rect, context: context)
                top += height + layout.px(0.08)
            }
            let text = titleLayout.set(nil, headlines.title, size: titleSize)
            _ = draw(text, width: titleLayout.balancedWidth(text), top: top, context: context, canvas: layout.canvas)
        }
        try writePNG(title, to: outputFolder.appending(path: "\(kind)-0-Title.png"))
        composed.append(title)

        for (screenshot, image) in images {
            let (feature, headline) = headlines.features[screenshot.index]!
            let png = render(size: layout.canvas) { context in
                drawBackground(context, size: layout.canvas)
                let text = headlineLayout.set(feature, headline, size: headlineSize)
                let width = headlineLayout.balancedWidth(text)
                // A shorter headline is centred in the band.
                let top = layout.px(layout.headlineTop) + ((headlineBand - text.height(width: width)) / 2).rounded()
                draw(text, width: width, top: top, context: context, canvas: layout.canvas)
                let deviceTop = layout.px(layout.headlineTop) + headlineBand + layout.px(layout.deviceSpacing)
                drawDevice(image, top: deviceTop, layout: layout, context: context)
            }
            try writePNG(png, to: outputFolder.appending(path: "\(kind)-\(screenshot.index)-\(screenshot.name).png"))
            composed.append(png)
        }
        written += composed.count

        if let overviewRoot {
            try fileManager.createDirectory(at: overviewRoot, withIntermediateDirectories: true)
            try writePNG(overview(of: composed), to: overviewRoot.appending(path: "\(locale)-\(kind).png"))
        }
    }
    print("Composed \(locale)")
}

print("Wrote \(written) screenshots to \(outputRoot.standardized.path)")
if !warnings.isEmpty {
    print("\nThese headlines don't fit, and were set smaller on extra lines. Consider asking for shorter translations:")
    warnings.forEach { print("- \($0)") }
}
