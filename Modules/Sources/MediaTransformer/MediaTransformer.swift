import AVFoundation
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Applies the upload policy's transforms to a picked or downloaded image or
/// video, streaming the result to a destination file: HEIC→JPEG conversion,
/// resize, EXIF-orientation flatten, and GPS strip for images (`plan`/`write`);
/// duration cap, passthrough remux, and location strip for video
/// (`planVideo`/`writeVideo`).
///
/// This is pure ImageIO and owns no upload state: it does not name files,
/// allocate staging directories, or build `MaterializedUpload`. A caller `plan`s
/// a transform from the image header, uses the plan's `contentType` /
/// `fileExtension` to name and allow-check the output, then hands the plan back
/// to `write(_:to:)`. The split keeps filename allocation — which is
/// session-scoped, for server-side dedup — with the materializer.
///
/// Memory is bounded to what each operation actually demands: ImageIO faults the
/// compressed source in on demand (a URL input is never held whole), the encoder
/// streams straight to disk, and the pixel work never exceeds one decode and one
/// encode. When no transform is needed the bytes pass through unchanged — a URL
/// input is clone-copied (an APFS copy-on-write clone, zero bytes through RAM),
/// so web-safe in-cap images survive byte-for-byte. Any ImageIO failure throws —
/// the transform never falls back to the original bytes, so a required GPS strip
/// can never silently ship the location.
public struct MediaTransformer: Sendable {
    private let policy: MediaUploadPolicy

    public init(policy: MediaUploadPolicy) {
        self.policy = policy
    }

    /// The origin of the bytes to transform. Disk-backed sources (`.file`,
    /// `.imagePlayground`, and the downloaded `.remoteURL` temp) pass `.url` so
    /// ImageIO can fault the compressed bytes in on demand and the no-transform
    /// case can clone the file instead of round-tripping it through RAM. The
    /// in-memory sources — the photo library's `NSItemProvider` (→ `Data`) and
    /// the camera's `UIImage` (→ JPEG `Data`) — have no file to point at, so they
    /// pass `.data`.
    public enum Input {
        case url(URL)
        case data(Data)

        /// `typeHint` (the caller's declared type) is passed as
        /// `kCGImageSourceTypeIdentifierHint` so ImageIO picks the right decoder
        /// when the bytes alone are ambiguous — notably a RAW (`.data`) source,
        /// whose magic bytes otherwise sniff as TIFF and yield the small embedded
        /// preview instead of the full-resolution image. Harmless when the hint
        /// is wrong: ImageIO validates the magic bytes and uses the real type.
        func makeImageSource(typeHint: UTType?) -> CGImageSource? {
            let options = typeHint.map {
                [kCGImageSourceTypeIdentifierHint: $0.identifier] as CFDictionary
            }
            switch self {
            case .url(let url): return CGImageSourceCreateWithURL(url as CFURL, options)
            case .data(let data): return CGImageSourceCreateWithData(data as CFData, options)
            }
        }
    }

    /// A decided image transform plus the content type and file extension it will
    /// produce. The caller reads `contentType` / `fileExtension` to name and
    /// allow-check the destination, then passes the plan to `write(_:to:)`; the
    /// remaining fields carry the already-opened image source across so the header
    /// isn't read twice.
    public struct Plan {
        public let contentType: UTType
        public let fileExtension: String

        fileprivate let input: Input
        fileprivate let source: CGImageSource
        fileprivate let sourceProperties: [CFString: Any]
        fileprivate let transforms: ImageTransforms
        fileprivate let actualType: UTType
    }

    /// The set of transforms the single-pass image write must apply, computed
    /// once from the image header and the policy.
    fileprivate struct ImageTransforms: OptionSet {
        let rawValue: Int

        static let convert = ImageTransforms(rawValue: 1 << 0)
        static let resize = ImageTransforms(rawValue: 1 << 1)
        static let stripLocation = ImageTransforms(rawValue: 1 << 2)
        /// Rotate the pixels to match the EXIF orientation tag, then reset the
        /// tag — a re-encode, so it forces a web-safe output like the others.
        static let normalizeOrientation = ImageTransforms(rawValue: 1 << 3)
        /// Re-encode a CMYK source to RGB through the colour-managed thumbnail
        /// path — browsers render 4-component JPEGs inconsistently. A re-encode,
        /// so it forces a web-safe output like the others.
        static let normalizeColorSpace = ImageTransforms(rawValue: 1 << 4)
    }

