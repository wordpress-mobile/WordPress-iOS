import UIKit
import SpriteKit

/// A table view cell that contains a SpriteKit game scene which shows logos
/// of the various apps from Automattic.
///
class AutomatticAppLogosCell: UITableViewCell {
    private var logosScene: AppLogosScene!
    private var spriteKitView: SKView!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.commonInit()
    }

    func commonInit() {
        spriteKitView = SKView(frame: Metrics.sceneFrame)
        logosScene = AppLogosScene()

        // Scene is resized to match the view
        logosScene.scaleMode = .resizeFill
        spriteKitView.presentScene(logosScene)

        contentView.addSubview(spriteKitView)
        spriteKitView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(lessThanOrEqualTo: spriteKitView.leadingAnchor),
            contentView.trailingAnchor.constraint(greaterThanOrEqualTo: spriteKitView.trailingAnchor),
            contentView.topAnchor.constraint(equalTo: spriteKitView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: spriteKitView.bottomAnchor),
            spriteKitView.widthAnchor.constraint(lessThanOrEqualToConstant: Metrics.maxWidth),
            spriteKitView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
        ])
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        logosScene.updateForTraitCollection(traitCollection)
    }

    enum Metrics {
        static let sceneFrame = CGRect(x:0 , y:0, width: 350.0, height: 150.0)
        static let maxWidth: CGFloat = 388.0 // Standard cell width on Max phone
    }
}


/// Displays the logos of the various Automattic apps in balls that collide
/// with one another.
///
private class AppLogosScene: SKScene {

    private struct App {
        let color: String
        let image: String
    }

    private let apps: [App] = [
        App(color: "#7d57a4", image: "woo"),
        App(color: "#001935", image: "tumblr"),
        App(color: "#3361cc", image: "simplenote"),
        App(color: "#f43e37", image: "pocketcasts"),
        App(color: "#44c0ff", image: "dayone"),
        App(color: "#00be28", image: "jetpack"),
        App(color: "#0675c4", image: "wp")
    ]

    // Collision categories
    private let ballCategory: UInt32 = 0b0010
    private let edgeCategory: UInt32 = 0b0001

    // Stores a reference to each of the balls in the scene
    private var balls: [SKNode] = []

    private var traitCollection: UITraitCollection?


    // MARK: - Scene lifecycle

    override func didMove(to view: SKView) {
        super.didMove(to: view)

        generateScene()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)

        if oldSize != size {
            generateScene()
        }
    }

    func updateForTraitCollection(_ traitCollection: UITraitCollection) {
        self.traitCollection = traitCollection

        // We need to manually update the scene for dark mode / light mode.
        // We'll also regenerate the balls to ensure they use the correct image.
        backgroundColor = .secondarySystemGroupedBackground.resolvedColor(with: traitCollection)
        generateBalls()
    }

    // MARK: - Scene creation

    private func generateScene() {
        backgroundColor = .secondarySystemGroupedBackground

        let edge = SKPhysicsBody(edgeLoopFrom: frame)
        edge.categoryBitMask = edgeCategory
        edge.collisionBitMask = ballCategory
        physicsBody = edge

        generateBalls()
    }

    private func generateBalls() {
        // Remove any existing balls
        balls.forEach({ $0.removeFromParent() })
        balls.removeAll()

        guard let bounds = view?.bounds,
              bounds.size != .zero else {
            return
        }

        balls = apps.compactMap({ makeBall(for: $0) })
        balls.forEach({ addChild($0) })
    }

    private func makeBall(for app: App) -> SKNode? {
        guard let view = view,
              let image = UIImage(named: Constants.appLogoPrefix + app.image, in: .main, compatibleWith: traitCollection) else {
            return nil
        }

        // Container for the various parts of the ball
        let ball = SKShapeNode(circleOfRadius: Metrics.ballRadius)
        ball.fillColor = .secondarySystemGroupedBackground
        ball.strokeColor = .secondarySystemGroupedBackground

        // For the background, we first draw a shape node at full opacity...
        let background = SKShapeNode(circleOfRadius: Metrics.ballRadius)
        background.strokeColor = UIColor(hex: app.color)
        background.fillColor = UIColor(hex: app.color)

        // ... Then turn that into a sprite with the correct alpha.
        // We can't just apply an alpha to the background shape node, as the
        // fill covers the stroke and their values are added together resulting
        // in a darker stroke. We also can't just set a clear stroke,
        // otherwise the fill won't be antialiased.
        let backgroundSprite = SKSpriteNode(texture: view.texture(from: background))
        backgroundSprite.alpha = Metrics.backgroundAlpha
        ball.addChild(backgroundSprite)

        // Add the logo, taking into account the current trait collection for dark mode
        let logo = SKSpriteNode(texture: SKTexture(image: image))
        logo.size = CGSize(width: Metrics.ballWidth, height: Metrics.ballWidth)
        ball.addChild(logo)

        let physicsBody = SKPhysicsBody(circleOfRadius: Metrics.ballRadius)
        physicsBody.categoryBitMask = ballCategory
        physicsBody.collisionBitMask = ballCategory | edgeCategory
        physicsBody.affectedByGravity = true
        physicsBody.restitution = Constants.physicsRestitution
        ball.physicsBody = physicsBody

        // Ensure we only spawn balls in an area in the center that's inset
        // from either side by the radius of a ball plus some padding
        let spawnArea = bounds.insetBy(dx: Metrics.edgePadding + Metrics.ballRadius,
                                       dy: Metrics.edgePadding + Metrics.ballRadius)

        ball.position = CGPoint(x: spawnArea.minX + CGFloat(arc4random_uniform(UInt32(spawnArea.width))),
                                y: spawnArea.minY + CGFloat(arc4random_uniform(UInt32(spawnArea.height))))
        return ball
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.randomElement() else {
            return
        }

        let location = touch.location(in: self)
        let touchedNodes = nodes(at: location)

        for node in touchedNodes {
            if node is SKShapeNode {
                let actions = SKAction.sequence([
                    SKAction.scale(to: Metrics.tapScaleUpValue, duration: Metrics.tapScaleUpDuration),
                    SKAction.scale(to: Metrics.tapDefaultScaleValue, duration: Metrics.tapDefaultScaleDuration)
                ])

                node.run(actions)
            }
        }
    }

    private var bounds: CGRect {
        view?.bounds ?? .zero
    }

    enum Metrics {
        static let ballRadius: CGFloat = 36.0
        static let logoSize: CGFloat = 40.0
        static let backgroundAlpha: CGFloat = 0.16
        static let edgePadding: CGFloat = 4.0 // So we don't spawn balls too close to the edges

        static let tapScaleUpValue: CGFloat = 1.4
        static let tapScaleUpDuration: TimeInterval = 0.05
        static let tapDefaultScaleValue: CGFloat = 1.0
        static let tapDefaultScaleDuration: TimeInterval = 0.1

        static var ballWidth: CGFloat {
            ballRadius * 2.0
        }
    }

    enum Constants {
        static let appLogoPrefix = "ua-logo-"
        static let physicsRestitution: CGFloat = 0.5
    }
}
