import SwiftUI
import PhotosUI
import WordPressIntelligence

@available(iOS 26, *)
struct ImageAltGeneratorTestView: View {
    @StateObject private var viewModel = ImageAltGeneratorTestViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Image Picker
                PhotosPicker(selection: $viewModel.selectedItem,
                           matching: .images) {
                    Label("Pick Image", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)

                // Selected Image
                if let image = viewModel.selectedImage {
                    VStack(spacing: 12) {
                        Text("Selected Image")
                            .font(.headline)

                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 300)
                            .cornerRadius(8)
                            .padding(.horizontal)
                    }
                }

                // Analysis Status
                if viewModel.isAnalyzing {
                    VStack(spacing: 8) {
                        ProgressView()
                        Text("Analyzing image...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                }

                // Analysis Result
                if let analysisResult = viewModel.analysisResult {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Image Analysis")
                                .font(.headline)
                            Spacer()
                            if let elapsed = viewModel.analysisTimeElapsed {
                                Text(String(format: "%.0f ms", elapsed))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Text(analysisResult)
                            .font(.body)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                }

                // Generation Status
                if viewModel.isGenerating {
                    VStack(spacing: 8) {
                        ProgressView()
                        Text("Generating alt text...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                }

                // Generated Alt Text
                if let altText = viewModel.generatedAltText {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Generated Alt Text")
                                .font(.headline)
                            Spacer()
                            if let elapsed = viewModel.generationTimeElapsed {
                                Text(String(format: "%.0f ms", elapsed))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Text(altText)
                            .font(.body)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGreen).opacity(0.1))
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                }

                // Error Display
                if let error = viewModel.errorMessage {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Error")
                            .font(.headline)
                            .foregroundStyle(.red)

                        Text(error)
                            .font(.body)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemRed).opacity(0.1))
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Image Alt Generator")
        .navigationBarTitleDisplayMode(.inline)
    }
}

@MainActor
@available(iOS 26, *)
final class ImageAltGeneratorTestViewModel: ObservableObject {
    @Published var selectedItem: PhotosPickerItem?
    @Published var selectedImage: UIImage?
    @Published var analysisResult: String?
    @Published var generatedAltText: String?
    @Published var isAnalyzing = false
    @Published var isGenerating = false
    @Published var errorMessage: String?
    @Published var analysisTimeElapsed: Double?
    @Published var generationTimeElapsed: Double?

    private var currentCGImage: CGImage?

    init() {
        // Observe selectedItem changes
        Task { @MainActor in
            for await item in $selectedItem.values {
                await loadImage(from: item)
            }
        }
    }

    private func loadImage(from item: PhotosPickerItem?) async {
        guard let item else {
            selectedImage = nil
            currentCGImage = nil
            analysisResult = nil
            generatedAltText = nil
            errorMessage = nil
            analysisTimeElapsed = nil
            generationTimeElapsed = nil
            return
        }

        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                print("❌ Failed to load image data")
                errorMessage = "Failed to load image data"
                return
            }

            selectedImage = image
            currentCGImage = image.cgImage
            analysisResult = nil
            generatedAltText = nil
            errorMessage = nil
            analysisTimeElapsed = nil
            generationTimeElapsed = nil

            print("✅ Image loaded successfully")

            // Automatically start analysis
            await analyzeImage()
        } catch {
            print("❌ Error loading image: \(error)")
            errorMessage = "Error loading image: \(error.localizedDescription)"
        }
    }

    func analyzeImage() async {
        guard let cgImage = currentCGImage else {
            errorMessage = "No image to analyze"
            return
        }

        isAnalyzing = true
        errorMessage = nil
        analysisTimeElapsed = nil

        let startTime = CFAbsoluteTimeGetCurrent()

        do {
            print("\n🔍 Starting image analysis...")
            let result = try await IntelligenceService.analyzeImage(cgImage)

            let elapsed = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
            analysisTimeElapsed = elapsed

            print("✅ Analysis complete (\(String(format: "%.0f", elapsed)) ms):")
            print(result)
            print("")

            analysisResult = result
            generatedAltText = nil

            // Automatically start generation
            await generateAltText()
        } catch {
            print("❌ Analysis error: \(error)")
            errorMessage = "Analysis failed: \(error.localizedDescription)"
        }

        isAnalyzing = false
    }

    func generateAltText() async {
        guard currentCGImage != nil else {
            errorMessage = "No image available"
            return
        }

        guard let analysis = analysisResult else {
            errorMessage = "Please analyze the image first"
            return
        }

        isGenerating = true
        errorMessage = nil
        generationTimeElapsed = nil

        let startTime = CFAbsoluteTimeGetCurrent()

        do {
            print("\n✨ Generating alt text...")

            let metadata = MediaMetadata(
                filename: "test-image.jpg",
                imageAnalysis: analysis
            )

            let generator = ImageAltTextGenerator()
            let altText = try await generator.generate(metadata: metadata)

            let elapsed = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
            generationTimeElapsed = elapsed

            print("✅ Alt text generated (\(String(format: "%.0f", elapsed)) ms):")
            print(altText)
            print("")

            generatedAltText = altText
        } catch {
            print("❌ Generation error: \(error)")
            errorMessage = "Generation failed: \(error.localizedDescription)"
        }

        isGenerating = false
    }
}

@available(iOS 26, *)
#Preview {
    NavigationStack {
        ImageAltGeneratorTestView()
    }
}
