import Foundation
import FoundationModels
import NaturalLanguage
import Vision
import UIKit
import WordPressShared

public enum IntelligenceService {
    /// Maximum context size for language model sessions (in tokens).
    ///
    /// A single token corresponds to three or four characters in languages like
    /// English, Spanish, or German, and one token per character in languages like
    /// Japanese, Chinese, or Korean. In a single session, the sum of all tokens
    /// in the instructions, all prompts, and all outputs count toward the context window size.
    ///
    /// https://developer.apple.com/documentation/foundationmodels/generating-content-and-performing-tasks-with-foundation-models#Consider-context-size-limits-per-session
    public static let contextSizeLimit = 4096

    /// Checks if intelligence features are supported on the current device.
    public nonisolated static var isSupported: Bool {
        guard #available(iOS 26, *) else {
            return false
        }
        switch SystemLanguageModel.default.availability {
        case .available:
            return true
        case .unavailable(let reason):
            switch reason {
            case .appleIntelligenceNotEnabled, .modelNotReady:
                return true
            case .deviceNotEligible:
                return false
            @unknown default:
                return false
            }
        }
    }

    /// Extracts relevant text from post content, removing HTML and limiting size.
    public static func extractRelevantText(from post: String, ratio: CGFloat = 0.6) -> String {
        let extract = try? ContentExtractor.extractRelevantText(from: post)
        let postSizeLimit = Double(IntelligenceService.contextSizeLimit) * ratio
        return String((extract ?? post).prefix(Int(postSizeLimit)))
    }

    /// - note: As documented in https://developer.apple.com/documentation/foundationmodels/supporting-languages-and-locales-with-foundation-models?changes=_10_5#Use-Instructions-to-set-the-locale-and-language
    static func makeLocaleInstructions(for locale: Locale = Locale.current) -> String {
        if Locale.Language(identifier: "en_US").isEquivalent(to: locale.language) {
            return "" // Skip the locale phrase for U.S. English.
        }
        return "The person's locale is \(locale.identifier)."
    }

    /// Detects the dominant language of the given text.
    ///
    /// - Parameter text: The text to analyze
    /// - Returns: The detected language code (e.g., "en", "es", "fr", "ja"), or nil if detection fails
    public static func detectLanguage(from text: String) -> String? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)

        guard let languageCode = recognizer.dominantLanguage else {
            return nil
        }

        return languageCode.rawValue
    }

    /// Analyzes an image using Vision framework to extract comprehensive visual information.
    ///
    /// Uses multiple Vision APIs to gather detailed information about the image:
    /// - Image classification for scene and object identification
    /// - Text recognition for readable content
    /// - Face detection for portrait photos
    /// - Human and animal detection for subjects
    /// - Saliency analysis for key regions of interest
    /// - Horizon detection for landscape orientation
    /// - Barcode detection for QR codes and barcodes
    ///
    /// - Parameter cgImage: The image to analyze
    /// - Returns: A comprehensive description of what's in the image
    /// - Throws: If image analysis fails
    @available(iOS 26, *)
    public static func analyzeImage(_ cgImage: CGImage) async throws -> String {
        let startTime = CFAbsoluteTimeGetCurrent()

        var descriptions: [String] = []

        // Create all analysis requests
        let classifyRequest = VNClassifyImageRequest()
        let textRequest = VNRecognizeTextRequest()
        textRequest.recognitionLevel = .accurate

        let faceRequest = VNDetectFaceRectanglesRequest()
        let humanRequest = VNDetectHumanRectanglesRequest()
        let animalRequest = VNRecognizeAnimalsRequest()
        let saliencyRequest = VNGenerateAttentionBasedSaliencyImageRequest()
        let horizonRequest = VNDetectHorizonRequest()
        let barcodeRequest = VNDetectBarcodesRequest()

        // Perform all requests
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([
            classifyRequest,
            textRequest,
            faceRequest,
            humanRequest,
            animalRequest,
            saliencyRequest,
            horizonRequest,
            barcodeRequest
        ])

        // 1. Scene/Object Classification
        if let classifications = classifyRequest.results?.prefix(5) {
            let labels = classifications
                .filter { $0.confidence > 0.3 }
                .map { "\($0.identifier.replacingOccurrences(of: "_", with: " ")) (\(Int($0.confidence * 100))%)" }
            if !labels.isEmpty {
                descriptions.append("Scene: \(labels.joined(separator: ", "))")
            }
        }

        // 2. Subjects - Faces
        if let faceObservations = faceRequest.results, !faceObservations.isEmpty {
            let faceCount = faceObservations.count
            let faceDesc = faceCount == 1 ? "1 face" : "\(faceCount) faces"
            descriptions.append("Subjects: \(faceDesc) detected")
        }

        // 3. Subjects - Humans (full body)
        if let humanObservations = humanRequest.results, !humanObservations.isEmpty {
            let humanCount = humanObservations.count
            let humanDesc = humanCount == 1 ? "1 person" : "\(humanCount) people"

            // Only add if we didn't already mention faces, or if there are more humans than faces
            if let faceCount = faceRequest.results?.count, humanCount > faceCount {
                descriptions.append("Additional subjects: \(humanDesc) visible")
            } else if faceRequest.results?.isEmpty ?? true {
                descriptions.append("Subjects: \(humanDesc) detected")
            }
        }

        // 4. Animals
        if let animalObservations = animalRequest.results, !animalObservations.isEmpty {
            let animals = animalObservations
                .filter { $0.confidence > 0.5 }
                .compactMap { observation -> String? in
                    guard let label = observation.labels.first else { return nil }
                    return "\(label.identifier) (\(Int(label.confidence * 100))%)"
                }
            if !animals.isEmpty {
                descriptions.append("Animals: \(animals.joined(separator: ", "))")
            }
        }

        // 5. Saliency (regions of interest)
        if let saliencyObservations = saliencyRequest.results as? [VNSaliencyImageObservation],
           let observation = saliencyObservations.first,
           let salientObjects = observation.salientObjects, !salientObjects.isEmpty {
            descriptions.append("Key regions: \(salientObjects.count) area\(salientObjects.count == 1 ? "" : "s") of interest")
        }

        // 6. Horizon detection (indicates landscape/orientation)
        if let horizonObservations = horizonRequest.results, let horizon = horizonObservations.first {
            let angle = horizon.angle * 180 / .pi
            if abs(angle) > 5 { // Only mention if horizon is noticeably tilted
                descriptions.append("Composition: horizon at \(Int(angle))° angle")
            }
        }

        // 7. Text content
        if let textObservations = textRequest.results, !textObservations.isEmpty {
            let text = textObservations
                .compactMap { $0.topCandidates(1).first?.string }
                .joined(separator: " ")
            if !text.isEmpty {
                let truncatedText = String(text.prefix(100))
                descriptions.append("Text: \"\(truncatedText)\(text.count > 100 ? "..." : "")\"")
            }
        }

        // 8. Barcodes/QR codes
        if let barcodeObservations = barcodeRequest.results, !barcodeObservations.isEmpty {
            let barcodeTypes = barcodeObservations.compactMap { $0.symbology.rawValue }
            if !barcodeTypes.isEmpty {
                descriptions.append("Codes: \(barcodeTypes.joined(separator: ", "))")
            }
        }

        let description = descriptions.isEmpty
            ? "Image analyzed"
            : descriptions.joined(separator: "; ")

        WPLogInfo("IntelligenceService.analyzeImage executed in \((CFAbsoluteTimeGetCurrent() - startTime) * 1000) ms")

        return description
    }
}
