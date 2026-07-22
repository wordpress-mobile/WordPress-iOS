import AVFoundation
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers

@testable import MediaTransformer

/// Direct tests for the image transform engine, exercised through its
/// `plan` → `write` API without the materializer, staging directories, or
/// filename allocation around it.
@Suite("MediaTransformer")
final class MediaTransformerTests {
    /// Per-test scratch directory for source fixtures and transform output.
    private let root = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)

    init() throws {
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }

    deinit {
        try? FileManager.default.removeItem(at: root)
    }

    // MARK: - plan: content type + extension decision

    @Test("plan: web-safe in-cap JPEG needs no transform")
    func planJPEGPassthrough() throws {
        let jpeg = try encodeImage(makeSolidColorImage(size: CGSize(width: 40, height: 40), color: .red), as: .jpeg)
        let plan = try MediaTransformer(policy: makeUploadPolicy()).plan(.data(jpeg), declaredType: .jpeg)
        #expect(plan.contentType == .jpeg)
        #expect(plan.fileExtension == "jpeg")
    }

    @Test("plan: web-safe in-cap PNG stays PNG")
    func planPNGPassthrough() throws {
        let png = try encodeImage(makeSolidColorImage(size: CGSize(width: 40, height: 40), color: .red), as: .png)
        let plan = try MediaTransformer(policy: makeUploadPolicy()).plan(.data(png), declaredType: .png)
        #expect(plan.contentType == .png)
        #expect(plan.fileExtension == "png")
    }

    @Test("plan: HEIC converts to JPEG when the policy asks")
    func planHEICConverts() throws {
        let heic = try makeSyntheticHEIC()
        let plan = try MediaTransformer(policy: makeUploadPolicy(convertHEICToJPEG: true))
            .plan(.data(heic), declaredType: .heic)
        #expect(plan.contentType == .jpeg)
        #expect(plan.fileExtension == "jpeg")
    }

    @Test("plan: HEIC stays HEIC when conversion is disabled and nothing else applies")
    func planHEICStaysHEICWithoutConversion() throws {
        let heic = try makeSyntheticHEIC()
        let plan = try MediaTransformer(policy: makeUploadPolicy(convertHEICToJPEG: false))
            .plan(.data(heic), declaredType: .heic)
        #expect(plan.contentType == .heic)
    }

    @Test("plan: the sniffed container type wins over a lying declared type")
    func planSniffsRealType() throws {
        // HEIC bytes announced as JPEG must still be seen as HEIC (and converted).
        let heic = try makeSyntheticHEIC()
        let plan = try MediaTransformer(policy: makeUploadPolicy()).plan(.data(heic), declaredType: .jpeg)
        #expect(plan.contentType == .jpeg) // converted from the real HEIC, not passed through
    }

    @Test("plan: a re-encode of a non-web-safe type targets JPEG")
    func planNonWebSafeReencodeTargetsJPEG() throws {
        // TIFF with conversion disabled: a resize still forces a re-encode, and
        // TIFF isn't web-writable, so the target must fall back to JPEG.
        let tiff = try encodeImage(makeSolidColorImage(size: CGSize(width: 128, height: 128), color: .red), as: .tiff)
        let plan = try MediaTransformer(policy: makeUploadPolicy(imageMaxDimension: 64, convertHEICToJPEG: false))
            .plan(.data(tiff), declaredType: .tiff)
        #expect(plan.contentType == .jpeg)
    }

    // MARK: - plan: validation

    @Test("plan: non-image bytes are rejected")
    func planRejectsNonImage() throws {
        let transformer = MediaTransformer(policy: makeUploadPolicy())
        #expect(throws: MediaTransformerError.self) {
            try transformer.plan(.data(Data("definitely not an image".utf8)), declaredType: .jpeg)
        }
    }

    @Test("plan: an HTML error body served as image/jpeg is rejected")
    func planRejectsHTMLBody() throws {
        let transformer = MediaTransformer(policy: makeUploadPolicy())
        let error = try? transformer.plan(
            .data(Data("<html><body>404 Not Found</body></html>".utf8)),
            declaredType: .jpeg
        )
        #expect(error == nil)
    }

    @Test("plan: empty data is rejected")
    func planRejectsEmpty() throws {
        let transformer = MediaTransformer(policy: makeUploadPolicy())
        #expect(throws: MediaTransformerError.self) {
            try transformer.plan(.data(Data()), declaredType: .jpeg)
        }
    }

    // MARK: - write: no-transform passthrough

    @Test("write: a no-transform URL input is copied byte-for-byte")
    func writeURLPassthroughByteIdentical() throws {
        let jpeg = try encodeImage(makeSolidColorImage(size: CGSize(width: 50, height: 50), color: .red), as: .jpeg)
        let source = try fixture(jpeg, ext: "jpg")
        let out = try transform(.url(source), declaredType: .jpeg, policy: makeUploadPolicy())
        #expect(try Data(contentsOf: out) == jpeg)
    }

    @Test("write: a no-transform Data input is written unchanged")
    func writeDataPassthroughByteIdentical() throws {
        let jpeg = try encodeImage(makeSolidColorImage(size: CGSize(width: 50, height: 50), color: .red), as: .jpeg)
        let out = try transform(.data(jpeg), declaredType: .jpeg, policy: makeUploadPolicy())
        #expect(try Data(contentsOf: out) == jpeg)
    }

    @Test("write: HEIC kept as HEIC (conversion off) is copied byte-for-byte")
    func writeHEICPassthroughByteIdentical() throws {
        let heic = try makeSyntheticHEIC()
        let out = try transform(.data(heic), declaredType: .heic, policy: makeUploadPolicy(convertHEICToJPEG: false))
        #expect(imageType(of: out) == .heic)
        #expect(try Data(contentsOf: out) == heic)
    }

    @Test("write: strip policy with no GPS present is a no-op passthrough")
    func writeStripWithoutGPSIsPassthrough() throws {
        let jpeg = try encodeImage(makeSolidColorImage(size: CGSize(width: 48, height: 48), color: .green), as: .jpeg)
        let out = try transform(.data(jpeg), declaredType: .jpeg, policy: makeUploadPolicy(stripLocation: true))
        #expect(!imageHasGPS(out))
        #expect(try Data(contentsOf: out) == jpeg) // untouched — nothing to strip
    }

    // MARK: - write: lossless GPS strip

    @Test("write: JPEG GPS strip is lossless and keeps other EXIF")
    func writeJPEGStripIsLossless() throws {
        let jpeg = try makeDetailedJPEGWithGPSAndDate()
        let source = try fixture(jpeg, ext: "jpg")
        let out = try transform(.url(source), declaredType: .jpeg, policy: makeUploadPolicy(stripLocation: true))

        let props = try imageProperties(of: out)
        #expect(props[kCGImagePropertyGPSDictionary] == nil)
        let exif = props[kCGImagePropertyExifDictionary] as? [CFString: Any]
        #expect(exif?[kCGImagePropertyExifDateTimeOriginal] as? String == fixtureDateTimeOriginal)
        #expect(imageType(of: out) == .jpeg)
        // Lossless container rewrite: decoding the output yields the source pixels.
        #expect(try decodedPixels(of: out) == decodedPixels(of: source))
    }

    @Test("write: located HEIC converts to JPEG and strips GPS")
    func writeHEICWithGPSConvertsAndStrips() throws {
        let heic = try makeSyntheticHEIC(gps: true)
        let out = try transform(.data(heic), declaredType: .heic, policy: makeUploadPolicy(stripLocation: true))
        #expect(imageType(of: out) == .jpeg)
        #expect(!imageHasGPS(out))
    }

    /// A strip-only transform is not a re-encode, so keeping HEIC (conversion
    /// off) must strip location without transcoding the container to JPEG — the
    /// located photo stays HEIC just like its un-located sibling would.
    @Test("write: located HEIC with conversion off strips GPS and stays HEIC")
    func writeHEICWithGPSStripsAndStaysHEIC() throws {
        let heic = try makeSyntheticHEIC(gps: true)
        let out = try transform(
            .data(heic),
            declaredType: .heic,
            policy: makeUploadPolicy(convertHEICToJPEG: false, stripLocation: true)
        )
        #expect(imageType(of: out) == .heic) // kept as HEIC, not forced to JPEG
        #expect(!imageHasGPS(out))
    }

    @Test("write: PNG GPS strip falls back to a pixel-lossless re-encode, stays PNG")
    func writePNGWithGPSStripsLosslessly() throws {
        let png = try makePNGWithGPS()
        let source = try fixture(png, ext: "png")
        let out = try transform(.url(source), declaredType: .png, policy: makeUploadPolicy(stripLocation: true))
        #expect(imageType(of: out) == .png)
        #expect(!imageHasGPS(out))
        // PNG is a lossless codec, so the fallback re-encode changes no pixels.
        #expect(try decodedPixels(of: out) == decodedPixels(of: source))
    }

    @Test("write: .data and .url inputs strip identically")
    func writeInputParity() throws {
        let jpeg = try makeJPEGWithGPSAndDate()
        let source = try fixture(jpeg, ext: "jpg")
        let policy = makeUploadPolicy(stripLocation: true)
        let fromData = try transform(.data(jpeg), declaredType: .jpeg, policy: policy)
        let fromURL = try transform(.url(source), declaredType: .jpeg, policy: policy)
        #expect(!imageHasGPS(fromData))
        #expect(!imageHasGPS(fromURL))
        #expect(try decodedPixels(of: fromData) == decodedPixels(of: fromURL))
    }

    // MARK: - write: conversion

    @Test("write: HEIC converts to JPEG")
    func writeHEICConverts() throws {
        let heic = try makeSyntheticHEIC()
        let out = try transform(.data(heic), declaredType: .heic, policy: makeUploadPolicy())
        #expect(imageType(of: out) == .jpeg)
    }

    @Test("write: TIFF is normalized to JPEG")
    func writeTIFFConverts() throws {
        let tiff = try encodeImage(makeSolidColorImage(size: CGSize(width: 64, height: 64), color: .red), as: .tiff)
        let out = try transform(.data(tiff), declaredType: .tiff, policy: makeUploadPolicy())
        #expect(imageType(of: out) == .jpeg)
    }

    @Test("write: HEIC→JPEG conversion preserves EXIF orientation")
    func writeConversionPreservesOrientation() throws {
        let heic = try makeSyntheticHEIC(orientation: .down) // 180°
        let out = try transform(.data(heic), declaredType: .heic, policy: makeUploadPolicy())
        let orientation = try imageProperties(of: out)[kCGImagePropertyOrientation] as? UInt32
        #expect(orientation == CGImagePropertyOrientation.down.rawValue)
    }

    @Test("write: the sniffed type wins — HEIC-as-JPEG is really converted")
    func writeSniffedTypeWins() throws {
        let heic = try makeSyntheticHEIC()
        let source = try fixture(heic, ext: "jpg") // lies with a .jpg extension
        let out = try transform(.url(source), declaredType: .jpeg, policy: makeUploadPolicy())
        #expect(imageType(of: out) == .jpeg)
        #expect(try Data(contentsOf: out) != heic) // genuinely re-encoded, not passed through
    }

    /// `write` re-reads its output and rejects a metadata-only stub that
    /// `CGImageDestinationFinalize` reports as success — the fail-closed guard
    /// against a truncated source shipping a broken image as a successful upload.
    /// Verified through the predicate directly, since the exact truncation that
    /// produces such a stub is decoder-version-specific (reproduces on macOS,
    /// not on the iOS 17 simulator's more lenient decoder).
    @Test("fileHasDecodableImage accepts a real image, rejects a header-only stub")
    func fileHasDecodableImageGuard() throws {
        let valid = try fixture(
            try encodeImage(makeSolidColorImage(size: CGSize(width: 24, height: 24), color: .red), as: .jpeg),
            ext: "jpg"
        )
        #expect(MediaTransformer.fileHasDecodableImage(valid))

        // SOI + JFIF APP0 + EOI, but no frame (no SOF/scan): a plausible JPEG
        // header with no decodable image — the shape a stub-y Finalize leaves.
        let stubBytes = Data([
            0xFF, 0xD8,
            0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00,
            0x01, 0x01, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00,
            0xFF, 0xD9
        ])
        let stub = try fixture(stubBytes, ext: "jpg")
        #expect(!MediaTransformer.fileHasDecodableImage(stub))
    }

    // MARK: - write: location strip (coordinates + textual place names)

    /// "Remove Location" must drop IPTC place names (which reverse-geocoding apps
    /// embed) as well as GPS coordinates, while keeping the caption and other
    /// non-location IPTC. This located JPEG has an IIM block `CopyImageSource`
    /// can't rewrite, so it exercises the fail-closed re-read → convert fallback.
    @Test("write: strip removes textual IPTC location but keeps caption")
    func writeStripsTextualLocation() throws {
        let jpeg = try makeJPEGWithTextualLocation()
        let out = try transform(.data(jpeg), declaredType: .jpeg, policy: makeUploadPolicy(stripLocation: true))
        let iptc = try imageIPTC(of: out)
        #expect(iptc[kCGImagePropertyIPTCCity] == nil)
        #expect(iptc[kCGImagePropertyIPTCCountryPrimaryLocationName] == nil)
        #expect(iptc[kCGImagePropertyIPTCCaptionAbstract] as? String == "A nice photo")
        #expect(!imageHasGPS(out))
    }

    @Test("write: resize strip removes textual IPTC location but keeps caption")
    func writeResizeStripsTextualLocation() throws {
        let jpeg = try makeJPEGWithTextualLocation()
        let out = try transform(
            .data(jpeg),
            declaredType: .jpeg,
            policy: makeUploadPolicy(imageMaxDimension: 32, stripLocation: true)
        )
        let iptc = try imageIPTC(of: out)
        #expect(iptc[kCGImagePropertyIPTCCity] == nil)
        #expect(iptc[kCGImagePropertyIPTCCaptionAbstract] as? String == "A nice photo")
        #expect(!imageHasGPS(out))
    }

    // MARK: - write: multi-image HEIC primary selection

    /// A multi-image HEIC container can mark a non-first item as primary. The
    /// transform must read that primary frame — item 0 is 40×40, the primary
    /// (item 1) is 80×60, so a hardcoded index-0 read would ship the wrong size.
    @Test("write: a multi-image HEIC uses the primary item, not index 0")
    func writeMultiImageHEICUsesPrimary() throws {
        let heic = try makeMultiImageHEIC(
            item0: CGSize(width: 40, height: 40),
            primary: CGSize(width: 80, height: 60)
        )
        let out = try transform(.data(heic), declaredType: .heic, policy: makeUploadPolicy())
        let props = try imageProperties(of: out)
        #expect(props[kCGImagePropertyPixelWidth] as? Int == 80)
        #expect(props[kCGImagePropertyPixelHeight] as? Int == 60)
    }

    // MARK: - write: color fidelity

    /// A resize must not collapse a wide-gamut (Display P3) photo to sRGB — the
    /// embedded ICC profile rides through so a color-managed web renders it right.
    @Test("write: resize preserves Display P3 wide gamut")
    func writeResizePreservesP3() throws {
        let p3 = try makeP3JPEG(size: CGSize(width: 128, height: 128))
        let out = try transform(.data(p3), declaredType: .jpeg, policy: makeUploadPolicy(imageMaxDimension: 32))
        #expect(imageIsWideGamut(of: out))
    }

    // MARK: - write: AVIF input

    /// AVIF is decode-only before iOS 26, so it can't be synthesized in-test on
    /// the iOS 17 floor — this uses a committed binary fixture. AVIF isn't
    /// web-safe, so it converts to JPEG.
    @Test("write: an AVIF input converts to a valid JPEG")
    func writeAVIFConvertsToJPEG() throws {
        let avif = try Data(contentsOf: #require(Bundle.module.url(forResource: "test-image", withExtension: "avif")))
        let out = try transform(.data(avif), declaredType: #require(UTType("public.avif")), policy: makeUploadPolicy())
        #expect(imageType(of: out) == .jpeg)
    }

    // MARK: - write: WebP input (decode-only)

    /// WebP decodes on the iOS 17 floor but can't be encoded, so a committed
    /// fixture stands in. Not web-safe and not ImageIO-writable → force-converts
    /// to JPEG (`!isEncodable`), even with HEIC→JPEG conversion off.
    @Test("write: a static WebP converts to a valid JPEG")
    func writeStaticWebPConvertsToJPEG() throws {
        let data = try Data(contentsOf: #require(Bundle.module.url(forResource: "test-image", withExtension: "webp")))
        let out = try transform(
            .data(data),
            declaredType: #require(UTType("org.webmproject.webp")),
            policy: makeUploadPolicy(convertHEICToJPEG: false)
        )
        #expect(imageType(of: out) == .jpeg)
        #expect(MediaTransformer.fileHasDecodableImage(out))
    }

    /// An animated WebP converts to a single-frame JPEG of its primary frame —
    /// never a broken multi-frame artifact.
    @Test("write: an animated WebP converts to a single-frame JPEG")
    func writeAnimatedWebPConvertsToJPEG() throws {
        let data = try Data(
            contentsOf: #require(Bundle.module.url(forResource: "test-image-animated", withExtension: "webp"))
        )
        let out = try transform(
            .data(data),
            declaredType: #require(UTType("org.webmproject.webp")),
            policy: makeUploadPolicy()
        )
        #expect(imageType(of: out) == .jpeg)
        let src = try #require(CGImageSourceCreateWithURL(out as CFURL, nil))
        #expect(CGImageSourceGetCount(src) == 1) // one frame, not an animation
    }

    /// A WebP whose header declares a >100 MP canvas is rejected before any
    /// decode — the decompression-bomb backstop (`maxSourcePixels`). The fixture
    /// is an 11000×11000 flat-colour lossless WebP: 4.7 KB on disk, 121 MP if
    /// decoded. WebP has no scaled-decode, so the header check is the only guard.
    @Test("plan: a WebP decompression bomb is rejected before decode")
    func planWebPBombThrows() throws {
        let data = try Data(
            contentsOf: #require(Bundle.module.url(forResource: "test-image-bomb", withExtension: "webp"))
        )
        let transformer = MediaTransformer(policy: makeUploadPolicy())
        #expect(throws: MediaTransformerError.self) {
            _ = try transformer.plan(.data(data), declaredType: #require(UTType("org.webmproject.webp")))
        }
    }

    // MARK: - write: CMYK JPEG → RGB (profile-honoured)

    /// Patch-centre coordinates in the CMYK fixtures — cyan, magenta, yellow, black.
    private static let cmykPatchCentres = [(8, 8), (24, 8), (8, 24), (24, 24)]

    /// Runs CMYK fixture `resource` through the pipeline; returns the converted
    /// output URL and its four patch-centre sRGB samples (cyan, magenta, yellow,
    /// black — in that order).
    private func convertCMYK(_ resource: String) throws -> (url: URL, patches: [(r: Int, g: Int, b: Int)]) {
        let data = try Data(
            contentsOf: #require(Bundle.module.url(forResource: resource, withExtension: "jpg"))
        )
        let out = try transform(.data(data), declaredType: .jpeg, policy: makeUploadPolicy())
        let patches = try Self.cmykPatchCentres.map { try #require(imageSampleRGB(of: out, x: $0.0, y: $0.1)) }
        return (out, patches)
    }

    /// A CMYK JPEG must convert to RGB before upload — browsers render 4-component
    /// JPEGs inconsistently — and the conversion must *honour the embedded ICC
    /// profile*, not apply a fixed formula. Two fixtures share identical CMYK pixels
    /// (pure cyan / magenta / yellow / black patches) but carry different profiles:
    ///   • `test-image-cmyk`    — untagged, so ImageIO applies its default Generic
    ///     CMYK, a LUT profile: pure cyan lands at sRGB (0, 164, 218), not (0, 255,
    ///     255), and black is a "rich black" (27, 25, 25), not (0, 0, 0).
    ///   • `test-image-cmyk-ps` — tagged PostScript CMYK, the naive analytic
    ///     profile: pure cyan is (0, 255, 255), black is (0, 0, 0).
    /// Same bytes → different output proves the profile drives the result. Golden
    /// values are ImageIO's colour-managed conversion; ±12 absorbs JPEG + CMM drift
    /// yet stays far tighter than the 80–130-level gap a profile-blind conversion
    /// would show.
    @Test("write: CMYK converts to RGB honouring the embedded colour profile")
    func writeCMYKConvertsHonouringProfile() throws {
        let generic = try convertCMYK("test-image-cmyk") // default Generic CMYK (LUT)
        let naive = try convertCMYK("test-image-cmyk-ps") // naive PostScript CMYK

        #expect(imageColorModel(of: generic.url) == "RGB") // converted, not shipped as CMYK
        #expect(imageColorModel(of: naive.url) == "RGB")

        let tol = 12
        func expectClose(_ got: (r: Int, g: Int, b: Int), _ want: (Int, Int, Int), _ label: String) {
            #expect(
                abs(got.r - want.0) <= tol && abs(got.g - want.1) <= tol && abs(got.b - want.2) <= tol,
                "\(label): got \(got), want ~\(want) ±\(tol)"
            )
        }
        // Generic CMYK (LUT) golden — cyan, magenta, yellow, black.
        expectClose(generic.patches[0], (0, 164, 218), "generic cyan")
        expectClose(generic.patches[1], (216, 16, 125), "generic magenta")
        expectClose(generic.patches[2], (255, 241, 6), "generic yellow")
        expectClose(generic.patches[3], (27, 25, 25), "generic black")
        // Naive PostScript golden.
        expectClose(naive.patches[0], (0, 255, 255), "naive cyan")
        expectClose(naive.patches[1], (255, 0, 255), "naive magenta")
        expectClose(naive.patches[2], (255, 255, 0), "naive yellow")
        expectClose(naive.patches[3], (0, 0, 0), "naive black")

        // Profile respected: identical CMYK, different profile → the LUT profile
        // pulls colours far off the naive conversion.
        #expect(abs(generic.patches[0].g - naive.patches[0].g) > 60) // cyan green: 164 vs 255
        #expect(abs(generic.patches[3].r - naive.patches[3].r) > 15) // black: 27 vs 0
    }

    // MARK: - write: alpha flatten

    /// Converting a non-web-safe alpha source (HEIC) to JPEG flattens the
    /// transparency — JPEG has no alpha channel. Documented fidelity loss; PNG,
    /// being web-safe, keeps its alpha by passing through instead.
    @Test("write: converting a transparent HEIC flattens alpha")
    func writeConvertFlattensAlpha() throws {
        let heic = try makeTransparentHEIC(size: CGSize(width: 40, height: 40))
        let src = try fixture(heic, ext: "heic")
        try #require(imageHasAlpha(of: src)) // sanity: the source really has alpha
        let out = try transform(.data(heic), declaredType: .heic, policy: makeUploadPolicy())
        #expect(imageType(of: out) == .jpeg)
        #expect(!imageHasAlpha(of: out))
    }

    // MARK: - write: EXIF orientation (all 8)

    /// Every EXIF orientation (1–8, incl. the mirrored 2/4/5/7) must bake upright
    /// on a resize: the 90°/270° values (5–8) swap the aspect, and the baked
    /// output carries no residual rotation tag. Extends the existing 3/6-only
    /// coverage across the whole table in one pass.
    @Test(
        "write: resize bakes every EXIF orientation upright",
        arguments: [1, 2, 3, 4, 5, 6, 7, 8] as [UInt32]
    )
    func writeResizeBakesAllOrientations(orientation: UInt32) throws {
        // Landscape 80×60 source tagged with `orientation`.
        let jpeg = try encodeImage(
            makeSolidColorImage(size: CGSize(width: 80, height: 60), color: .blue),
            as: .jpeg,
            properties: [kCGImagePropertyOrientation: orientation]
        )
        let out = try transform(.data(jpeg), declaredType: .jpeg, policy: makeUploadPolicy(imageMaxDimension: 40))
        let props = try imageProperties(of: out)
        let width = try #require(props[kCGImagePropertyPixelWidth] as? Int)
        let height = try #require(props[kCGImagePropertyPixelHeight] as? Int)
        // Orientations 5–8 rotate 90°, so a landscape source becomes portrait
        // once baked upright; 1–4 stay landscape.
        if (5...8).contains(orientation) {
            #expect(height > width)
        } else {
            #expect(width > height)
        }
        // No residual rotation in the baked output.
        let outOrientation = props[kCGImagePropertyOrientation] as? UInt32
        #expect(outOrientation == nil || outOrientation == 1)
    }

    // MARK: - write: resize

    @Test("write: an over-cap image is resized within the cap")
    func writeResizeWithinCap() throws {
        let jpeg = try encodeImage(makeSolidColorImage(size: CGSize(width: 200, height: 120), color: .blue), as: .jpeg)
        let out = try transform(.data(jpeg), declaredType: .jpeg, policy: makeUploadPolicy(imageMaxDimension: 64))
        let props = try imageProperties(of: out)
        let width = try #require(props[kCGImagePropertyPixelWidth] as? Int)
        let height = try #require(props[kCGImagePropertyPixelHeight] as? Int)
        #expect(max(width, height) <= 64)
    }

    @Test("write: resize strips GPS but keeps other EXIF")
    func writeResizeStripsGPSKeepsEXIF() throws {
        let jpeg = try makeJPEGWithGPSAndDate()
        let out = try transform(
            .data(jpeg),
            declaredType: .jpeg,
            policy: makeUploadPolicy(imageMaxDimension: 32, stripLocation: true)
        )
        let props = try imageProperties(of: out)
        #expect(props[kCGImagePropertyGPSDictionary] == nil)
        let exif = props[kCGImagePropertyExifDictionary] as? [CFString: Any]
        #expect(exif?[kCGImagePropertyExifDateTimeOriginal] as? String == fixtureDateTimeOriginal)
        let width = try #require(props[kCGImagePropertyPixelWidth] as? Int)
        #expect(width <= 32)
    }

    @Test("write: resize with strip off keeps GPS")
    func writeResizeKeepsGPSWhenStripOff() throws {
        let jpeg = try makeJPEGWithGPSAndDate()
        let out = try transform(.data(jpeg), declaredType: .jpeg, policy: makeUploadPolicy(imageMaxDimension: 32))
        #expect(imageHasGPS(out))
    }

    @Test("write: PNG stays PNG through a resize")
    func writePNGResizeKeepsType() throws {
        let png = try encodeImage(makeSolidColorImage(size: CGSize(width: 128, height: 128), color: .red), as: .png)
        let out = try transform(.data(png), declaredType: .png, policy: makeUploadPolicy(imageMaxDimension: 32))
        #expect(imageType(of: out) == .png)
        let width = try #require(try imageProperties(of: out)[kCGImagePropertyPixelWidth] as? Int)
        #expect(width <= 32)
    }

    @Test("write: resize bakes EXIF orientation into the pixels")
    func writeResizeBakesOrientation() throws {
        // Landscape pixels with a 90° tag → baked resize is portrait + upright.
        let heic = try encodeImage(
            makeSolidColorImage(size: CGSize(width: 80, height: 60), color: .blue),
            as: .heic,
            properties: [kCGImagePropertyOrientation: CGImagePropertyOrientation.right.rawValue]
        )
        let out = try transform(.data(heic), declaredType: .heic, policy: makeUploadPolicy(imageMaxDimension: 40))
        let props = try imageProperties(of: out)
        let width = try #require(props[kCGImagePropertyPixelWidth] as? Int)
        let height = try #require(props[kCGImagePropertyPixelHeight] as? Int)
        #expect(height > width)
        let orientation = props[kCGImagePropertyOrientation] as? UInt32
        #expect(orientation == nil || orientation == CGImagePropertyOrientation.up.rawValue)
    }

    // MARK: - write: orientation normalize

    @Test("write: normalize bakes a non-upright JPEG upright and drops the tag")
    func writeNormalizeBakesOrientation() throws {
        // Landscape 80×60 pixels tagged 90° (.right) display as portrait. With
        // normalize on and no resize, the rotation is baked into full-resolution
        // pixels and the tag reset — no viewer needs to honor orientation.
        let jpeg = try encodeImage(
            makeSolidColorImage(size: CGSize(width: 80, height: 60), color: .blue),
            as: .jpeg,
            properties: [kCGImagePropertyOrientation: CGImagePropertyOrientation.right.rawValue]
        )
        let out = try transform(
            .data(jpeg),
            declaredType: .jpeg,
            policy: makeUploadPolicy(normalizeImageOrientation: true)
        )
        let props = try imageProperties(of: out)
        let width = try #require(props[kCGImagePropertyPixelWidth] as? Int)
        let height = try #require(props[kCGImagePropertyPixelHeight] as? Int)
        #expect(height > width) // pixels physically rotated to portrait
        #expect(max(width, height) == 80) // full resolution — not resized
        let orientation = props[kCGImagePropertyOrientation] as? UInt32
        #expect(orientation == nil || orientation == CGImagePropertyOrientation.up.rawValue)
        #expect(imageType(of: out) == .jpeg)
    }

    @Test("write: normalize is a byte-for-byte passthrough for an upright image")
    func writeNormalizeUprightIsPassthrough() throws {
        // No orientation tag → nothing to bake → no recompress.
        let jpeg = try encodeImage(
            makeSolidColorImage(size: CGSize(width: 50, height: 50), color: .red),
            as: .jpeg
        )
        let out = try transform(
            .data(jpeg),
            declaredType: .jpeg,
            policy: makeUploadPolicy(normalizeImageOrientation: true)
        )
        #expect(try Data(contentsOf: out) == jpeg)
    }

    @Test("write: normalize off leaves a non-upright image's tag and bytes intact")
    func writeNormalizeOffKeepsTag() throws {
        // Default policy relies on the server/browser to honor orientation, so a
        // sideways JPEG passes through untouched — tag and pixels both preserved.
        let jpeg = try encodeImage(
            makeSolidColorImage(size: CGSize(width: 80, height: 60), color: .blue),
            as: .jpeg,
            properties: [kCGImagePropertyOrientation: CGImagePropertyOrientation.right.rawValue]
        )
        let out = try transform(.data(jpeg), declaredType: .jpeg, policy: makeUploadPolicy())
        let orientation = try imageProperties(of: out)[kCGImagePropertyOrientation] as? UInt32
        #expect(orientation == CGImagePropertyOrientation.right.rawValue)
        #expect(try Data(contentsOf: out) == jpeg)
    }

    @Test("write: HEIC→JPEG conversion bakes orientation when normalize is on")
    func writeConvertBakesOrientationWhenNormalizeOn() throws {
        // Contrast with `writeConversionPreservesOrientation` (normalize off,
        // which carries the tag across): with normalize on, the convert path
        // bakes the rotation and clears the tag.
        let heic = try encodeImage(
            makeSolidColorImage(size: CGSize(width: 80, height: 60), color: .blue),
            as: .heic,
            properties: [kCGImagePropertyOrientation: CGImagePropertyOrientation.right.rawValue]
        )
        let out = try transform(
            .data(heic),
            declaredType: .heic,
            policy: makeUploadPolicy(normalizeImageOrientation: true)
        )
        #expect(imageType(of: out) == .jpeg)
        let props = try imageProperties(of: out)
        let width = try #require(props[kCGImagePropertyPixelWidth] as? Int)
        let height = try #require(props[kCGImagePropertyPixelHeight] as? Int)
        #expect(height > width)
        let orientation = props[kCGImagePropertyOrientation] as? UInt32
        #expect(orientation == nil || orientation == CGImagePropertyOrientation.up.rawValue)
    }

    @Test("write: normalize bakes orientation, strips GPS, and keeps other EXIF")
    func writeNormalizeStripsGPSKeepsEXIF() throws {
        // The real phone-photo combo: a located, dated, sideways JPEG.
        let jpeg = try encodeImage(
            makeSolidColorImage(size: CGSize(width: 80, height: 60), color: .green),
            as: .jpeg,
            properties: [
                kCGImagePropertyOrientation: CGImagePropertyOrientation.right.rawValue,
                kCGImagePropertyGPSDictionary: [
                    kCGImagePropertyGPSLatitude: 37.33,
                    kCGImagePropertyGPSLongitude: -122.03
                ],
                kCGImagePropertyExifDictionary: [
                    kCGImagePropertyExifDateTimeOriginal: fixtureDateTimeOriginal
                ]
            ]
        )
        let out = try transform(
            .data(jpeg),
            declaredType: .jpeg,
            policy: makeUploadPolicy(stripLocation: true, normalizeImageOrientation: true)
        )
        let props = try imageProperties(of: out)
        #expect(props[kCGImagePropertyGPSDictionary] == nil)
        let exif = props[kCGImagePropertyExifDictionary] as? [CFString: Any]
        #expect(exif?[kCGImagePropertyExifDateTimeOriginal] as? String == fixtureDateTimeOriginal)
        let width = try #require(props[kCGImagePropertyPixelWidth] as? Int)
        let height = try #require(props[kCGImagePropertyPixelHeight] as? Int)
        #expect(height > width)
        let orientation = props[kCGImagePropertyOrientation] as? UInt32
        #expect(orientation == nil || orientation == CGImagePropertyOrientation.up.rawValue)
    }

    // MARK: - Video

    /// A source already within the resolution cap is remuxed (streams copied),
    /// not transcoded — so it isn't re-encoded end to end just to strip location.
    @Test("video within the resolution cap is remuxed, not re-encoded")
    func videoWithinCapUsesPassthrough() async throws {
        let videoURL = try await sharedBlankVideoTask.value // 320×240
        let preset = try await MediaTransformer(policy: makeUploadPolicy(videoMaxDimension: 1024))
            .resolveVideoExportPreset(for: AVURLAsset(url: videoURL), outputType: .mp4)
        #expect(preset == AVAssetExportPresetPassthrough)
    }

    @Test("an uncapped video is remuxed, not re-encoded")
    func videoUncappedUsesPassthrough() async throws {
        let videoURL = try await sharedBlankVideoTask.value
        let preset = try await MediaTransformer(policy: makeUploadPolicy())
            .resolveVideoExportPreset(for: AVURLAsset(url: videoURL), outputType: .mp4)
        #expect(preset == AVAssetExportPresetPassthrough)
    }

    /// Only a source that exceeds the cap falls back to a full re-encode.
    @Test("video over the resolution cap falls back to the re-encode preset")
    func videoOverCapUsesReencode() async throws {
        let videoURL = try await sharedBlankVideoTask.value // 320×240
        let preset = try await MediaTransformer(policy: makeUploadPolicy(videoMaxDimension: 100))
            .resolveVideoExportPreset(for: AVURLAsset(url: videoURL), outputType: .mp4)
        #expect(preset == AVAssetExportPresetMediumQuality)
    }
}

// MARK: - Helpers

extension MediaTransformerTests {
    /// Writes fixture bytes to a fresh file under the per-test root.
    private func fixture(_ data: Data, ext: String) throws -> URL {
        let url = root.appendingPathComponent("src-\(UUID().uuidString).\(ext)")
        try data.write(to: url)
        return url
    }

    /// Plans and writes `input` through a transformer, returning the output URL
    /// (named from the plan's extension, exactly as the materializer would).
    private func transform(
        _ input: MediaTransformer.Input,
        declaredType: UTType,
        policy: MediaUploadPolicy
    ) throws -> URL {
        let transformer = MediaTransformer(policy: policy)
        let plan = try transformer.plan(input, declaredType: declaredType)
        let output = root.appendingPathComponent("out-\(UUID().uuidString).\(plan.fileExtension)")
        try transformer.write(plan, to: output)
        return output
    }
}
