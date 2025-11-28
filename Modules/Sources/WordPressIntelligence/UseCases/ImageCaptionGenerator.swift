import Foundation
import FoundationModels
import UIKit
import WordPressShared

/// Caption generation for media items.
///
/// Generates engaging, informative captions for images based on
/// visual analysis and available metadata.
///
/// Example usage:
/// ```swift
/// let generator = ImageCaptionGenerator()
/// let caption = try await generator.generate(metadata: metadata)
/// ```
@available(iOS 26, *)
public struct ImageCaptionGenerator {
    public var options: GenerationOptions

    public init(options: GenerationOptions = GenerationOptions(temperature: 0.8)) {
        self.options = options
    }

    /// Generates a caption for a media item.
    ///
    /// - Parameter metadata: The media metadata to use for generation
    /// - Returns: Generated caption
    /// - Throws: If metadata is insufficient or generation fails
    public func generate(metadata: MediaMetadata) async throws -> String {
        guard metadata.hasContent else {
            throw NSError(domain: "IntelligenceService", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Insufficient metadata to generate caption. Please add a filename, title, or description first."
            ])
        }

        let startTime = CFAbsoluteTimeGetCurrent()
        let session = makeSession()
        let prompt = makePrompt(metadata: metadata)

        let response = try await session.respond(to: prompt, options: options)

        WPLogInfo("ImageCaptionGenerator executed in \((CFAbsoluteTimeGetCurrent() - startTime) * 1000) ms")

        return response.content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Generates a caption for an image with automatic Vision analysis.
    ///
    /// This convenience method automatically analyzes the image using Vision framework
    /// and generates a caption based on the analysis combined with provided metadata.
    ///
    /// - Parameters:
    ///   - cgImage: The image to analyze and generate caption for
    ///   - metadata: Additional metadata (filename, title, etc.). The imageAnalysis field will be populated automatically.
    /// - Returns: Generated caption
    /// - Throws: If image analysis or generation fails
    public func generate(cgImage: CGImage, metadata: MediaMetadata = MediaMetadata()) async throws -> String {
        let imageAnalysis = try await IntelligenceService.analyzeImage(cgImage)

        let metadataWithAnalysis = MediaMetadata(
            filename: metadata.filename,
            title: metadata.title,
            caption: metadata.caption,
            description: metadata.description,
            altText: metadata.altText,
            fileType: metadata.fileType,
            dimensions: metadata.dimensions,
            imageAnalysis: imageAnalysis
        )

        return try await generate(metadata: metadataWithAnalysis)
    }

    /// Generates a caption for an image with automatic Vision analysis.
    ///
    /// This convenience method automatically analyzes the image using Vision framework
    /// and generates a caption based on the analysis combined with provided metadata.
    ///
    /// - Parameters:
    ///   - image: The UIImage to analyze and generate caption for
    ///   - metadata: Additional metadata (filename, title, etc.). The imageAnalysis field will be populated automatically.
    /// - Returns: Generated caption
    /// - Throws: If the image cannot be converted to CGImage, or if analysis/generation fails
    public func generate(image: UIImage, metadata: MediaMetadata = MediaMetadata()) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw NSError(domain: "IntelligenceService", code: -2, userInfo: [
                NSLocalizedDescriptionKey: "Unable to convert UIImage to CGImage"
            ])
        }
        return try await generate(cgImage: cgImage, metadata: metadata)
    }

    /// Generates a caption for image data with automatic VisionKit analysis.
    ///
    /// This convenience method automatically analyzes the image using VisionKit
    /// and generates a caption based on the analysis combined with provided metadata.
    ///
    /// - Parameters:
    ///   - imageData: The image data to analyze and generate caption for
    ///   - metadata: Additional metadata (filename, title, etc.). The imageAnalysis field will be populated automatically.
    /// - Returns: Generated caption
    /// - Throws: If the data cannot be converted to an image, or if analysis/generation fails
    public func generate(imageData: Data, metadata: MediaMetadata = MediaMetadata()) async throws -> String {
        guard let image = UIImage(data: imageData) else {
            throw NSError(domain: "IntelligenceService", code: -3, userInfo: [
                NSLocalizedDescriptionKey: "Unable to create UIImage from data"
            ])
        }
        return try await generate(image: image, metadata: metadata)
    }

    // MARK: - Session & Prompt Building

    /// Creates a language model session configured for caption generation.
    ///
    /// - Returns: Configured session with instructions
    public func makeSession() -> LanguageModelSession {
        LanguageModelSession(
            model: .init(guardrails: .permissiveContentTransformations),
            instructions: Self.instructions
        )
    }

    /// Instructions for the language model on how to generate captions.
    public static var instructions: String {
        """
        You are helping a WordPress user generate a caption for an image.
        Captions should be engaging, informative, and complement the image.

        **Parameters**
        - IMAGE_ANALYSIS: Visual analysis of the actual image content (MOST IMPORTANT)
        - FILENAME: the image filename
        - FILE_TYPE: the file type/extension
        - DIMENSIONS: the image dimensions
        - TITLE: the image title (if available)
        - ALT_TEXT: the image alt text (if available)
        - DESCRIPTION: the image description (if available)

        **Requirements**
        - Generate an engaging caption (1-2 sentences)
        - Prioritize IMAGE_ANALYSIS to understand what's actually in the image
        - Can be more creative and conversational than alt text
        - May include context, emotion, or storytelling elements
        - Only output the caption, nothing else
        """
    }

    /// Builds the prompt for generating captions.
    ///
    /// - Parameter metadata: The media metadata
    /// - Returns: Formatted prompt string ready for the language model
    public func makePrompt(metadata: MediaMetadata) -> String {
        var contextParts: [String] = []

        if let imageAnalysis = metadata.imageAnalysis, !imageAnalysis.isEmpty {
            contextParts.append("IMAGE_ANALYSIS: '\(imageAnalysis)'")
        }
        if let filename = metadata.filename, !filename.isEmpty {
            contextParts.append("FILENAME: '\(filename)'")
        }
        if let fileType = metadata.fileType, !fileType.isEmpty {
            contextParts.append("FILE_TYPE: '\(fileType)'")
        }
        if let dimensions = metadata.dimensions, !dimensions.isEmpty {
            contextParts.append("DIMENSIONS: '\(dimensions)'")
        }
        if let title = metadata.title, !title.isEmpty {
            contextParts.append("TITLE: '\(title)'")
        }
        if let altText = metadata.altText, !altText.isEmpty {
            contextParts.append("ALT_TEXT: '\(altText)'")
        }
        if let description = metadata.description, !description.isEmpty {
            contextParts.append("DESCRIPTION: '\(description)'")
        }

        return """
        Generate a caption for an image with the following information:

        \(contextParts.joined(separator: "\n"))
        """
    }
}

@available(iOS 26, *)
extension IntelligenceService {
    /// Generates a caption for a media item based on available metadata.
    ///
    /// - Parameter metadata: The media metadata to use for generation
    /// - Returns: Generated caption
    /// - Throws: If metadata is insufficient or generation fails
    public func generateCaption(metadata: MediaMetadata) async throws -> String {
        try await ImageCaptionGenerator().generate(metadata: metadata)
    }
}
