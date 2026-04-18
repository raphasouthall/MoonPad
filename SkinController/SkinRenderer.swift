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
        // Button / thumbstick subviews take touches as-is.
        if result !== self && result !== backgroundImageView {
            return result
        }
        // Otherwise the touch is on skin background (or an image pixel).
        // Let it fall through ONLY if it's over a declared video screen
        // region — those are handled by per-region touch handlers behind
        // the skin (trackpad on the top screen, touchscreen on the bottom).
        // Everything else (button gutters, bezel artwork) is absorbed here
        // so it doesn't leak down to _streamView's relative-touch mode.
        if let layout {
            for screen in layout.screens {
                if scaleRect(screen.outputFrame).contains(point) {
                    return nil
                }
            }
        }
        return self
    }

    // MARK: - Public API

    func load(skin: ManicSkin, assets: [String: UIImage], bridge: SkinInputBridge) {
        self.skin = skin
        self.assets = assets
        self.bridge = bridge

        let isLandscape = bounds.width > bounds.height
        guard let layout = SkinLoader.selectLayout(from: skin, isLandscape: isLandscape) else {
            NSLog("MoonPad: SkinRenderer.load — no matching layout (device=%d, landscape=%d, reps iphone=%d ipad=%d)",
                  UIDevice.current.userInterfaceIdiom.rawValue,
                  isLandscape ? 1 : 0,
                  skin.representations.iphone != nil ? 1 : 0,
                  skin.representations.ipad != nil ? 1 : 0)
            return
        }
        self.layout = layout

        NSLog("MoonPad: SkinRenderer.load — layout selected, items=%d screens=%d mapping=%.0fx%.0f bg=%@",
              layout.items.count,
              layout.screens.count,
              layout.mappingSize.width,
              layout.mappingSize.height,
              layout.assets.backgroundAsset ?? "<none>")
        rebuildSubviews()
    }

    var videoFrame: CGRect? {
        guard let layout, let screen = layout.screens.first else { return nil }
        return scaleRect(screen.outputFrame)
    }

    /// All video screen regions, in the order declared by the skin.
    /// - `outputFrame`: position on this view in view-point coordinates.
    /// - `inputFrame`: source crop in the skin's native source-pixel coordinate system
    ///   (for 3DS Delta skins this is a 400×480-ish space). If absent we treat it as the
    ///   full source (i.e. no crop).
    @objc var videoRegions: [SkinVideoRegion] {
        guard let layout else { return [] }
        return layout.screens.map { screen in
            let output = scaleRect(screen.outputFrame)
            let input: CGRect
            if let inputRect = screen.inputFrame {
                input = inputRect.cgRect
            } else {
                // No crop: assume the source fills the skin's mapping coordinate space.
                // For single-screen skins this mirrors the old full-stream behavior.
                input = CGRect(x: 0, y: 0,
                               width: CGFloat(layout.mappingSize.width),
                               height: CGFloat(layout.mappingSize.height))
            }
            return SkinVideoRegion(inputFrame: input, outputFrame: output)
        }
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

        // Background (supports both "resizable" [Manic-Emu] and "small/medium/large" [Delta])
        if let bgName = layout.assets.backgroundAsset {
            backgroundImageView.image = assets[bgName]
        } else {
            backgroundImageView.image = nil
        }

        // Create subviews for each item
        for item in layout.items {
            if item.isThumbstick {
                let knobImage = item.thumbstick.flatMap { assets[$0.name] }
                let view = SkinThumbstickView(item: item, knobImage: knobImage, bridge: bridge)
                thumbstickViews.append(view)
                addSubview(view)
            } else if item.asset != nil {
                // Button or D-pad — both handled by SkinButtonView
                let image = item.asset.flatMap { assets[$0.normal] }
                let view = SkinButtonView(item: item, image: image, bridge: bridge)
                buttonViews.append(view)
                addSubview(view)
            }
            // Asset-less, thumbstick-less items are skipped. These are usually
            // Delta-format "touchscreen region" markers that declare a hit area
            // and map it to `touchScreenX`/`touchScreenY`. Creating a button
            // view for them would eat taps without doing anything, blocking
            // the per-region SkinRegionTouchHandler MoonPad adds behind the skin.
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
