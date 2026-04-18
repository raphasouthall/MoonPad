#if canImport(UIKit)
import UIKit

class SkinButtonView: UIView {

    let item: SkinItem
    private let imageView = UIImageView()
    private let bridge: SkinInputBridge

    // For D-pad items: tracks which directions are currently active
    private var activeDpadDirections: Set<String> = []

    init(item: SkinItem, image: UIImage?, bridge: SkinInputBridge) {
        self.item = item
        self.bridge = bridge
        super.init(frame: .zero)

        isMultipleTouchEnabled = true
        isExclusiveTouch = false

        imageView.image = image
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = false
        addSubview(imageView)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = bounds
    }

    // MARK: - Hit Testing with Extended Edges

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let ext = item.extendedEdges
        let hitRect = bounds.inset(by: UIEdgeInsets(
            top: -CGFloat(ext?.top ?? 0),
            left: -CGFloat(ext?.left ?? 0),
            bottom: -CGFloat(ext?.bottom ?? 0),
            right: -CGFloat(ext?.right ?? 0)
        ))
        return hitRect.contains(point)
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }

        if item.isDpad {
            let dirs = dpadDirections(for: touch.location(in: self))
            for dir in dirs {
                activeDpadDirections.insert(dir)
                bridge.activate(input: dir)
            }
        } else {
            for label in item.inputs.buttonLabels {
                bridge.activate(input: label)
            }
        }

        animatePress(true)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard item.isDpad, let touch = touches.first else { return }

        let newDirs = Set(dpadDirections(for: touch.location(in: self)))
        let released = activeDpadDirections.subtracting(newDirs)
        let pressed = newDirs.subtracting(activeDpadDirections)

        for dir in released { bridge.deactivate(input: dir) }
        for dir in pressed { bridge.activate(input: dir) }
        activeDpadDirections = newDirs
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        releaseAll()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        releaseAll()
    }

    private func releaseAll() {
        if item.isDpad {
            for dir in activeDpadDirections {
                bridge.deactivate(input: dir)
            }
            activeDpadDirections.removeAll()
        } else {
            for label in item.inputs.buttonLabels {
                bridge.deactivate(input: label)
            }
        }
        animatePress(false)
    }

    // MARK: - Press Feedback

    private func animatePress(_ pressed: Bool) {
        UIView.animate(withDuration: 0.05) {
            self.imageView.alpha = pressed ? 0.6 : 1.0
        }
    }

    // MARK: - D-pad Direction Detection (8-way with diagonals)

    private func dpadDirections(for point: CGPoint) -> [String] {
        let map = item.inputs.directionalMap
        let cx = bounds.midX
        let cy = bounds.midY
        let dx = point.x - cx
        let dy = point.y - cy

        // Normalise to unit square
        let nx = dx / (bounds.width * 0.5)
        let ny = dy / (bounds.height * 0.5)

        // Dead zone in the center (20% radius)
        let magnitude = sqrt(nx * nx + ny * ny)
        if magnitude < 0.2 { return [] }

        var dirs: [String] = []
        // Threshold for cardinal vs diagonal: ±0.4 of the normalised axis
        if ny < -0.4, let dir = map["up"]    { dirs.append(dir) }
        if ny >  0.4, let dir = map["down"]  { dirs.append(dir) }
        if nx < -0.4, let dir = map["left"]  { dirs.append(dir) }
        if nx >  0.4, let dir = map["right"] { dirs.append(dir) }

        return dirs
    }
}

#endif
