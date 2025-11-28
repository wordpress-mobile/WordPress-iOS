import Testing
import Foundation
import FoundationModels
import UIKit
@testable import WordPressIntelligence

@Suite(.serialized)
struct ImageAltTextGeneratorTests {

    // MARK: - Basic Tests

    @available(iOS 26, *)
    @Test("Generate alt text with full metadata")
    func generateAltTextWithFullMetadata() async throws {
        let metadata = MediaMetadata(
            filename: "beach-sunset.jpg",
            title: "Beautiful Beach Sunset",
            caption: "A stunning view of the ocean at golden hour",
            description: "Photograph taken at Bondi Beach during sunset",
            altText: nil,
            fileType: "JPEG",
            dimensions: "1920x1080",
            imageAnalysis: "Scene: beach, sunset, ocean; Colors: orange, purple, blue"
        )

        let generator = ImageAltTextGenerator()
        let (altText, duration) = try await TestHelpers.measure {
            try await generator.generate(metadata: metadata)
        }

        // Validations
        #expect(!altText.isEmpty, "Alt text should not be empty")
        #expect(altText.count <= 125, "Alt text should be concise (max 125 characters)")
        #expect(!altText.lowercased().contains("image of"), "Alt text should not contain 'image of'")
        #expect(!altText.lowercased().contains("picture of"), "Alt text should not contain 'picture of'")

        let durationSeconds = Double(duration.components.seconds) + Double(duration.components.attoseconds) / 1e18
        print("✓ Generated alt text in \(String(format: "%.2f", durationSeconds))s: \"\(altText)\"")
    }

    @available(iOS 26, *)
    @Test("Generate alt text with minimal metadata")
    func generateAltTextWithMinimalMetadata() async throws {
        let metadata = MediaMetadata(
            filename: "photo.jpg",
            title: nil,
            caption: nil,
            description: nil,
            altText: nil,
            fileType: "JPEG",
            dimensions: nil,
            imageAnalysis: nil
        )

        let generator = ImageAltTextGenerator()
        let altText = try await generator.generate(metadata: metadata)

        #expect(!altText.isEmpty, "Alt text should be generated even with minimal metadata")
        print("✓ Minimal metadata alt text: \"\(altText)\"")
    }

    @available(iOS 26, *)
    @Test("Generate alt text with image analysis only")
    func generateAltTextWithImageAnalysisOnly() async throws {
        let metadata = MediaMetadata(
            filename: nil,
            title: nil,
            caption: nil,
            description: nil,
            altText: nil,
            fileType: nil,
            dimensions: nil,
            imageAnalysis: "Scene: mountain, landscape, snow; Objects: trees, rocks"
        )

        let generator = ImageAltTextGenerator()
        let altText = try await generator.generate(metadata: metadata)

        #expect(!altText.isEmpty, "Alt text should be generated from image analysis")
        print("✓ Image analysis-only alt text: \"\(altText)\"")
    }

    @available(iOS 26, *)
    @Test("Generate alt text with real image analysis from cat.jpg")
    func generateAltTextWithRealImageAnalysis() async throws {
        // Load cat.jpg from test resources
        guard let imageURL = Bundle.module.url(forResource: "cat", withExtension: "jpg"),
              let imageData = try? Data(contentsOf: imageURL),
              let image = UIImage(data: imageData),
              let cgImage = image.cgImage else {
            Issue.record("Failed to load cat.jpg from test resources")
            return
        }

        // Perform real image analysis using Vision framework
        let imageAnalysis = try await IntelligenceService.analyzeImage(cgImage)
        #expect(!imageAnalysis.isEmpty, "Image analysis should return results")
        print("✓ Real image analysis result: \"\(imageAnalysis)\"")

        // Generate alt text using only the image analysis 
        let metadata = MediaMetadata(
            filename: nil,
            title: nil,
            caption: nil,
            description: nil,
            altText: nil,
            fileType: nil,
            dimensions: nil,
            imageAnalysis: imageAnalysis
        )

        let generator = ImageAltTextGenerator()
        let altText = try await generator.generate(metadata: metadata)

        #expect(!altText.isEmpty, "Alt text should be generated from real image analysis")
        #expect(altText.count <= 125, "Alt text should be under 125 characters")
        print("✓ Alt text from real image analysis: \"\(altText)\"")
    }