    /// Header-validates, sniffs the real content type, and decides which
    /// transforms the policy requires (JPEG conversion, resize, GPS strip). Reads
    /// only the image header — the pixels are touched by `write`, not here.
    ///
    /// Validation is header-level: a non-image body (e.g. an HTML error page
    /// served as image/jpeg) is rejected, but a truncated image with an intact
    /// header still passes, matching V1.
    public func plan(_ input: Input, declaredType: UTType) throws -> Plan {
        guard
            let source = input.makeImageSource(typeHint: declaredType),
            CGImageSourceGetCount(source) >= 1
        else {
            throw MediaTransformerError.invalidImageData
        }
        // Read the container's *primary* image (HEIF honors the `pitm` box, which
        // needn't be item 0). Every downstream index uses the same frame so the
        // transform, cap decision, and location check all agree on it.
        let primaryIndex = CGImageSourceGetPrimaryImageIndex(source)
        guard
            let props = CGImageSourceCopyPropertiesAtIndex(source, primaryIndex, nil) as? [CFString: Any],
            let width = props[kCGImagePropertyPixelWidth] as? Int,
            let height = props[kCGImagePropertyPixelHeight] as? Int
        else {
            throw MediaTransformerError.invalidImageData
        }

        // The sniffed container type is the truth; the declared type (picker
        // hint, Content-Type header, file extension) can lie — a HEIC served
        // as image/jpeg must still be converted.
        let actualType = CGImageSourceGetType(source).flatMap { UTType($0 as String) } ?? declaredType

        var transforms: ImageTransforms = []
        var effectiveType = actualType
        // Convert a non-web-safe source to JPEG when the policy asks, or when the
        // source format can't be written back at all (AVIF is decode-only before
        // iOS 26) — keeping an unwritable type would fail every encode.
        if !Self.webSafeImageTypes.contains(actualType),
            policy.convertHEICToJPEG || !Self.isEncodable(actualType)
        {
            effectiveType = .jpeg
            transforms.insert(.convert)
        }
        // A CMYK JPEG is a valid, "web-safe" JPEG by type, but browsers render
        // 4-component JPEGs inconsistently — Firefox and Chrome historically showed
        // a broken image, and most still do a naive CMYK→RGB conversion that ignores
        // the ICC profile (Adobe "inverted" CMYK then renders with inverted colours).
        // Route it through the colour-managed thumbnail re-encode, the only path that
        // actually converts to RGB — `AddImageFromSource` copies the CMYK data verbatim.
        if Self.isCMYK(props) {
            transforms.insert(.normalizeColorSpace)
        }
        if let cap = policy.imageMaxDimension, cap > 0, max(width, height) > cap {
            transforms.insert(.resize)
        }
        // "Remove Location" covers GPS coordinates AND textual place names
        // (IPTC/XMP City/State/Country) that reverse-geocoding apps embed.
        if policy.stripLocation, Self.hasLocation(props) {
            transforms.insert(.stripLocation)
        }
        // Flatten a non-identity EXIF orientation into the pixels when the
        // policy asks, so a viewer that ignores the orientation tag (older
        // WordPress, some preview clients) still renders the image upright.
        // Gated on a real rotation (orientation 2–8) — an already-upright image
        // (tag absent or `1`) would gain nothing but a needless recompress.
        // Harmless alongside `.resize`, which bakes orientation regardless.
        if policy.normalizeImageOrientation,
            let orientation = (props[kCGImagePropertyOrientation] as? NSNumber)?.intValue,
            (2...8).contains(orientation)
        {
            transforms.insert(.normalizeOrientation)
        }
        // A resize, format conversion, or orientation flatten re-encodes the
        // pixels, and that re-encode target must be web-renderable and
        // ImageIO-writable (e.g. an oversized DNG with HEIC conversion disabled
        // still can't be written back as DNG). A pure GPS strip is excluded:
        // `stripGPSLosslessly` can rewrite only the metadata and keep the source
        // format, so forcing JPEG here would needlessly transcode — and degrade
        // — a located HEIC the policy asked to keep as HEIC.
        if !transforms.intersection([.resize, .convert, .normalizeOrientation, .normalizeColorSpace]).isEmpty,
            !Self.webSafeImageTypes.contains(effectiveType)
        {
            effectiveType = .jpeg
        }

        // Decompression-bomb backstop (see `maxSourcePixels`): only the unbounded
        // decode paths — WebP (no scaled decode), or a full-resolution re-encode
        // (convert, colour-space normalise, or orientation flatten) not first
        // bounded by a resize — can be OOM'd by a crafted large source; the
        // scale-decoding resize path stays memory-bounded at any size.
        let decodesUnbounded =
            actualType == .webP
            || (!transforms.intersection([.convert, .normalizeColorSpace, .normalizeOrientation]).isEmpty
                && !transforms.contains(.resize))
        if decodesUnbounded, width * height > Self.maxSourcePixels {
            throw MediaTransformerError.invalidImageData
        }

        let ext =
            effectiveType.preferredFilenameExtension
            ?? declaredType.preferredFilenameExtension ?? "bin"

        return Plan(
            contentType: effectiveType,
            fileExtension: ext,
            input: input,
            source: source,
            sourceProperties: props,
            transforms: transforms,
            actualType: actualType
        )
    }

