import UIKit

struct StarFieldViewConfig {
    var particleImage: UIImage?
    var starColors: [UIColor]
}

class StarFieldView: UIView {
    struct Particle {
        let image: UIImage
        let tintColor: UIColor
    }

    let config: StarFieldViewConfig

    /// The base emitter layer that fills the background
    var emitterLayer: StarFieldEmitterLayer?

    /// A special layer that moves when the user touches
    var interactiveEmitterLayer: InteractiveStarFieldEmitterLayer?

    // MARK: - Config
    init(with config: StarFieldViewConfig) {
        self.config = config
        super.init(frame: .zero)

        configure()
    }

    required init?(coder: NSCoder) {
        self.config = StarFieldViewConfig(particleImage: nil, starColors: [])
        super.init(coder: coder)

        configure()
    }

    private func configure() {
        backgroundColor = .clear

        makeEmitterLayer()
    }

    private func makeEmitterLayer() {
        guard emitterLayer == nil, let image = config.particleImage else {
            return
        }

        let particles = config.starColors.map { Particle(image: image, tintColor: $0) }

        // Background layer
        self.emitterLayer = {
            let layer = StarFieldEmitterLayer(with: particles)
            self.layer.addSublayer(layer)
            return layer
        }()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        emitterLayer?.frame = bounds
        interactiveEmitterLayer?.frame = bounds
    }

    // MARK: - Touches
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if interactiveEmitterLayer == nil {
            interactiveEmitterLayer = {
                let particles = config.starColors.map { Particle(image: config.particleImage!, tintColor: $0) }
                let layer = InteractiveStarFieldEmitterLayer(with: particles)
                self.layer.addSublayer(layer)

                return layer
            }()
        }

        touchesMoved(touches, with: event)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let firstTouch = touches.first else {
            return
        }

        let location = firstTouch.location(in: self)
        let radius = firstTouch.majorRadius

        interactiveEmitterLayer?.touchesMoved(to: location, with: radius)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        interactiveEmitterLayer?.touchesEnded()

    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }
}

class StarFieldEmitterLayer: CAEmitterLayer {
    init(with particles: [StarFieldView.Particle]) {
        super.init()

        needsDisplayOnBoundsChange = true
        emitterCells = particles.map { ParticleCell(with: $0) }
    }

    override func layoutSublayers() {
        super.layoutSublayers()

        emitterMode = .outline
        emitterShape = .sphere
        emitterSize = bounds.insetBy(dx: -50, dy: -50).size
        emitterPosition = CGPoint(x: bounds.midX, y: bounds.maxY)
        speed = 0.5
    }

    override init(layer: Any) {
        super.init(layer: layer)
    }

    private class ParticleCell: CAEmitterCell {
        init(with particle: StarFieldView.Particle) {
            super.init()

            let randomAlpha = CGFloat.random(in: 0.3...0.5)
            color = particle.tintColor.withAlphaComponent(randomAlpha).cgColor
            contents = particle.image.cgImage

            birthRate = 5
            lifetime = Float.infinity
            lifetimeRange = 0
            velocity = 5
            velocityRange = velocity * 0.5
            yAcceleration = -0.01

            scale = WPDeviceIdentification.isiPad() ? 0.07 : 0.04
            scaleRange = 0.05
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class InteractiveStarFieldEmitterLayer: StarFieldEmitterLayer {
    override init(with particles: [StarFieldView.Particle]) {
        super.init(with: particles)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(layer: Any) {
        super.init(layer: layer)
    }

    override func layoutSublayers() {
        super.layoutSublayers()

        emitterShape = .circle
        emitterSize = .zero
        beginTime = CACurrentMediaTime()
    }

    /// Moves the emitter point to the touch location
    /// - Parameters:
    ///   - location: The location to move the emitter point to
    ///   - radius: The size of the emitter
    public func touchesMoved(to location: CGPoint, with radius: CGFloat = 10) {
        lifetime = 1
        birthRate = 1
        speed = 10

        emitterPosition = location
        emitterSize = CGSize(width: radius, height: radius)
    }

    public func touchesBegan() {
        beginTime = CACurrentMediaTime()
    }

    public func touchesEnded() {
        lifetime = 0
        emitterSize = .zero
    }
}