    @available(iOS 26, *)
    @Test("Generate alt text using convenience API with CGImage")
    func generateAltTextWithConvenienceAPICGImage() async throws {
        // Load cat.jpg from test resources
        guard let imageURL = Bundle.module.url(forResource: "cat", withExtension: "jpg", subdirectory: "Resources"),
              let imageData = try? Data(contentsOf: imageURL),
              let image = UIImage(data: imageData),
              let cgImage = image.cgImage else {
            Issue.record("Failed to load cat.jpg from test resources")
            return
        }

        // Use convenience API - Vision analysis is automatic
        let generator = ImageAltTextGenerator()
        let altText = try await generator.generate(cgImage: cgImage)

        #expect(!altText.isEmpty, "Alt text should be generated")
        #expect(altText.count <= 125, "Alt text should be under 125 characters")
        print("✓ Alt text from convenience API (CGImage): \"\(altText)\"")
    }

    @available(iOS 26, *)
    @Test("Generate alt text using convenience API with UIImage")
    func generateAltTextWithConvenienceAPIUIImage() async throws {
        // Load cat.jpg from test resources
        guard let imageURL = Bundle.module.url(forResource: "cat", withExtension: "jpg", subdirectory: "Resources"),
              let imageData = try? Data(contentsOf: imageURL),
              let image = UIImage(data: imageData) else {
            Issue.record("Failed to load cat.jpg from test resources")
            return
        }

        // Use convenience API with UIImage
        let generator = ImageAltTextGenerator()
        let altText = try await generator.generate(image: image)

        #expect(!altText.isEmpty, "Alt text should be generated")
        #expect(altText.count <= 125, "Alt text should be under 125 characters")
        print("✓ Alt text from convenience API (UIImage): \"\(altText)\"")
    }

    @available(iOS 26, *)
    @Test("Generate alt text using convenience API with Data")
    func generateAltTextWithConvenienceAPIData() async throws {
        // Load cat.jpg from test resources
        guard let imageURL = Bundle.module.url(forResource: "cat", withExtension: "jpg", subdirectory: "Resources"),
              let imageData = try? Data(contentsOf: imageURL) else {
            Issue.record("Failed to load cat.jpg from test resources")
            return
        }

        // Use convenience API with Data
        let generator = ImageAltTextGenerator()
        let altText = try await generator.generate(imageData: imageData)

        #expect(!altText.isEmpty, "Alt text should be generated")
        #expect(altText.count <= 125, "Alt text should be under 125 characters")
        print("✓ Alt text from convenience API (Data): \"\(altText)\"")
    }

    @available(iOS 26, *)
    @Test("Generate alt text using convenience API with additional metadata")
    func generateAltTextWithConvenienceAPIAndMetadata() async throws {
        // Load cat.jpg from test resources
        guard let imageURL = Bundle.module.url(forResource: "cat", withExtension: "jpg", subdirectory: "Resources"),
              let imageData = try? Data(contentsOf: imageURL),
              let image = UIImage(data: imageData),
              let cgImage = image.cgImage else {
            Issue.record("Failed to load cat.jpg from test resources")
            return
        }

        // Use convenience API with additional metadata
        let metadata = MediaMetadata(
            filename: "cat.jpg",
            title: "Cute Cat",
            caption: nil,
            description: "A photo of a cat",
            altText: nil,
            fileType: "JPEG",
            dimensions: "1024x680",
            imageAnalysis: nil  // Will be populated automatically
        )

        let generator = ImageAltTextGenerator()
        let altText = try await generator.generate(cgImage: cgImage, metadata: metadata)

        #expect(!altText.isEmpty, "Alt text should be generated")
        #expect(altText.count <= 125, "Alt text should be under 125 characters")
        print("✓ Alt text from convenience API with metadata: \"\(altText)\"")
    }

    @available(iOS 26, *)
    @Test("Generate alt text prioritizes image analysis")
    func generateAltTextPrioritizesImageAnalysis() async throws {
        let metadata = MediaMetadata(
            filename: "document.pdf",
            title: "Document",
            caption: nil,
            description: nil,
            altText: nil,
            fileType: "PDF",
            dimensions: nil,
            imageAnalysis: "Scene: forest, trees, wildlife; Objects: deer, birds"
        )

        let generator = ImageAltTextGenerator()
        let altText = try await generator.generate(metadata: metadata)

        #expect(!altText.isEmpty, "Alt text should be generated")
        // The alt text should reflect the image analysis (forest/trees/wildlife) rather than just "document"
        let lowerAltText = altText.lowercased()
        let hasImageContent = lowerAltText.contains("forest") ||
                             lowerAltText.contains("tree") ||
                             lowerAltText.contains("wildlife") ||
                             lowerAltText.contains("deer") ||
                             lowerAltText.contains("bird")
        #expect(hasImageContent, "Alt text should prioritize image analysis content")
        print("✓ Analysis-prioritized alt text: \"\(altText)\"")
    }

    // MARK: - Edge Cases

