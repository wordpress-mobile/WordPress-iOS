import Testing
import Foundation
import FoundationModels
import UIKit
@testable import WordPressIntelligence

@Suite(.serialized)
struct ImageCaptionGeneratorTests {

    // MARK: - Basic Tests

    @available(iOS 26, *)
    @Test("Generate caption with full metadata")
    func generateCaptionWithFullMetadata() async throws {
        let metadata = MediaMetadata(
            filename: "beach-sunset.jpg",
            title: "Beautiful Beach Sunset",
            caption: nil,
            description: "Photograph taken at Bondi Beach during sunset",
            altText: "Golden sunset over ocean waves at Bondi Beach",
            fileType: "JPEG",
            dimensions: "1920x1080",
            imageAnalysis: "Scene: beach, sunset, ocean; Colors: orange, purple, blue"
        )

        let generator = ImageCaptionGenerator()
        let (caption, duration) = try await TestHelpers.measure {
            try await generator.generate(metadata: metadata)
        }

        // Validations
        #expect(!caption.isEmpty, "Caption should not be empty")

        let durationSeconds = Double(duration.components.seconds) + Double(duration.components.attoseconds) / 1e18
        print("✓ Generated caption in \(String(format: "%.2f", durationSeconds))s: \"\(caption)\"")
    }

    @available(iOS 26, *)
    @Test("Generate caption with minimal metadata")
    func generateCaptionWithMinimalMetadata() async throws {
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

        let generator = ImageCaptionGenerator()
        let caption = try await generator.generate(metadata: metadata)

        #expect(!caption.isEmpty, "Caption should be generated even with minimal metadata")
        print("✓ Minimal metadata caption: \"\(caption)\"")
    }

    @available(iOS 26, *)
    @Test("Generate caption with image analysis only")
    func generateCaptionWithImageAnalysisOnly() async throws {
        let metadata = MediaMetadata(
            filename: nil,
            title: nil,
            caption: nil,
            description: nil,
            altText: nil,
            fileType: nil,
            dimensions: nil,
            imageAnalysis: "Scene: mountain, landscape, snow; Objects: trees, rocks; Colors: white, blue, green"
        )

        let generator = ImageCaptionGenerator()
        let caption = try await generator.generate(metadata: metadata)

        #expect(!caption.isEmpty, "Caption should be generated from image analysis")
        print("✓ Image analysis-only caption: \"\(caption)\"")
    }

    @available(iOS 26, *)
    @Test("Generate caption with real image analysis from cat.jpg")
    func generateCaptionWithRealImageAnalysis() async throws {
        // Load cat.jpg from test resources
        guard let imageURL = Bundle.module.url(forResource: "cat", withExtension: "jpg", subdirectory: "Resources"),
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

        // Generate caption using only the image analysis
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

        let generator = ImageCaptionGenerator()
        let caption = try await generator.generate(metadata: metadata)

        #expect(!caption.isEmpty, "Caption should be generated from real image analysis")
        print("✓ Caption from real image analysis: \"\(caption)\"")
    }

    @available(iOS 26, *)
    @Test("Generate caption using convenience API with CGImage")
    func generateCaptionWithConvenienceAPICGImage() async throws {
        // Load cat.jpg from test resources
        guard let imageURL = Bundle.module.url(forResource: "cat", withExtension: "jpg", subdirectory: "Resources"),
              let imageData = try? Data(contentsOf: imageURL),
              let image = UIImage(data: imageData),
              let cgImage = image.cgImage else {
            Issue.record("Failed to load cat.jpg from test resources")
            return
        }

        // Use convenience API - Vision analysis is automatic
        let generator = ImageCaptionGenerator()
        let caption = try await generator.generate(cgImage: cgImage)

        #expect(!caption.isEmpty, "Caption should be generated")
        print("✓ Caption from convenience API (CGImage): \"\(caption)\"")
    }

