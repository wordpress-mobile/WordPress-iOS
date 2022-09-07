import Combine
import Foundation
import SwiftUI

class JetpackPromptsViewModel: ObservableObject {

    // duration of the animation that shifts the views
    private static let animationDuration: CGFloat = 1

    @Published var rotation: CGFloat = 0

    private var timer: Timer?

    var configuration: JetpackPromptsConfiguration? {
        didSet {
            guard configuration != nil else {
                return
            }
            startAnimation()
        }
    }

    init(configuration: JetpackPromptsConfiguration? = nil) {
        self.configuration = configuration
    }

    func startAnimation() {

        guard let configuration = configuration else {
            return
        }
        // reset any existing timers
        timer?.invalidate()
        timer = nil
        rotation = 0

        timer = Timer.scheduledTimer(withTimeInterval: Self.animationDuration, repeats: true) { [weak self] _ in

            guard let self = self else {
                return
            }

            if self.rotation == configuration.totalHeight {
                self.rotation = 0
            }

            withAnimation(.linear(duration: Self.animationDuration)) {
                self.rotation += configuration.frameHeight * Self.animationDuration
                // multiplying by animationDuration will keep the movement at the speed of 1 row per second.
                // Can be tweaked if needed (e.g. if we want to use the accelerometer)
            }
        }
    }

    var prompts: [JetpackPrompt] {
        configuration?.prompts ?? []
    }

    var fontSize: CGFloat {
        configuration?.fontSize ?? 0
    }

    func offset(for prompt: JetpackPrompt) -> CGFloat {
        guard let configuration = configuration else {
            return 0
        }

        var offset = prompt.initialOffset + rotation

        if offset > configuration.maximumOffset {
            offset -= configuration.totalHeight
        }

        return offset
    }

    func opacity(for prompt: JetpackPrompt) -> Double {
        guard let configuration = configuration else {
            return 0
        }

        let offset = offset(for: prompt)
        return offset >= -configuration.frameHeight && offset <= configuration.size.height ? 1 : 0
    }
}
