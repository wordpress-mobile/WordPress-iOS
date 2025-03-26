import SwiftUI
import AVFoundation
import WordPressUI

struct AudioRecorderVisualizerView: View {
    let recorder: AVAudioRecorder
    @StateObject private var viewModel = AudioRecorderVisualizerViewModel()

    var body: some View {
        AudiowaveView(samples: viewModel.samples)
            .onAppear {
                viewModel.recorder = recorder
            }
    }
}

private struct AudiowaveView: View {
    let samples: [Float]

    var body: some View {
        let indices = Array<Int>(samples.indices)
        HStack(spacing: 6) {
            ForEach(indices, id: \.self) { index in
                let height = max(10, 80 * normalizePowerLevel(samples[index]))
                Capsule(style: .continuous)
                    .fill(Color(uiColor: UIAppColor.primary))
                    .frame(width: 10, height: CGFloat(height))
                    .animation(.spring(duration: 0.1), value: height)
            }
        }
    }

    private func normalizePowerLevel(_ power: Float) -> Float {
        // About the expected range for voice
        let minPower: Float = -41
        let maxPower: Float = -22
        let value = (power + abs(minPower)) / abs(maxPower - minPower)
        return min(1, max(0, value))
    }
}

private final class AudioRecorderVisualizerViewModel: ObservableObject {
    @Published private(set) var samples = Array<Float>(repeating: -160, count: numberOfSamples)
    private(set) var currentSample = 0

    var recorder: AVAudioRecorder?

    private weak var timer: Timer?

    deinit {
        timer?.invalidate()
    }

    init() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.04, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    private func refresh() {
        guard let recorder else { return }
        recorder.updateMeters()
        samples.removeFirst()
        samples.append(recorder.averagePower(forChannel: 0))
    }
}

private let numberOfSamples = 20

#Preview {
    AudiowaveView(samples: [-37, -35, 10, 20, 30])
}