    /// Executes `plan`, streaming the transformed image to `destURL`.
    ///
    /// When no transform is needed the bytes pass through unchanged — a URL input
    /// is clone-copied (APFS copy-on-write), in-memory bytes are written straight
    /// out. Otherwise the pixels are decoded at most once and encoded at most
    /// once. Any ImageIO failure throws — never a silent fallback to the original
    /// bytes, so a required GPS strip can't ship the location.
    public func write(_ plan: Plan, to destURL: URL) throws {
        if plan.transforms.isEmpty {
            // Upload-ready as-is: no decode, no encode. A file input is cloned
            // (copy-on-write on APFS); in-memory bytes are written straight out.
            switch plan.input {
            case .url(let url):
                try FileManager.default.copyItem(at: url, to: destURL)
            case .data(let data):
                try data.write(to: destURL)
            }
        } else {
            try transformImage(
                source: plan.source,
                sourceProperties: plan.sourceProperties,
                actualType: plan.actualType,
                to: plan.contentType,
                applying: plan.transforms,
                writingTo: destURL
            )
        }
    }

    /// Single ImageIO write applying `transforms`, streamed to `destURL` rather
    /// than accumulated in memory. At most one decode and one encode. Strategies,
    /// chosen to preserve the EXIF orientation tag whenever pixels are not
    /// resampled (a dropped tag once shipped rotated HEIC uploads):
    /// - GPS strip only, no format change: `stripGPSLosslessly` copies the
    ///   encoded image and rewrites only the metadata — no decode, no recompress,
    ///   and the orientation tag stays paired with its untouched pixels. Falls
    ///   through to the decode path below when the container won't drop GPS this
    ///   way (checked per-write).
    /// - resize or orientation flatten: thumbnail with the rotation baked into
    ///   the pixels, the tag stamped upright, and the remaining metadata carried
    ///   over — the same treatment as V1 `MediaImageExporter.ImageSourceWriter`.
    ///   Resize caps the longest edge; a flatten-only pass omits the cap and
    ///   reproduces the image at full resolution, changing nothing but the
    ///   orientation.
    /// - any other re-encode (format conversion, a format-changing GPS strip, or
    ///   the lossless path's PNG fallback): `CGImageDestinationAddImageFromSource`,
    ///   which tiles the transcode and carries pixels, orientation, and metadata
    ///   across the container change, dropping GPS via a `kCFNull` override when
    ///   the strip is needed.
    private func transformImage(
        source: CGImageSource,
        sourceProperties: [CFString: Any],
        actualType: UTType,
        to effectiveType: UTType,
        applying transforms: ImageTransforms,
        writingTo destURL: URL
    ) throws {
        // Lossless GPS strip: no resize and no format change, so the encoded
        // image can be copied verbatim while only its metadata is rewritten.
        if transforms == [.stripLocation],
            effectiveType == actualType,
            stripGPSLosslessly(source: source, type: actualType, writingTo: destURL)
        {
            return
        }

        guard
            let dst = CGImageDestinationCreateWithURL(
                destURL as CFURL,
                effectiveType.identifier as CFString,
                1,
                nil
            )
        else {
            throw MediaTransformerError.imageEncodeFailed
        }

        // The container's primary image — the same frame `plan` measured.
        let primaryIndex = CGImageSourceGetPrimaryImageIndex(source)

        if transforms.contains(.resize) || transforms.contains(.normalizeOrientation)
            || transforms.contains(.normalizeColorSpace)
        {
            var thumbnailOptions: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceShouldCacheImmediately: true
            ]
            // A resize caps the longest edge; a flatten-only pass omits the cap
            // so ImageIO reproduces the full-resolution pixels with just the
            // rotation baked in. `.resize` is only ever set with a positive cap.
            if transforms.contains(.resize), let cap = policy.imageMaxDimension {
                thumbnailOptions[kCGImageSourceThumbnailMaxPixelSize] = cap
            }
            guard
                let thumb = CGImageSourceCreateThumbnailAtIndex(
                    source,
                    primaryIndex,
                    thumbnailOptions as CFDictionary
                )
            else {
                throw MediaTransformerError.imageEncodeFailed
            }
            var props = sourceProperties
            if transforms.contains(.stripLocation) {
                props.removeValue(forKey: kCGImagePropertyGPSDictionary)
                props = Self.removingIPTCLocation(from: props)
            }
            // The thumbnail baked the EXIF rotation into the pixels, so stamp
            // the orientation upright everywhere it lives (V1 parity) and drop
            // the stale pixel-dimension records; the destination writes the
            // real dimensions itself.
            props[kCGImagePropertyOrientation] = CGImagePropertyOrientation.up.rawValue
            if var tiff = props[kCGImagePropertyTIFFDictionary] as? [CFString: Any] {
                tiff.removeValue(forKey: kCGImagePropertyTIFFOrientation)
                props[kCGImagePropertyTIFFDictionary] = tiff
            }
            if var iptc = props[kCGImagePropertyIPTCDictionary] as? [CFString: Any] {
                iptc.removeValue(forKey: kCGImagePropertyIPTCImageOrientation)
                props[kCGImagePropertyIPTCDictionary] = iptc
            }
            if var exif = props[kCGImagePropertyExifDictionary] as? [CFString: Any] {
                exif.removeValue(forKey: kCGImagePropertyExifPixelXDimension)
                exif.removeValue(forKey: kCGImagePropertyExifPixelYDimension)
                props[kCGImagePropertyExifDictionary] = exif
            }
            props.removeValue(forKey: kCGImagePropertyPixelWidth)
            props.removeValue(forKey: kCGImagePropertyPixelHeight)
            props[kCGImageDestinationLossyCompressionQuality] = policy.imageJpegQuality
            CGImageDestinationAddImage(dst, thumb, props as CFDictionary)
        } else {
            // Any re-encode that isn't a resize: a format conversion
            // (e.g. HEIC→JPEG), a GPS strip that changes format, or the lossless
            // path's fallback (e.g. a PNG, whose GPS lives in a binary `eXIf`
            // chunk `CopyImageSource` won't rewrite). `AddImageFromSource` tiles
            // the transcode — the resident set is the working tiles, not the
            // whole decoded bitmap — and carries the orientation tag (and other
            // metadata) across the container change. Decoding to a bare CGImage
            // and re-adding it would drop the tag and render a non-upright source
            // (e.g. a 180°-oriented HEIC) upside down.
            //
            // `kCFNull` drops GPS from the metadata `AddImageFromSource` rewrites
            // from the source; every non-GPS record (capture date, camera make,
            // orientation) rides along. This reaches PNG only as the fallback,
            // where it is pixel-lossless anyway (PNG is a lossless codec).
            var options: [CFString: Any] = [
                kCGImageDestinationLossyCompressionQuality: policy.imageJpegQuality
            ]
            if transforms.contains(.stripLocation) {
                options[kCGImagePropertyGPSDictionary] = kCFNull
                options[kCGImagePropertyIPTCDictionary] = Self.iptcLocationNulls
            }
            CGImageDestinationAddImageFromSource(dst, source, primaryIndex, options as CFDictionary)
        }

