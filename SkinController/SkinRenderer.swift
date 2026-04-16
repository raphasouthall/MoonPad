#if canImport(UIKit)
import UIKit

class SkinRenderer: UIView {

    private var skin: ManicSkin?
    private var assets: [String: UIImage] = [:]
    private var layout: SkinLayout?
    private var bridge: SkinInputBridge?

    private let backgroundImageView = UIImageView()
    private var buttonViews: [SkinButtonView] = []
    private var thumbstickViews: [SkinThumbstickView] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundImageView.contentMode = .scaleToFill
        backgroundImageView.isUserInteractionEnabled = false
        addSubview(backgroundImageView)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Touch Passthrough

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let result = super.hitTest(point, with: event)
        // Only intercept touches on button/stick subviews.
        // Background and video area touches pass through to StreamView below.
        if result === self || result === backgroundImageView {
            return nil
        }
        return result
    }

    // MARK: - Public API

    func load(skin: ManicSkin, assets: [String: UIImage], bridge: SkinInputBridge) {
        self.skin = skin
        self.assets = assets
        self.bridge = bridge

        let isLandscape = bounds.width > bounds.height
        guard let layout = SkinLoader.selectLayout(from: skin, isLandscape: isLandscape) else { return }
        self.layout = layout

        rebuildSubviews()
    }

    var videoFrame: CGRect? {
        guard let layout, let screen = layout.screens.first else { return nil }
        return scaleRect(screen.outputFrame)
    }

    func handleOrientationChange() {
        guard let skin, let bridge else { return }
        let isLandscape = bounds.width > bounds.height
        guard let newLayout = SkinLoader.selectLayout(from: skin, isLandscape: isLandscape) else { return }
        layout = newLayout
        rebuildSubviews()
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundImageView.frame = bounds

        guard let layout else { return }
        let scaleX = bounds.width / CGFloat(layout.mappingSize.width)
        let scaleY = bounds.height / CGFloat(layout.mappingSize.height)

        for view in buttonViews {
            view.frame = scaledFrame(view.item.frame, scaleX: scaleX, scaleY: scaleY)
        }
        for view in thumbstickViews {
            view.frame = scaledFrame(view.item.frame, scaleX: scaleX, scaleY: scaleY)
        }

        updateBackgroundMask()
    }

    private func updateBackgroundMask() {
        guard let vf = videoFrame else { return }
        // Cut a transparent hole in the background image so the Metal video view below shows through
        let path = UIBezierPath(rect: backgroundImageView.bounds)
        path.append(UIBezierPath(rect: vf).reversing())
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        backgroundImageView.layer.mask = mask
    }

    // MARK: - Internal

    private func rebuildSubviews() {
        // Remove old control subviews
        for v in buttonViews { v.removeFromSuperview() }
        for v in thumbstickViews { v.removeFromSuperview() }
        buttonViews.removeAll()
        thumbstickViews.removeAll()

        guard let layout, let bridge else { return }

        // Background
        backgroundImageView.image = assets[layout.assets.resizable]

        // Create subviews for each item
        for item in layout.items {
            if item.isThumbstick {
                let knobImage = item.thumbstick.flatMap { assets[$0.name] }
                let view = SkinThumbstickView(item: item, knobImage: knobImage, bridge: bridge)
                thumbstickViews.append(view)
                addSubview(view)
            } else {
                // Button or D-pad — both handled by SkinButtonView
                let image = item.asset.flatMap { assets[$0.normal] }
                let view = SkinButtonView(item: item, image: image, bridge: bridge)
                buttonViews.append(view)
                addSubview(view)
            }
        }

        setNeedsLayout()
    }

    private func scaleRect(_ rect: SkinRect) -> CGRect {
        guard let layout else { return .zero }
        let scaleX = bounds.width / CGFloat(layout.mappingSize.width)
        let scaleY = bounds.height / CGFloat(layout.mappingSize.height)
        return CGRect(
            x: CGFloat(rect.x) * scaleX,
            y: CGFloat(rect.y) * scaleY,
            width: CGFloat(rect.width) * scaleX,
            height: CGFloat(rect.height) * scaleY
        )
    }

    private func scaledFrame(_ rect: SkinRect, scaleX: CGFloat, scaleY: CGFloat) -> CGRect {
        CGRect(
            x: CGFloat(rect.x) * scaleX,
            y: CGFloat(rect.y) * scaleY,
            width: CGFloat(rect.width) * scaleX,
            height: CGFloat(rect.height) * scaleY
        )
    }
}

#endif
