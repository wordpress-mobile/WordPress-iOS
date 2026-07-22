import AVFoundation
import CoreGraphics
import Foundation
import ImageIO
import MediaTransformer
import UniformTypeIdentifiers

// Shared image fixtures for the media upload tests. Used by both
// `UploadSourceMaterializerTests` (end-to-end, in `WordPressMediaLibraryTests`)
// and `MediaTransformerTests` (the transform engine in isolation).
//
// This module is UIKit-free — fixtures render through CoreGraphics rather than
// `UIGraphicsImageRenderer` — so `MediaTransformer` and its tests build on macOS
// for a fast `swift test` without Xcode.

enum FixtureError: Error { case encodingFailed, imageUnavailable }

let fixtureDateTimeOriginal = "2026:01:01 12:00:00"

/// The handful of solid fill colours the image fixtures use. Modelled as an enum
/// (rather than `UIColor`) so call sites keep reading `color: .red` while the
/// module stays UIKit-free.
enum FixtureColor {
    case red, green, blue

    var cgColor: CGColor {
        switch self {
        case .red: return CGColor(srgbRed: 1, green: 0, blue: 0, alpha: 1)
        case .green: return CGColor(srgbRed: 0, green: 1, blue: 0, alpha: 1)
        case .blue: return CGColor(srgbRed: 0, green: 0, blue: 1, alpha: 1)
        }
    }
}

/// A `MediaUploadPolicy` with test defaults; pass only the knobs a test cares
/// about. Video fields are fixed — the image transformer never reads them.
func makeUploadPolicy(
    allow: @escaping @Sendable (UTType, String) -> Bool = { _, _ in true },
    imageMaxDimension: Int? = nil,
    imageJpegQuality: Double = 0.9,
    convertHEICToJPEG: Bool = true,
    videoMaxDurationSeconds: TimeInterval? = nil,
    videoMaxDimension: Int? = nil,
    stripLocation: Bool = false,
    normalizeImageOrientation: Bool = false
) -> MediaUploadPolicy {
    MediaUploadPolicy(
        filePickerContentTypes: [.content],
        isAllowedForUpload: allow,
        imageMaxDimension: imageMaxDimension,
        imageJpegQuality: imageJpegQuality,
        convertHEICToJPEG: convertHEICToJPEG,
        normalizeImageOrientation: normalizeImageOrientation,
        videoMaxDurationSeconds: videoMaxDurationSeconds,
        videoMaxDimension: videoMaxDimension,
        videoExportPreset: AVAssetExportPresetMediumQuality,
        videoOutputContentType: .mpeg4Movie,
        stripLocation: stripLocation
    )
}

/// A solid-colour image. Opaque device-RGB — no alpha channel — matching the old
/// opaque renderer format so a later re-encode doesn't trip ImageIO's "opaque
/// image with AlphaLast" warnings.
func makeSolidColorImage(size: CGSize, color: FixtureColor) throws -> CGImage {
    let width = Int(size.width)
    let height = Int(size.height)
    guard
        let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        )
    else { throw FixtureError.encodingFailed }
    context.setFillColor(color.cgColor)
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    guard let image = context.makeImage() else { throw FixtureError.imageUnavailable }
    return image
}

/// A high-frequency image (per-pixel varying color) whose JPEG re-encode is
/// visibly lossy, unlike a flat fill — so a lossless strip is distinguishable
/// from a decode + recompress by comparing decoded pixels.
func makeDetailedImage(size: CGSize) throws -> CGImage {
    let width = Int(size.width)
    let height = Int(size.height)
    guard
        let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        )
    else { throw FixtureError.encodingFailed }
    for y in 0..<height {
        for x in 0..<width {
            let checker = (x / 2 + y / 2) % 2 == 0
            context.setFillColor(
                red: checker ? 0.9 : 0.1,
                green: CGFloat(x) / CGFloat(width),
                blue: CGFloat(y) / CGFloat(height),
                alpha: 1
            )
            context.fill(CGRect(x: x, y: y, width: 1, height: 1))
        }
    }
    guard let image = context.makeImage() else { throw FixtureError.imageUnavailable }
    return image
}

