import UIKit
import WordPressUI

class ConfettiView: UIView {
    public struct EmitterConfig {

        /// How long the emitter run before fading out
        /// higher number means more particles for longer
        var duration: TimeInterval = 2.0

        /// The number of particles created every second
        /// higher number = lots more particles moving faster
        var birthRate: Float = 40

        /// A range of when particles are created
        /// honestly not really sure, 10 seems to be good though heh.
        var lifetime: Float = 15

        /// Percent value that defines the range of sizes the particles can be
        var scaleRange: CGFloat = 0.1

        /// Percent value that defines the scale of the contents of the particle
        /// based on the the Particle image size
        var scale: CGFloat = 0.4
    }

    public struct Particle {
        let image: UIImage
        let tintColor: UIColor

        func tintedImage() -> UIImage {
            guard let returnImage = image.imageWithTintColor(tintColor) else {
                return image
            }

            return returnImage
        }
    }

    typealias AnimationCompletion = (ConfettiView) -> Void
    public var onAnimationCompletion: AnimationCompletion?

    // MARK: - Config
    override init(frame: CGRect) {
        super.init(frame: .zero)

        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        configure()
    }

    private func configure() {
        isUserInteractionEnabled = false
        backgroundColor = .clear
    }

    // MARK: - Public: Animations
    public func emit(with particles: [Particle], config: EmitterConfig) {
        let emitterLayer = ParticleEmitterLayer(with: particles, config: config)
        emitterLayer.frame = bounds

        layer.addSublayer(emitterLayer)

        fadeOut(layer: emitterLayer, after: config.duration)
    }

    private func fadeOut(layer: ParticleEmitterLayer, after duration: TimeInterval) {
        let animation = CAKeyframeAnimation(keyPath: #keyPath(CAEmitterLayer.birthRate))
        animation.duration = duration
        animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        animation.fillMode = .forwards
        animation.values = [1, 0, 0]
        animation.keyTimes = [0, 0.5, 1]
        animation.isRemovedOnCompletion = false

        layer.birthRate = 1.0

        CATransaction.begin()
        CATransaction.setCompletionBlock {
            let transition = CATransition()
            transition.delegate = self
            transition.type = .fade
            transition.duration = duration * 0.5
            transition.timingFunction = CAMediaTimingFunction(name: .easeOut)
            transition.setValue(layer, forKey: Constants.animationLayerKey)
            transition.isRemovedOnCompletion = false

            layer.add(transition, forKey: nil)
            layer.opacity = 0
        }

        layer.add(animation, forKey: nil)
        CATransaction.commit()
    }

    // MARK: - Private: ParticleEmitterLayer
    private class ParticleEmitterLayer: CAEmitterLayer {
        init(with particles: [Particle], config: EmitterConfig) {
            super.init()

            needsDisplayOnBoundsChange = true
            emitterCells = particles.map { ParticleCell(with: $0, config: config) }
        }

        override func layoutSublayers() {
            super.layoutSublayers()

            emitterMode = .outline
            emitterShape = .line
            emitterSize = CGSize(width: bounds.width, height: 1.0)
            emitterPosition = CGPoint(x: bounds.midX, y: 0)
        }

        override init(layer: Any) {
            super.init(layer: layer)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private class ParticleCell: CAEmitterCell {
            init(with particle: Particle, config: EmitterConfig) {
                super.init()

                contents = particle.tintedImage().cgImage
                birthRate = config.birthRate
                lifetime = config.lifetime
                lifetimeRange = 7
                scale = config.scale
                scaleRange = config.scaleRange
                beginTime = CACurrentMediaTime()
                velocity = CGFloat(birthRate * lifetime)
                velocityRange = velocity * 0.5
                emissionLongitude = .pi
                emissionRange = .pi / 4
                spinRange = .pi * 8
            }

            required init?(coder: NSCoder) {
                fatalError("init(coder:) has not been implemented")
            }
        }
    }

    private struct Constants {
        static let animationLayerKey = "org.wordpress.confetti"
    }
}

// MARK: - Animation Delegate
extension ConfettiView: CAAnimationDelegate {
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        guard let layer = anim.value(forKey: Constants.animationLayerKey) as? ParticleEmitterLayer else {
            return
        }

        layer.removeAllAnimations()
        layer.removeFromSuperlayer()

        onAnimationCompletion?(self)
    }
}


extension ConfettiView {

    func emitConfetti() {
        // Images
        guard let star = UIImage(named: "confetti-star"),
              let circle = UIImage(named: "confetti-circle"),
              let hotdog = UIImage(named: "confetti-hotdog") else {
            return
        }

        // Colors
        let purple = UIColor(light: .muriel(name: .purple, .shade20), dark: .muriel(name: .purple, .shade40))

        let orange = UIColor(light: .muriel(name: .orange, .shade10), dark: .muriel(name: .orange, .shade30))

        let green = UIColor(light: .muriel(name: .green, .shade10), dark: .muriel(name: .green, .shade30))

        let celadon = UIColor(light: .muriel(name: .celadon, .shade10), dark: .muriel(name: .celadon, .shade20))

        let pink = UIColor(light: .muriel(name: .pink, .shade20), dark: .muriel(name: .pink, .shade40))

        let red = UIColor(light: .muriel(name: .red, .shade10), dark: .muriel(name: .red, .shade30))

        let blue = UIColor(light: .muriel(name: .blue, .shade30), dark: .muriel(name: .blue, .shade50))

        let yellow = UIColor(light: .muriel(name: .yellow, .shade10), dark: .muriel(name: .yellow, .shade30))


        let starParticles = [purple, orange, green, blue].map { Particle(image: star, tintColor: $0) }
        let circleParticles = [celadon, pink, red, yellow].map { Particle(image: circle, tintColor: $0) }
        let hotdogParticles = [orange, pink, blue, red].map { Particle(image: hotdog, tintColor: $0) }

        let particles = starParticles + circleParticles + hotdogParticles

        self.emit(with: particles, config: ConfettiView.EmitterConfig())
    }
}

// MARK: - Convenience methods to add/remove ConfettiView from any view
extension ConfettiView {

    /// Adds an instance of ConfettiView to the specified view
    /// - Parameters:
    ///   - view: the view where to add the ConfettiView
    ///   - frame: optional frame for ConfettiView
    ///   - onAnimationCompletion: optional closure to be executed when the animation ends
    /// - Returns: the newly created instance of ConfettiView
    static func add(on view: UIView,
                    frame: CGRect? = nil,
                    onAnimationCompletion: AnimationCompletion? = nil) -> ConfettiView {

        let confettiView = ConfettiView()

        if let frame = frame {
            confettiView.frame = frame
        }

        confettiView.onAnimationCompletion = onAnimationCompletion

        view.addSubview(confettiView)

        return confettiView
    }

    /// Remove any existing instance of ConfettiView from the specified view
    /// - Parameter view: the view to remove ConfettiView instances from
    static func removeAll(from view: UIView) {

        let existingConfettiViews = view.subviews.filter { $0.isKind(of: ConfettiView.self) }

        existingConfettiViews.forEach {
            $0.removeFromSuperview()
        }
    }

    /// combines the two previous methods, removing any existing ConfettiView instance before adding a new one and firing the animation
    static func cleanupAndAnimate(on view: UIView,
                                  frame: CGRect? = nil,
                                  onAnimationCompletion: AnimationCompletion? = nil) {

        removeAll(from: view)

        add(on: view,
            frame: frame,
            onAnimationCompletion: onAnimationCompletion)
            .emitConfetti()
    }
}
