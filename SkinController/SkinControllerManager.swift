#if canImport(UIKit) && canImport(ZIPFoundation)
import UIKit
import ZIPFoundation

@objc class SkinControllerManager: NSObject {

    @objc let view: SkinRenderer
    private let bridge: SkinInputBridge
    private var skin: ManicSkin

    @objc init?(skinFilename: String) {
        guard let url = Self.findSkin(named: skinFilename) else {
            NSLog("MoonPad: Skin file not found in bundle or Documents/Skins: %@", skinFilename)
            return nil
        }
        let loaded: LoadedSkin
        do {
            loaded = try SkinLoader.load(from: url)
        } catch {
            NSLog("MoonPad: Skin load failed (%@): %@", skinFilename, String(describing: error))
            return nil
        }

        self.skin = loaded.skin
        self.bridge = SkinInputBridge()
        self.view = SkinRenderer(frame: .zero)
        super.init()

        NSLog("MoonPad: Skin loaded: %@ name=%@ id=%@ assetCount=%d",
              skinFilename, loaded.skin.name, loaded.skin.identifier, loaded.assets.count)
        view.load(skin: loaded.skin, assets: loaded.assets, bridge: bridge)
    }

    @objc var videoFrame: CGRect {
        return view.videoFrame ?? .zero
    }

    /// All video screen regions defined by the skin (e.g. 1 for PS1, 2 for 3DS).
    @objc var videoRegions: [SkinVideoRegion] {
        return view.videoRegions
    }

    @objc func handleOrientationChange() {
        view.handleOrientationChange()
    }

    // MARK: - Skin File Discovery

    private static func findSkin(named filename: String) -> URL? {
        // Check Resources/Skins in the app bundle
        if let bundlePath = Bundle.main.path(forResource: filename, ofType: nil, inDirectory: "Skins") {
            return URL(fileURLWithPath: bundlePath)
        }
        // Check bundle root
        if let bundlePath = Bundle.main.path(forResource: filename, ofType: nil) {
            return URL(fileURLWithPath: bundlePath)
        }
        // Check Documents/Skins for user-imported skins
        if let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let userSkin = docs.appendingPathComponent("Skins").appendingPathComponent(filename)
            if FileManager.default.fileExists(atPath: userSkin.path) {
                return userSkin
            }
        }
        return nil
    }
}

#endif
