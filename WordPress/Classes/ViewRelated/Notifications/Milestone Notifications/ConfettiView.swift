import UIKit


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
        var lifetime: Float = 10

        /// Percent value that defines the range of sizes the particles can be
        var scaleRange: CGFloat = 0.1

        // Percent value that defines the scale of the contents of the particle
        // based on the the Particle image size
        var scale: CGFloat = 0.4
    }

    public struct Particle {
        let image: UIImage
        let tintColor: UIColor

        func tintedImage() -> UIImage {
            guard let returnImage = image.imageWithTintColor(color: tintColor) else {
                return image
            }

            return returnImage
        }
    }

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
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.fillMode = .forwards
        animation.values = [1, 0, 0]
        animation.keyTimes = [0, 0.5, 1]
        animation.isRemovedOnCompletion = false

        layer.beginTime = CACurrentMediaTime()
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
                scale = config.scale
                scaleRange = config.scaleRange

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
    }
}


extension ConfettiView {

    func emitConfetti() {
        // Images
        let star = UIImage(named: "confetti-star")!
        let circle = UIImage(named: "confetti-circle")!
        let hotdog = UIImage(named: "confetti-hotdog")!

        // Colors
        let purple = UIColor(red: 0.75, green: 0.35, blue: 0.95, alpha: 1.00)
        let orange = UIColor(red: 1.00, green: 0.50, blue: 0.52, alpha: 1.00)
        let green = UIColor(red: 0.44, green: 0.88, blue: 0.65, alpha: 1.00)

        let particles: [ConfettiView.Particle] = [
            .init(image: star, tintColor: purple),
            .init(image: circle, tintColor: orange),
            .init(image: hotdog, tintColor: green),

            .init(image: star, tintColor: orange),
            .init(image: circle, tintColor: green),
            .init(image: hotdog, tintColor: purple),

            .init(image: star, tintColor: green),
            .init(image: circle, tintColor: purple),
            .init(image: hotdog, tintColor: orange),
        ]

        self.emit(with: particles, config: ConfettiView.EmitterConfig())
    }
}

extension UIImage {
    public func imageWithTintColor(color: UIColor) -> UIImage? {
        guard let cgImg = cgImage else {
            return nil
        }

        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return nil
        }

        let bounds = CGRect(origin: CGPoint.zero, size: size)

        let flipTransform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: size.height)
        context.concatenate(flipTransform)

        context.clip(to: bounds, mask: cgImg)

        color.setFill()
        context.fill(bounds)

        let tintedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return tintedImage
    }
}