    @available(iOS 26, *)
    @Test("Generate caption using convenience API with UIImage")
    func generateCaptionWithConvenienceAPIUIImage() async throws {
        // Load cat.jpg from test resources
        guard let imageURL = Bundle.module.url(forResource: "cat", withExtension: "jpg", subdirectory: "Resources"),
              let imageData = try? Data(contentsOf: imageURL),
              let image = UIImage(data: imageData) else {
            Issue.record("Failed to load cat.jpg from test resources")
            return
        }

        // Use convenience API with UIImage
        let generator = ImageCaptionGenerator()
        let caption = try await generator.generate(image: image)

        #expect(!caption.isEmpty, "Caption should be generated")
        print("✓ Caption from convenience API (UIImage): \"\(caption)\"")
    }

    @available(iOS 26, *)
    @Test("Generate caption using convenience API with Data")
    func generateCaptionWithConvenienceAPIData() async throws {
        // Load cat.jpg from test resources
        guard let imageURL = Bundle.module.url(forResource: "cat", withExtension: "jpg", subdirectory: "Resources"),
              let imageData = try? Data(contentsOf: imageURL) else {
            Issue.record("Failed to load cat.jpg from test resources")
            return
        }

        // Use convenience API with Data
        let generator = ImageCaptionGenerator()
        let caption = try await generator.generate(imageData: imageData)

        #expect(!caption.isEmpty, "Caption should be generated")
        print("✓ Caption from convenience API (Data): \"\(caption)\"")
    }

    @available(iOS 26, *)
    @Test("Generate caption prioritizes image analysis")
    func generateCaptionPrioritizesImageAnalysis() async throws {
        let metadata = MediaMetadata(
            filename: "document.pdf",
            title: "Document",
            caption: nil,
            description: nil,
            altText: nil,
            fileType: "PDF",
            dimensions: nil,
            imageAnalysis: "Scene: forest, trees, wildlife; Objects: deer, birds; Colors: green, brown"
        )

        let generator = ImageCaptionGenerator()
        let caption = try await generator.generate(metadata: metadata)

        #expect(!caption.isEmpty, "Caption should be generated")
        // The caption should reflect the image analysis (forest/trees/wildlife) rather than just "document"
        let lowerCaption = caption.lowercased()
        let hasImageContent = lowerCaption.contains("forest") ||
                             lowerCaption.contains("tree") ||
                             lowerCaption.contains("wildlife") ||
                             lowerCaption.contains("deer") ||
                             lowerCaption.contains("bird") ||
                             lowerCaption.contains("nature")
        #expect(hasImageContent, "Caption should prioritize image analysis content")
        print("✓ Analysis-prioritized caption: \"\(caption)\"")
    }