/// Encodes an image as `type`, attaching any extra image properties such as
/// orientation or GPS. Centralizes the `CGImageDestination` boilerplate the
/// image fixtures would otherwise each repeat.
func encodeImage(
    _ image: CGImage,
    as type: UTType,
    properties: [CFString: Any] = [:]
) throws -> Data {
    let out = NSMutableData()
    guard
        let dst = CGImageDestinationCreateWithData(out, type.identifier as CFString, 1, nil)
    else {
        throw FixtureError.encodingFailed
    }
    CGImageDestinationAddImage(dst, image, properties as CFDictionary)
    guard CGImageDestinationFinalize(dst) else {
        throw FixtureError.encodingFailed
    }
    return out as Data
}

/// Synthetic JPEG carrying both a GPS dictionary and an EXIF capture date,
/// for GPS-stripping tests and tests that pin the resize path's metadata
/// handling.
func makeJPEGWithGPSAndDate() throws -> Data {
    let image = try makeSolidColorImage(size: CGSize(width: 128, height: 128), color: .green)
    let gps: [CFString: Any] = [
        kCGImagePropertyGPSLatitude: 37.33,
        kCGImagePropertyGPSLongitude: -122.03
    ]
    let exif: [CFString: Any] = [
        kCGImagePropertyExifDateTimeOriginal: fixtureDateTimeOriginal
    ]
    return try encodeImage(
        image,
        as: .jpeg,
        properties: [
            kCGImagePropertyGPSDictionary: gps,
            kCGImagePropertyExifDictionary: exif
        ]
    )
}

/// Synthetic JPEG with GPS + EXIF date over high-frequency content, for proving
/// the GPS strip is a lossless container rewrite (decoded pixels unchanged)
/// rather than a decode + re-encode.
func makeDetailedJPEGWithGPSAndDate() throws -> Data {
    try encodeImage(
        makeDetailedImage(size: CGSize(width: 96, height: 96)),
        as: .jpeg,
        properties: [
            kCGImagePropertyGPSDictionary: [
                kCGImagePropertyGPSLatitude: 37.33,
                kCGImagePropertyGPSLongitude: -122.03
            ],
            kCGImagePropertyExifDictionary: [
                kCGImagePropertyExifDateTimeOriginal: fixtureDateTimeOriginal
            ]
        ]
    )
}

/// Synthetic PNG carrying a GPS dictionary. PNG keeps its GPS in a binary eXIf
/// chunk a metadata-only rewrite can't touch, so this drives the strip's
/// re-encode fallback.
func makePNGWithGPS() throws -> Data {
    try encodeImage(
        makeSolidColorImage(size: CGSize(width: 48, height: 48), color: .green),
        as: .png,
        properties: [
            kCGImagePropertyGPSDictionary: [
                kCGImagePropertyGPSLatitude: 37.33,
                kCGImagePropertyGPSLongitude: -122.03
            ]
        ]
    )
}

/// Synthetic HEIC, optionally carrying a specific EXIF orientation tag and/or a
/// GPS dictionary. Works on iOS 17+ simulator.
func makeSyntheticHEIC(
    orientation: CGImagePropertyOrientation? = nil,
    gps: Bool = false
) throws -> Data {
    let image = try makeSolidColorImage(size: CGSize(width: 64, height: 64), color: .blue)
    var properties: [CFString: Any] = [:]
    if let orientation {
        properties[kCGImagePropertyOrientation] = orientation.rawValue
    }
    if gps {
        properties[kCGImagePropertyGPSDictionary] = [
            kCGImagePropertyGPSLatitude: 37.33,
            kCGImagePropertyGPSLongitude: -122.03
        ]
    }
    return try encodeImage(image, as: .heic, properties: properties)
}

