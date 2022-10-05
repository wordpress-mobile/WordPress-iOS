import Combine
import Foundation
import SwiftUI

class JetpackPromptsViewModel: ObservableObject {

    @Published var rotation: CGFloat = 0

    private var displayLink: CADisplayLink?

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
        displayLink = CADisplayLink(target: self, selector: #selector(step))
    }

    @objc
    func step() {
        guard let configuration = configuration else {
            return
        }

        if self.rotation == configuration.totalHeight {
            self.rotation = 0
        }

        // Can be tweaked if needed (e.g. if we want to use the accelerometer)
        self.rotation += 1
    }

    func startAnimation() {
        displayLink?.add(to: .current, forMode: .default)
        rotation = 0
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