        guard CGImageDestinationFinalize(dst) else {
            throw transforms.contains(.stripLocation)
                ? MediaTransformerError.locationStripFailed
                : MediaTransformerError.imageEncodeFailed
        }

        // `Finalize` can return `true` for a structurally-empty output: a
        // truncated source (interrupted download, corrupt HEIC) passes the
        // header read in `plan`, then `AddImageFromSource` writes only the
        // metadata markers and no image data, yet `Finalize` still succeeds.
        // Re-read the output and require a decodable frame so a broken image is
        // never enqueued as a successful upload — fail-closed, upholding this
        // type's "any ImageIO failure throws" contract.
        guard Self.fileHasDecodableImage(destURL) else {
            try? FileManager.default.removeItem(at: destURL)
            throw MediaTransformerError.imageEncodeFailed
        }
    }

    /// Strips GPS metadata from `source` and writes the result to `destURL`
    /// without decoding or recompressing: `CGImageDestinationCopyImageSource`
    /// copies the encoded image verbatim and rewrites only the metadata
    /// container, so the pixels and their JPEG quality are untouched and the
    /// EXIF orientation tag stays paired with them. Every non-GPS record
    /// (capture date, camera make, ...) is preserved — the "Remove Location"
    /// policy strips location only, unlike a blanket metadata exclude.
    ///
    /// Returns `true` only after re-reading the output and confirming the GPS
    /// block is actually gone. This check is load-bearing, not paranoia: PNG
    /// keeps its location in a binary `eXIf` chunk that `CopyImageSource` copies
    /// verbatim no matter which metadata options are set (`kCGImageDestinationMetadata`,
    /// `ShouldExcludeGPS`, and `ShouldExcludeXMP` were all verified to leave it
    /// intact — the options only rewrite the XMP representation, never `eXIf`),
    /// so a PNG lands here with its GPS still readable. When the check fails the
    /// caller falls back to the `AddImageFromSource` strip — which rewrites the
    /// metadata from scratch (dropping GPS) and, for PNG (a lossless codec),
    /// re-encodes without any compression loss. Fail-closed: any failure removes
    /// the partial output and returns `false`.
    private func stripGPSLosslessly(
        source: CGImageSource,
        type: UTType,
        writingTo destURL: URL
    ) -> Bool {
        guard
            let metadata = CGImageSourceCopyMetadataAtIndex(source, CGImageSourceGetPrimaryImageIndex(source), nil),
            let mutableMetadata = CGImageMetadataCreateMutableCopy(metadata)
        else {
            return false
        }

        // Drop every GPS tag from the metadata we carry over. The standard EXIF
        // GPS tags are all named `GPS*`, so a case-insensitive "gps" match on the
        // tag path catches them without disturbing anything else.
        var gpsPaths: [String] = []
        CGImageMetadataEnumerateTagsUsingBlock(
            mutableMetadata,
            nil,
            [kCGImageMetadataEnumerateRecursively: true] as CFDictionary
        ) { path, _ in
            if (path as String).range(of: "gps", options: .caseInsensitive) != nil {
                gpsPaths.append(path as String)
            }
            return true
        }
        for path in gpsPaths {
            CGImageMetadataRemoveTagWithPath(mutableMetadata, nil, path as CFString)
        }

        let options: [CFString: Any] = [
            kCGImageDestinationMetadata: mutableMetadata,
            // Backstop in case a GPS tag hid behind a non-obvious path.
            kCGImageMetadataShouldExcludeGPS: true
        ]
        guard
            let dst = CGImageDestinationCreateWithURL(
                destURL as CFURL,
                type.identifier as CFString,
                1,
                nil
            ),
            CGImageDestinationCopyImageSource(dst, source, options as CFDictionary, nil),
            !Self.fileHasLocation(destURL)
        else {
            try? FileManager.default.removeItem(at: destURL)
            return false
        }
        return true
    }

    /// Whether the image at `url` still carries an EXIF GPS dictionary — the
    /// post-write check that keeps `stripGPSLosslessly` honest. Internal (not
    /// private) so the tests assert with this exact predicate instead of a copy.
    public static func fileHasGPS(_ url: URL) -> Bool {
        guard
            let source = CGImageSourceCreateWithURL(url as CFURL, nil),
            let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
        else {
            return false
        }
        return props[kCGImagePropertyGPSDictionary] != nil
    }

    /// Whether the image written to `url` has a decodable primary frame with
    /// real pixel dimensions. Guards the re-encode paths against a
    /// `CGImageDestinationFinalize` that returns `true` for a metadata-only stub
    /// produced from a truncated source — a header re-read (no full decode)
    /// mirroring the validation `plan` runs on the input. Internal so the tests
    /// assert with this exact predicate.
    static func fileHasDecodableImage(_ url: URL) -> Bool {
        guard
            let source = CGImageSourceCreateWithURL(url as CFURL, nil),
            CGImageSourceGetCount(source) >= 1,
            let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
        else {
            return false
        }
        return props[kCGImagePropertyPixelWidth] != nil && props[kCGImagePropertyPixelHeight] != nil
    }

    // MARK: - Location & format helpers

    /// IPTC place-name fields the "Remove Location" policy strips alongside the
    /// EXIF GPS coordinates. Reverse-geocoding apps (Lightroom, third-party
    /// cameras) embed these; the iOS Camera never does. Caption, byline,
    /// copyright, and keywords are deliberately left intact.
    private nonisolated(unsafe) static let iptcLocationKeys: [CFString] = [
        kCGImagePropertyIPTCCity,
        kCGImagePropertyIPTCProvinceState,
        kCGImagePropertyIPTCSubLocation,
        kCGImagePropertyIPTCCountryPrimaryLocationName,
        kCGImagePropertyIPTCCountryPrimaryLocationCode,
        kCGImagePropertyIPTCContentLocationName,
        kCGImagePropertyIPTCContentLocationCode
    ]

    /// Whether `props` carries any location — GPS coordinates or IPTC place
    /// names — so the strip also fires for a photo tagged with only a textual
    /// location and no coordinates.
    private static func hasLocation(_ props: [CFString: Any]) -> Bool {
        if props[kCGImagePropertyGPSDictionary] != nil { return true }
        if let iptc = props[kCGImagePropertyIPTCDictionary] as? [CFString: Any] {
            return iptcLocationKeys.contains { iptc[$0] != nil }
        }
        return false
    }

    /// Whether the source's primary image is CMYK — a 4-component colour model
    /// browsers render inconsistently, so it's re-encoded to RGB.
    private static func isCMYK(_ props: [CFString: Any]) -> Bool {
        (props[kCGImagePropertyColorModel] as? String) == (kCGImagePropertyColorModelCMYK as String)
    }

    /// An IPTC dictionary override that nulls only the location subkeys. Merged
    /// into the `AddImageFromSource` options, it clears the place names (and the
    /// XMP tags ImageIO keeps in sync) while leaving caption/byline/copyright.
    private static var iptcLocationNulls: [CFString: Any] {
        Dictionary(uniqueKeysWithValues: iptcLocationKeys.map { ($0, kCFNull as Any) })
    }

    /// Removes the IPTC location subkeys from a full properties dictionary — the
    /// resize path, which re-writes the whole dictionary rather than merging.
    private static func removingIPTCLocation(from props: [CFString: Any]) -> [CFString: Any] {
        guard var iptc = props[kCGImagePropertyIPTCDictionary] as? [CFString: Any] else { return props }
        for key in iptcLocationKeys { iptc.removeValue(forKey: key) }
        var result = props
        result[kCGImagePropertyIPTCDictionary] = iptc
        return result
    }

    /// Post-write location check for the lossless strip's fail-closed re-read.
    /// `CopyImageSource` copies the IIM IPTC block verbatim (like PNG's `eXIf`
    /// GPS), so a place-name-tagged file survives the metadata rewrite; when it
    /// does, the caller re-encodes through the location-nulling
    /// `AddImageFromSource` path instead of shipping the location.
    static func fileHasLocation(_ url: URL) -> Bool {
        guard
            let source = CGImageSourceCreateWithURL(url as CFURL, nil),
            let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
        else {
            return false
        }
        return hasLocation(props)
    }

    /// The container types this OS can *write*. AVIF, for instance, is
    /// decode-only before iOS 26, so keeping it as the effective type would fail
    /// every encode — `plan` converts such a source to JPEG regardless of policy.
    private static let encodableTypes: Set<String> =
        Set((CGImageDestinationCopyTypeIdentifiers() as? [String]) ?? [])

    private static func isEncodable(_ type: UTType) -> Bool {
        encodableTypes.contains(type.identifier)
    }

    /// Decompression-bomb backstop: the largest source area an *unbounded* decode
    /// path may hold. Scale-decoding formats (JPEG/HEIC/TIFF/PNG) resize within a
    /// bounded working set via the thumbnail path, so this only gates WebP (no
    /// scaled decode) and full-resolution `AddImageFromSource` transcodes. Set
    /// above legitimate phone photos (~48MP) and below the multi-hundred-
    /// megapixel range that OOMs the memory-constrained share extension.
    private static let maxSourcePixels = 100_000_000

    // MARK: - Video

    /// A validated, decided video export: the output content type/extension and
    /// the chosen `AVAssetExportSession` preset (passthrough remux or re-encode).
    /// The source URL and output file type ride along for `writeVideo`. Carries
    /// only `Sendable` values, so it can cross the `await` between `planVideo`
    /// and `writeVideo`.
    public struct VideoPlan {
        public let contentType: UTType
        public let fileExtension: String

        fileprivate let sourceURL: URL
        fileprivate let outputType: AVFileType
        fileprivate let preset: String
    }

    /// Validates the duration cap and picks a passthrough or re-encode preset for
    /// the video at `sourceURL`. Reads the asset's duration and dimensions (hence
    /// `async`); throws `durationCapExceeded` for an over-long source.
    public func planVideo(for sourceURL: URL) async throws -> VideoPlan {
        let asset = AVURLAsset(url: sourceURL)
        let duration = try await asset.load(.duration).seconds
        // A non-finite duration (NaN for an indefinite/unreadable asset) must not
        // slip past a cap that exists — `NaN > cap` is false, so an unmeasurable
        // source would otherwise bypass the limit. Reject it fail-closed.
        if let cap = policy.videoMaxDurationSeconds, !duration.isFinite || duration > cap {
            throw MediaTransformerError.durationCapExceeded
        }
        let outputType = AVFileType(rawValue: policy.videoOutputContentType.identifier)
        let ext = policy.videoOutputContentType.preferredFilenameExtension ?? "mp4"
        let preset = try await resolveVideoExportPreset(for: asset, outputType: outputType)
        return VideoPlan(
            contentType: policy.videoOutputContentType,
            fileExtension: ext,
            sourceURL: sourceURL,
            outputType: outputType,
            preset: preset
        )
    }

    /// Exports `plan` to `destURL`, driving `progress` from a sibling poll of the
    /// session's `.progress`.
    ///
    /// `export(to:as:isolation:)` is `@backDeployed` to iOS 13, so the export
    /// runs structured even on the iOS 17 floor: it sets the output URL / file
    /// type itself, observes `Task` cancellation natively, and throws on failure
    /// instead of reporting through a callback. Progress still uses the legacy
    /// `session.progress` property because the modern `states(updateInterval:)`
    /// AsyncSequence is iOS 18+ and not back-deployed.
    public func writeVideo(_ plan: VideoPlan, to destURL: URL, progress: Progress) async throws {
        let asset = AVURLAsset(url: plan.sourceURL)
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: plan.preset) else {
            throw MediaTransformerError.videoExportSessionUnavailable
        }
        exportSession.shouldOptimizeForNetworkUse = true
        if policy.stripLocation {
            // `stripLocation` is the single "Remove Location" setting and
            // governs video too. `forSharing()` drops the QuickTime location atom
            // (and other identifying metadata), matching V1 MediaVideoExporter.
            // Verified to strip movie-level location on a passthrough remux — the
            // form iPhone captures use. `forSharing()` is an `AVMetadataItem`
            // filter, so location carried in a per-sample timed metadata track
            // may survive a passthrough copy; that case isn't exercised by our
            // tests — verify on a device-captured clip before relying on it.
            exportSession.metadataItemFilter = AVMetadataItemFilter.forSharing()
        }

        // `AVAssetExportSession` isn't `Sendable`, but the poll task only reads
        // `.progress`, which is safe to sample off the originating actor.
        nonisolated(unsafe) let session = exportSession
        let pollTask = Task { [progress] in
            while !Task.isCancelled {
                progress.completedUnitCount = Int64(
                    (Double(progress.totalUnitCount) * Double(session.progress)).rounded()
                )
                try? await Task.sleep(for: .milliseconds(100))
            }
        }
        defer { pollTask.cancel() }

        do {
            try await exportSession.export(to: destURL, as: plan.outputType)
        } catch {
            // Let cancellation propagate untouched so the uploader treats it as a
            // cancel rather than a failure; wrap everything else.
            if error is CancellationError { throw error }
            throw MediaTransformerError.videoExportFailed(underlyingError: error)
        }

        // Snap progress to full — the final poll may have been just shy of 1.0
        // when export returned.
        progress.completedUnitCount = progress.totalUnitCount
    }

    /// Chooses the export preset for `asset`. A source already within the
    /// resolution cap (or an uncapped one) is remuxed with
    /// `AVAssetExportPresetPassthrough` — the elementary streams are copied, not
    /// transcoded — as long as it can be written into `outputType`. The metadata
    /// filter still drops the movie-level QuickTime location atom on a passthrough
    /// export, so an in-limit located video is no longer re-encoded end to
    /// end just to be re-containered or to strip its location. Only a source that
    /// exceeds the cap, or can't be remuxed into `outputType` (an exotic codec),
    /// falls back to the policy's re-encode preset.
    func resolveVideoExportPreset(for asset: AVAsset, outputType: AVFileType) async throws -> String {
        if try await videoExceedsResolutionCap(asset) {
            return policy.videoExportPreset
        }
        guard
            let probe = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough),
            await compatibleFileTypes(of: probe).contains(outputType)
        else {
            return policy.videoExportPreset
        }
        return AVAssetExportPresetPassthrough
    }

    /// Whether `asset`'s longest (orientation-corrected) edge exceeds
    /// `policy.videoMaxDimension`. A missing cap means no limit. A source with no
    /// readable video track is treated as over-cap, so it re-encodes rather than
    /// risk passing an unmeasured file through the cap.
    private func videoExceedsResolutionCap(_ asset: AVAsset) async throws -> Bool {
        guard let cap = policy.videoMaxDimension, cap > 0 else { return false }
        guard let track = try await asset.loadTracks(withMediaType: .video).first else { return true }
        let (naturalSize, preferredTransform) = try await track.load(.naturalSize, .preferredTransform)
        let size = naturalSize.applying(preferredTransform)
        return max(abs(size.width), abs(size.height)) > CGFloat(cap)
    }

    /// The output container types `session` can write. Bridges the
    /// completion-handler API (the async form isn't back-deployed on the floor).
    private func compatibleFileTypes(of session: AVAssetExportSession) async -> [AVFileType] {
        await withCheckedContinuation { continuation in
            session.determineCompatibleFileTypes { continuation.resume(returning: $0) }
        }
    }

    /// Raster types that upload without format conversion. Everything else
    /// (HEIC, HEIF, TIFF, WebP, BMP, DNG, ...) is converted to JPEG, matching
    /// V1 `ItemProviderMediaExporter.supportedImageTypes`. GIF and SVG never
    /// reach the transformer — the materializer raw-copies them.
    private static let webSafeImageTypes: Set<UTType> = [.png, .jpeg]
}