func imageProperties(of url: URL) throws -> [CFString: Any] {
    guard
        let src = CGImageSourceCreateWithURL(url as CFURL, nil),
        let props = CGImageSourceCopyPropertiesAtIndex(src, 0, nil) as? [CFString: Any]
    else { throw FixtureError.imageUnavailable }
    return props
}

func imageType(of url: URL) -> UTType? {
    guard
        let src = CGImageSourceCreateWithURL(url as CFURL, nil),
        let type = CGImageSourceGetType(src)
    else { return nil }
    return UTType(type as String)
}

/// The GPS-presence check both suites assert with. Delegates to production's
/// fail-closed post-write predicate so the test oracle can't drift from the
/// exact check `stripGPSLosslessly` trusts.
func imageHasGPS(_ url: URL) -> Bool {
    MediaTransformer.fileHasGPS(url)
}

/// The colour model ImageIO reports for `url` (e.g. "RGB", "CMYK").
func imageColorModel(of url: URL) -> String? {
    guard
        let src = CGImageSourceCreateWithURL(url as CFURL, nil),
        let props = CGImageSourceCopyPropertiesAtIndex(src, 0, nil) as? [CFString: Any]
    else { return nil }
    return props[kCGImagePropertyColorModel] as? String
}

/// Samples the sRGB pixel at (`x`, `y`) of the image at `url`, drawing through a
/// colour-managed context so the recovered hue can be asserted — this catches an
/// inverted or corrupt CMYK→RGB conversion, not just a colour-model relabel.
func imageSampleRGB(of url: URL, x: Int, y: Int) -> (r: Int, g: Int, b: Int)? {
    guard
        let src = CGImageSourceCreateWithURL(url as CFURL, nil),
        let image = CGImageSourceCreateImageAtIndex(src, 0, nil),
        x >= 0, y >= 0, x < image.width, y < image.height,
        let space = CGColorSpace(name: CGColorSpace.sRGB)
    else { return nil }
    let width = image.width
    let height = image.height
    var buffer = [UInt8](repeating: 0, count: width * height * 4)
    let drew = buffer.withUnsafeMutableBytes { raw -> Bool in
        guard
            let context = CGContext(
                data: raw.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: space,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        else { return false }
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        return true
    }
    guard drew else { return nil }
    let i = (y * width + x) * 4
    return (Int(buffer[i]), Int(buffer[i + 1]), Int(buffer[i + 2]))
}

/// Decodes `url` to a raw RGBA pixel buffer so two images can be compared for
/// pixel-exact equality independent of their container/metadata bytes.
func decodedPixels(of url: URL) throws -> Data {
    guard
        let source = CGImageSourceCreateWithURL(url as CFURL, nil),
        let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
    else { throw FixtureError.imageUnavailable }
    let width = image.width
    let height = image.height
    var buffer = [UInt8](repeating: 0, count: width * height * 4)
    let drew = buffer.withUnsafeMutableBytes { raw -> Bool in
        guard
            let context = CGContext(
                data: raw.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
            )
        else { return false }
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        return true
    }
    guard drew else { throw FixtureError.encodingFailed }
    return Data(buffer)
}

/// Synthetic JPEG carrying textual IPTC place names (City/State/Country) plus a
/// non-location caption/byline and EXIF GPS — the third-party / reverse-
/// geocoding-app shape the "Remove Location" strip must fully cover without
/// dropping the caption.
func makeJPEGWithTextualLocation() throws -> Data {
    try encodeImage(
        makeSolidColorImage(size: CGSize(width: 64, height: 64), color: .green),
        as: .jpeg,
        properties: [
            kCGImagePropertyIPTCDictionary: [
                kCGImagePropertyIPTCCity: "Cupertino",
                kCGImagePropertyIPTCProvinceState: "CA",
                kCGImagePropertyIPTCCountryPrimaryLocationName: "USA",
                kCGImagePropertyIPTCSubLocation: "Infinite Loop",
                kCGImagePropertyIPTCCaptionAbstract: "A nice photo",
                kCGImagePropertyIPTCByline: "Jane Doe"
            ],
            kCGImagePropertyGPSDictionary: [
                kCGImagePropertyGPSLatitude: 37.33,
                kCGImagePropertyGPSLongitude: -122.03
            ]
        ]
    )
}

/// The IPTC sub-dictionary of a written image (for asserting a location strip
/// dropped place names while keeping the caption).
func imageIPTC(of url: URL) throws -> [CFString: Any] {
    (try imageProperties(of: url))[kCGImagePropertyIPTCDictionary] as? [CFString: Any] ?? [:]
}

/// A multi-image HEIC whose primary is item 1 (a distinct size from item 0), so
/// a hardcoded index-0 read would pick the wrong frame.
func makeMultiImageHEIC(item0: CGSize, primary: CGSize) throws -> Data {
    let out = NSMutableData()
    guard let dst = CGImageDestinationCreateWithData(out, UTType.heic.identifier as CFString, 2, nil) else {
        throw FixtureError.encodingFailed
    }
    let cg0 = try makeSolidColorImage(size: item0, color: .red)
    let cg1 = try makeSolidColorImage(size: primary, color: .blue)
    CGImageDestinationAddImage(dst, cg0, nil)
    CGImageDestinationAddImage(dst, cg1, [kCGImagePropertyPrimaryImage: true] as CFDictionary)
    guard CGImageDestinationFinalize(dst) else { throw FixtureError.encodingFailed }
    return out as Data
}

/// A Display-P3 (wide-gamut) JPEG, for asserting the transform keeps the profile.
func makeP3JPEG(size: CGSize) throws -> Data {
    guard
        let p3 = CGColorSpace(name: CGColorSpace.displayP3),
        let ctx = CGContext(
            data: nil,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: p3,
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        )
    else { throw FixtureError.encodingFailed }
    ctx.setFillColor(red: 1, green: 0, blue: 0, alpha: 1)
    ctx.fill(CGRect(origin: .zero, size: size))
    guard let cg = ctx.makeImage() else { throw FixtureError.imageUnavailable }
    let out = NSMutableData()
    guard let dst = CGImageDestinationCreateWithData(out, UTType.jpeg.identifier as CFString, 1, nil) else {
        throw FixtureError.encodingFailed
    }
    CGImageDestinationAddImage(dst, cg, [kCGImageDestinationLossyCompressionQuality: 0.9] as CFDictionary)
    guard CGImageDestinationFinalize(dst) else { throw FixtureError.encodingFailed }
    return out as Data
}

/// Whether the image at `url` decodes to a wide-gamut (Display P3) color space.
func imageIsWideGamut(of url: URL) -> Bool {
    guard
        let src = CGImageSourceCreateWithURL(url as CFURL, nil),
        let img = CGImageSourceCreateImageAtIndex(src, 0, nil)
    else { return false }
    return img.colorSpace?.isWideGamutRGB ?? false
}

/// A HEIC whose right half is transparent, for asserting alpha is flattened when
/// a non-web-safe alpha source is converted to JPEG.
func makeTransparentHEIC(size: CGSize) throws -> Data {
    let width = Int(size.width)
    let height = Int(size.height)
    // Alpha-enabled context; only the left half is filled, so the right half
    // stays transparent and the HEIC carries a real alpha channel.
    guard
        let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
    else { throw FixtureError.encodingFailed }
    context.setFillColor(FixtureColor.red.cgColor)
    context.fill(CGRect(x: 0, y: 0, width: width / 2, height: height))
    guard let image = context.makeImage() else { throw FixtureError.imageUnavailable }
    return try encodeImage(image, as: .heic)
}

/// Whether the image at `url` reports an alpha channel.
func imageHasAlpha(of url: URL) -> Bool {
    ((try? imageProperties(of: url))?[kCGImagePropertyHasAlpha] as? Bool) ?? false
}
