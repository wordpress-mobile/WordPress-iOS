import Foundation
import FoundationModels
import UIKit
import WordPressShared

/// Alt text generation for media items.
///
/// Generates concise, descriptive, and accessible alt text for images based on
/// visual analysis and available metadata.
///
/// Example usage:
/// ```swift
/// let generator = ImageAltTextGenerator()
/// let altText = try await generator.generate(metadata: metadata)
/// ```
@available(iOS 26, *)
public struct ImageAltTextGenerator {
    public var options: GenerationOptions

    public init(options: GenerationOptions = GenerationOptions(temperature: 0.3)) {
        self.options = options
    }

    /// Generates alt text for a media item.
    ///
    /// - Parameter metadata: The media metadata to use for generation
    /// - Returns: Generated alt text
    /// - Throws: If metadata is insufficient or generation fails
    public func generate(metadata: MediaMetadata) async throws -> String {
        guard metadata.hasContent else {
            throw NSError(domain: "IntelligenceService", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Insufficient metadata to generate alt text. Please add a filename, title, or description first."
            ])
        }

        let startTime = CFAbsoluteTimeGetCurrent()
        let session = makeSession()
        let prompt = makePrompt(metadata: metadata)

        let response = try await session.respond(to: prompt, options: options)

        WPLogInfo("ImageAltTextGenerator executed in \((CFAbsoluteTimeGetCurrent() - startTime) * 1000) ms")

        return response.content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Generates alt text for an image with automatic Vision analysis.
    ///
    /// This convenience method automatically analyzes the image using Vision framework
    /// and generates alt text based on the analysis combined with provided metadata.
    ///
    /// - Parameters:
    ///   - cgImage: The image to analyze and generate alt text for
    ///   - metadata: Additional metadata (filename, title, etc.). The imageAnalysis field will be populated automatically.
    /// - Returns: Generated alt text
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

    /// Generates alt text for an image with automatic Vision analysis.
    ///
    /// This convenience method automatically analyzes the image using Vision framework
    /// and generates alt text based on the analysis combined with provided metadata.
    ///
    /// - Parameters:
    ///   - image: The UIImage to analyze and generate alt text for
    ///   - metadata: Additional metadata (filename, title, etc.). The imageAnalysis field will be populated automatically.
    /// - Returns: Generated alt text
    /// - Throws: If the image cannot be converted to CGImage, or if analysis/generation fails
    public func generate(image: UIImage, metadata: MediaMetadata = MediaMetadata()) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw NSError(domain: "IntelligenceService", code: -2, userInfo: [
                NSLocalizedDescriptionKey: "Unable to convert UIImage to CGImage"
            ])
        }
        return try await generate(cgImage: cgImage, metadata: metadata)
    }

    /// Generates alt text for image data with automatic Vision analysis.
    ///
    /// This convenience method automatically analyzes the image using Vision framework
    /// and generates alt text based on the analysis combined with provided metadata.
    ///
    /// - Parameters:
    ///   - imageData: The image data to analyze and generate alt text for
    ///   - metadata: Additional metadata (filename, title, etc.). The imageAnalysis field will be populated automatically.
    /// - Returns: Generated alt text
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

    /// Creates a language model session configured for alt text generation.
    ///
    /// - Returns: Configured session with instructions
    public func makeSession() -> LanguageModelSession {
        LanguageModelSession(
            model: .init(guardrails: .permissiveContentTransformations),
            instructions: Self.instructions
        )
    }

    /// Instructions for the language model on how to generate alt text.
    public static var instructions: String {
        """
        You are helping a WordPress user generate alt text for an image.
        Alt text should be descriptive and accessible for screen readers.

        **Parameters**
        - IMAGE_ANALYSIS: Structured JSON with comprehensive visual analysis (MOST IMPORTANT)
          The JSON includes: sceneClassification, faces (with position, size, features), humans, animals,
          text content, orientation, regions of interest, barcodes, and document detection
        - FILENAME: the image filename
        - FILE_TYPE: the file type/extension
        - DIMENSIONS: the image dimensions
        - TITLE: the image title (if available)
        - CAPTION: the image caption (if available)
        - DESCRIPTION: the image description (if available)

        **Requirements**
        - For simple images: 1-2 sentences describing the main subject and action
        - For complex images (charts, infographics, screenshots): 2-3 sentences explaining key information
        - Parse the JSON IMAGE_ANALYSIS to understand:
          * Scene/subject: Use sceneClassification labels with highest confidence
          * People: Check faces/humans data for count, position (left/center/right), and shot type (closeup/medium/distant)
          * Spatial layout: Use position and orientation data to describe composition
          * Text: If text is prominent, include key text content verbatim
          * Documents/Screenshots: Mention if containsDocument is true
        - Prioritize information based on:
          1. Primary subject (faces, humans, animals, main scene)
          2. Actions or relationships between subjects
          3. Setting/context from scene classification
          4. Important text content (if present)
        - Use specific, concrete descriptions based on the data
        - Use simple, clear language
        - Do not include "image of", "picture of", or "photo of"
        - Do not describe decorative or insignificant details
        - For portraits: Include shot type (closeup/medium) and position if relevant
        - For screenshots: Mention it's a screenshot and describe the key visible element
        - For images with text: Include the most important text content

        **Examples**
        Good: "Person smiling in closeup portrait with outdoor background"
        Good: "Three people standing left to right in conference room"
        Good: "Screenshot of WordPress editor with Publish button highlighted"
        Good: "Bar chart showing 45% increase in website traffic during Q3"
        Bad: "A person" (too vague, missing details from analysis)
        Bad: "Image of a chart" (avoid "image of", describe what the chart shows)

        Only output the alt text, nothing else.
        """
    }

    /// Builds the prompt for generating alt text.
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
        if let caption = metadata.caption, !caption.isEmpty {
            contextParts.append("CAPTION: '\(caption)'")
        }
        if let description = metadata.description, !description.isEmpty {
            contextParts.append("DESCRIPTION: '\(description)'")
        }

        return """
        Generate alt text for an image with the following information:

        \(contextParts.joined(separator: "\n"))
        """
    }
}

@available(iOS 26, *)
extension IntelligenceService {
    /// Generates alt text for a media item based on available metadata.
    ///
    /// - Parameter metadata: The media metadata to use for generation
    /// - Returns: Generated alt text
    /// - Throws: If metadata is insufficient or generation fails
    public func generateAltText(metadata: MediaMetadata) async throws -> String {
        try await ImageAltTextGenerator().generate(metadata: metadata)
    }
}
