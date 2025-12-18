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
    /// - Face detection and landmarks for portraits
    /// - Human and animal detection for subjects
    /// - Saliency analysis for key regions of interest
    /// - Horizon detection for landscape orientation
    /// - Barcode detection for QR codes and barcodes
    /// - Document detection for papers and screenshots
    ///
    /// - Parameter cgImage: The image to analyze
    /// - Returns: A JSON string with structured analysis data
    /// - Throws: If image analysis fails
    @available(iOS 26, *)
    public static func analyzeImage(_ cgImage: CGImage) async throws -> String {
        let startTime = CFAbsoluteTimeGetCurrent()

        // Create all analysis requests
        let classifyRequest = VNClassifyImageRequest()
        let textRequest = VNRecognizeTextRequest()
        textRequest.recognitionLevel = .accurate
        textRequest.usesLanguageCorrection = true

        let faceRequest = VNDetectFaceRectanglesRequest()
        let faceLandmarksRequest = VNDetectFaceLandmarksRequest()
        let humanRequest = VNDetectHumanRectanglesRequest()
        let animalRequest = VNRecognizeAnimalsRequest()
        let saliencyRequest = VNGenerateAttentionBasedSaliencyImageRequest()
        let horizonRequest = VNDetectHorizonRequest()
        let barcodeRequest = VNDetectBarcodesRequest()
        let documentRequest = VNDetectDocumentSegmentationRequest()

        // Perform all requests
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([
            classifyRequest,
            textRequest,
            faceRequest,
            faceLandmarksRequest,
            humanRequest,
            animalRequest,
            saliencyRequest,
            horizonRequest,
            barcodeRequest,
            documentRequest
        ])

        // Build structured analysis result
        var analysis: [String: Any] = [:]

        // Image dimensions
        analysis["imageSize"] = [
            "width": cgImage.width,
            "height": cgImage.height
        ]

        let aspectRatio = Double(cgImage.width) / Double(cgImage.height)
        if aspectRatio > 1.5 {
            analysis["orientation"] = "landscape"
        } else if aspectRatio < 0.7 {
            analysis["orientation"] = "portrait"
        } else {
            analysis["orientation"] = "square"
        }

        // 1. Scene/Object Classification
        if let classifications = classifyRequest.results?.prefix(5) {
            let labels = classifications
                .filter { $0.confidence > 0.3 }
                .map { [
                    "label": $0.identifier.replacingOccurrences(of: "_", with: " "),
                    "confidence": Int($0.confidence * 100)
                ] as [String: Any] }
            if !labels.isEmpty {
                analysis["sceneClassification"] = labels
            }
        }

        // 2. Face Detection with Landmarks
        var facesData: [[String: Any]] = []
        if let faceObservations = faceLandmarksRequest.results, !faceObservations.isEmpty {
            for face in faceObservations {
                var faceInfo: [String: Any] = [:]

                // Position
                let bounds = face.boundingBox
                if bounds.origin.x < 0.33 {
                    faceInfo["horizontalPosition"] = "left"
                } else if bounds.origin.x > 0.66 {
                    faceInfo["horizontalPosition"] = "right"
                } else {
                    faceInfo["horizontalPosition"] = "center"
                }

                if bounds.origin.y < 0.33 {
                    faceInfo["verticalPosition"] = "bottom"
                } else if bounds.origin.y > 0.66 {
                    faceInfo["verticalPosition"] = "top"
                } else {
                    faceInfo["verticalPosition"] = "middle"
                }

                // Size (relative to image)
                let faceArea = bounds.width * bounds.height
                if faceArea > 0.25 {
                    faceInfo["size"] = "closeup"
                } else if faceArea > 0.1 {
                    faceInfo["size"] = "medium"
                } else {
                    faceInfo["size"] = "distant"
                }

                // Landmarks details
                if let landmarks = face.landmarks {
                    var landmarksInfo: [String] = []
                    if landmarks.faceContour != nil { landmarksInfo.append("face contour") }
                    if landmarks.leftEye != nil { landmarksInfo.append("left eye") }
                    if landmarks.rightEye != nil { landmarksInfo.append("right eye") }
                    if landmarks.nose != nil { landmarksInfo.append("nose") }
                    if landmarks.outerLips != nil { landmarksInfo.append("mouth") }
                    faceInfo["detectedFeatures"] = landmarksInfo
                }

                facesData.append(faceInfo)
            }
            analysis["faces"] = [
                "count": faceObservations.count,
                "details": facesData
            ]
        }

        // 3. Human Detection (full body)
        if let humanObservations = humanRequest.results, !humanObservations.isEmpty {
            let humanData = humanObservations.map { observation -> [String: Any] in
                let bounds = observation.boundingBox
                return [
                    "confidence": Int(observation.confidence * 100),
                    "size": bounds.width * bounds.height > 0.2 ? "prominent" : "background"
                ]
            }
            analysis["humans"] = [
                "count": humanObservations.count,
                "details": humanData
            ]
        }

        // 4. Animals
        if let animalObservations = animalRequest.results, !animalObservations.isEmpty {
            let animals = animalObservations
                .filter { $0.confidence > 0.5 }
                .compactMap { observation -> [String: Any]? in
                    guard let label = observation.labels.first else { return nil }
                    return [
                        "type": label.identifier,
                        "confidence": Int(label.confidence * 100)
                    ]
                }
            if !animals.isEmpty {
                analysis["animals"] = animals
            }
        }

        // 5. Saliency (regions of interest)
        if let saliencyObservations = saliencyRequest.results as? [VNSaliencyImageObservation],
           let observation = saliencyObservations.first,
           let salientObjects = observation.salientObjects, !salientObjects.isEmpty {
            let regions = salientObjects.map { object -> [String: Any] in
                let bounds = object.boundingBox
                var position = ""
                if bounds.origin.x < 0.33 {
                    position = "left"
                } else if bounds.origin.x > 0.66 {
                    position = "right"
                } else {
                    position = "center"
                }
                return [
                    "position": position,
                    "confidence": Int(object.confidence * 100)
                ]
            }
            analysis["regionsOfInterest"] = [
                "count": salientObjects.count,
                "regions": regions
            ]
        }

        // 6. Horizon detection
        if let horizonObservations = horizonRequest.results, let horizon = horizonObservations.first {
            let angle = horizon.angle * 180 / .pi
            if abs(angle) > 5 {
                analysis["horizon"] = [
                    "angle": Int(angle),
                    "tilt": angle > 0 ? "clockwise" : "counterclockwise"
                ]
            }
        }

        // 7. Text content
        if let textObservations = textRequest.results, !textObservations.isEmpty {
            let textLines = textObservations.compactMap { observation -> [String: Any]? in
                guard let text = observation.topCandidates(1).first?.string else { return nil }
                return [
                    "text": text,
                    "confidence": Int(observation.confidence * 100)
                ]
            }
            if !textLines.isEmpty {
                let fullText = textLines.compactMap { $0["text"] as? String }.joined(separator: " ")
                analysis["text"] = [
                    "fullText": String(fullText.prefix(500)),
                    "lineCount": textLines.count,
                    "lines": textLines.prefix(10)
                ]
            }
        }

        // 8. Barcodes/QR codes
        if let barcodeObservations = barcodeRequest.results, !barcodeObservations.isEmpty {
            let barcodes = barcodeObservations.compactMap { barcode -> [String: Any]? in
                var barcodeInfo: [String: Any] = [
                    "type": barcode.symbology.rawValue
                ]
                if let payload = barcode.payloadStringValue {
                    barcodeInfo["payload"] = payload
                }
                return barcodeInfo
            }
            analysis["barcodes"] = barcodes
        }

        // 9. Document detection
        if let documentObservations = documentRequest.results, !documentObservations.isEmpty {
            analysis["containsDocument"] = true
            analysis["documentCount"] = documentObservations.count
        }

        // Convert to JSON string
        let jsonData = try JSONSerialization.data(withJSONObject: analysis, options: [.prettyPrinted, .sortedKeys])
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw NSError(domain: "IntelligenceService", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Failed to convert analysis to JSON"
            ])
        }

        WPLogInfo("IntelligenceService.analyzeImage executed in \((CFAbsoluteTimeGetCurrent() - startTime) * 1000) ms")

        return jsonString
    }
}