    @available(iOS 26, *)
    @Test("Insufficient metadata throws error")
    func insufficientMetadataThrowsError() async throws {
        let metadata = MediaMetadata(
            filename: nil,
            title: nil,
            caption: nil,
            description: nil,
            altText: nil,
            fileType: nil,
            dimensions: nil,
            imageAnalysis: nil
        )

        let generator = ImageAltTextGenerator()

        do {
            _ = try await generator.generate(metadata: metadata)
            Issue.record("Expected error for insufficient metadata but generation succeeded")
        } catch {
            let errorDescription = (error as NSError).userInfo[NSLocalizedDescriptionKey] as? String
            #expect(errorDescription?.contains("Insufficient metadata") ?? false,
                   "Error should indicate insufficient metadata")
            print("✓ Correctly threw error for insufficient metadata")
        }
    }

    @available(iOS 26, *)
    @Test("Alt text length is reasonable")
    func altTextLengthIsReasonable() async throws {
        let metadata = MediaMetadata(
            filename: "team-meeting.jpg",
            title: "Q4 Team Strategy Meeting",
            caption: "Our team discussing the quarterly strategy and planning for next year's initiatives",
            description: "A professional meeting room with team members gathered around a conference table",
            altText: nil,
            fileType: "JPEG",
            dimensions: "2048x1536",
            imageAnalysis: "Scene: office, meeting, indoor; Objects: people, table, laptops, documents"
        )

        let generator = ImageAltTextGenerator()
        let altText = try await generator.generate(metadata: metadata)

        let wordCount = altText.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
        #expect(wordCount >= 3, "Alt text should have at least a few words")
        #expect(wordCount <= 25, "Alt text should be concise (typically under 25 words)")
        #expect(altText.count <= 125, "Alt text should be under 125 characters")
        print("✓ Alt text length is appropriate (\(wordCount) words, \(altText.count) chars): \"\(altText)\"")
    }

    @available(iOS 26, *)
    @Test("Performance benchmark")
    func performanceBenchmark() async throws {
        let metadata = MediaMetadata(
            filename: "landscape.jpg",
            title: "Mountain Landscape",
            caption: "Scenic mountain view",
            description: "A beautiful mountain landscape with snow-capped peaks",
            altText: nil,
            fileType: "JPEG",
            dimensions: "4000x3000",
            imageAnalysis: "Scene: mountain, landscape, outdoor; Colors: white, blue, green"
        )

        let generator = ImageAltTextGenerator()
        let (altText, duration) = try await TestHelpers.measure {
            try await generator.generate(metadata: metadata)
        }

        let durationSeconds = Double(duration.components.seconds) + Double(duration.components.attoseconds) / 1e18
        #expect(duration <= .seconds(10), "Generation should complete within reasonable time")
        #expect(!altText.isEmpty, "Should generate alt text")

        print("✓ Performance: Generated alt text in \(String(format: "%.3f", durationSeconds))s")
    }

    // MARK: - Prompt Building Tests

    @available(iOS 26, *)
    @Test("Prompt includes all provided metadata")
    func promptIncludesAllMetadata() async throws {
        let metadata = MediaMetadata(
            filename: "test.jpg",
            title: "Test Title",
            caption: "Test Caption",
            description: "Test Description",
            altText: nil,
            fileType: "JPEG",
            dimensions: "1024x768",
            imageAnalysis: "Test Analysis"
        )

        let generator = ImageAltTextGenerator()
        let prompt = generator.makePrompt(metadata: metadata)

        #expect(prompt.contains("test.jpg"), "Prompt should include filename")
        #expect(prompt.contains("Test Title"), "Prompt should include title")
        #expect(prompt.contains("Test Caption"), "Prompt should include caption")
        #expect(prompt.contains("Test Description"), "Prompt should include description")
        #expect(prompt.contains("JPEG"), "Prompt should include file type")
        #expect(prompt.contains("1024x768"), "Prompt should include dimensions")
        #expect(prompt.contains("Test Analysis"), "Prompt should include image analysis")
        print("✓ Prompt correctly includes all metadata fields")
    }

    @available(iOS 26, *)
    @Test("Prompt excludes nil fields")
    func promptExcludesNilFields() async throws {
        let metadata = MediaMetadata(
            filename: "test.jpg",
            title: nil,
            caption: nil,
            description: nil,
            altText: nil,
            fileType: nil,
            dimensions: nil,
            imageAnalysis: nil
        )

        let generator = ImageAltTextGenerator()
        let prompt = generator.makePrompt(metadata: metadata)

        #expect(!prompt.contains("TITLE:"), "Prompt should not include TITLE when nil")
        #expect(!prompt.contains("CAPTION:"), "Prompt should not include CAPTION when nil")
        #expect(!prompt.contains("DESCRIPTION:"), "Prompt should not include DESCRIPTION when nil")
        print("✓ Prompt correctly excludes nil fields")
    }
}