    @available(iOS 26, *)
    @Test("Generate caption with existing alt text")
    func generateCaptionWithExistingAltText() async throws {
        let metadata = MediaMetadata(
            filename: "coffee-shop.jpg",
            title: "Morning Coffee",
            caption: nil,
            description: nil,
            altText: "Person enjoying coffee at outdoor cafe table",
            fileType: "JPEG",
            dimensions: "1600x900",
            imageAnalysis: "Scene: cafe, outdoor, urban; Objects: coffee cup, person, table, chair"
        )

        let generator = ImageCaptionGenerator()
        let caption = try await generator.generate(metadata: metadata)

        #expect(!caption.isEmpty, "Caption should be generated")
        // Caption can be more creative/engaging than the alt text
        print("✓ Caption with alt text context: \"\(caption)\"")
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

        let generator = ImageCaptionGenerator()

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
    @Test("Caption length is reasonable")
    func captionLengthIsReasonable() async throws {
        let metadata = MediaMetadata(
            filename: "team-meeting.jpg",
            title: "Q4 Team Strategy Meeting",
            caption: nil,
            description: "A professional meeting room with team members gathered around a conference table",
            altText: "Team members collaborating in conference room",
            fileType: "JPEG",
            dimensions: "2048x1536",
            imageAnalysis: "Scene: office, meeting, indoor; Objects: people, table, laptops, documents"
        )

        let generator = ImageCaptionGenerator()
        let caption = try await generator.generate(metadata: metadata)

        let wordCount = caption.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
        // Captions can be slightly longer than alt text (1-2 sentences)
        #expect(wordCount >= 3, "Caption should have at least a few words")
        #expect(wordCount <= 50, "Caption should be concise (typically 1-2 sentences)")
        print("✓ Caption length is appropriate (\(wordCount) words): \"\(caption)\"")
    }

    @available(iOS 26, *)
    @Test("Caption is more creative than alt text would be")
    func captionIsMoreCreative() async throws {
        let metadata = MediaMetadata(
            filename: "sunrise.jpg",
            title: "Morning Sunrise",
            caption: nil,
            description: "Early morning landscape",
            altText: "Sunrise over mountains with clouds",
            fileType: "JPEG",
            dimensions: "3000x2000",
            imageAnalysis: "Scene: sunrise, mountains, clouds; Colors: orange, pink, purple, blue"
        )

        let generator = ImageCaptionGenerator()
        let caption = try await generator.generate(metadata: metadata)

        #expect(!caption.isEmpty, "Caption should be generated")
        // Caption should be more than just a description - it can be creative/engaging
        // We just verify it was generated successfully; manual inspection would confirm creativity
        print("✓ Creative caption: \"\(caption)\"")
    }

    @available(iOS 26, *)
    @Test("Performance benchmark")
    func performanceBenchmark() async throws {
        let metadata = MediaMetadata(
            filename: "landscape.jpg",
            title: "Mountain Landscape",
            caption: nil,
            description: "A beautiful mountain landscape with snow-capped peaks",
            altText: "Snow-capped mountains under blue sky",
            fileType: "JPEG",
            dimensions: "4000x3000",
            imageAnalysis: "Scene: mountain, landscape, outdoor; Colors: white, blue, green"
        )

        let generator = ImageCaptionGenerator()
        let (caption, duration) = try await TestHelpers.measure {
            try await generator.generate(metadata: metadata)
        }

        let durationSeconds = Double(duration.components.seconds) + Double(duration.components.attoseconds) / 1e18
        #expect(duration <= .seconds(10), "Generation should complete within reasonable time")
        #expect(!caption.isEmpty, "Should generate caption")

        print("✓ Performance: Generated caption in \(String(format: "%.3f", durationSeconds))s")
    }

    // MARK: - Prompt Building Tests

    @available(iOS 26, *)
    @Test("Prompt includes all provided metadata")
    func promptIncludesAllMetadata() async throws {
        let metadata = MediaMetadata(
            filename: "test.jpg",
            title: "Test Title",
            caption: nil,
            description: "Test Description",
            altText: "Test Alt Text",
            fileType: "JPEG",
            dimensions: "1024x768",
            imageAnalysis: "Test Analysis"
        )

        let generator = ImageCaptionGenerator()
        let prompt = generator.makePrompt(metadata: metadata)

        #expect(prompt.contains("test.jpg"), "Prompt should include filename")
        #expect(prompt.contains("Test Title"), "Prompt should include title")
        #expect(prompt.contains("Test Description"), "Prompt should include description")
        #expect(prompt.contains("Test Alt Text"), "Prompt should include alt text")
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

        let generator = ImageCaptionGenerator()
        let prompt = generator.makePrompt(metadata: metadata)

        #expect(!prompt.contains("TITLE:"), "Prompt should not include TITLE when nil")
        #expect(!prompt.contains("CAPTION:"), "Prompt should not include CAPTION when nil")
        #expect(!prompt.contains("DESCRIPTION:"), "Prompt should not include DESCRIPTION when nil")
        #expect(!prompt.contains("ALT_TEXT:"), "Prompt should not include ALT_TEXT when nil")
        print("✓ Prompt correctly excludes nil fields")
    }

    @available(iOS 26, *)
    @Test("Prompt includes alt text but not caption")
    func promptIncludesAltTextNotCaption() async throws {
        let metadata = MediaMetadata(
            filename: "test.jpg",
            title: "Test",
            caption: "This should not appear",
            description: nil,
            altText: "This should appear",
            fileType: nil,
            dimensions: nil,
            imageAnalysis: nil
        )

        let generator = ImageCaptionGenerator()
        let prompt = generator.makePrompt(metadata: metadata)

        // Caption generator should use alt text as input but not the existing caption
        #expect(prompt.contains("This should appear"), "Prompt should include alt text")
        #expect(!prompt.contains("CAPTION:"), "Prompt should not include existing caption")
        print("✓ Prompt correctly uses alt text but excludes caption field")
    }
}
