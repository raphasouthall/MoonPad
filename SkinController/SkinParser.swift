import Foundation

// MARK: - Skin Data Model

struct ManicSkin: Codable {
    let name: String
    let identifier: String
    let gameTypeIdentifier: String?
    let debug: Bool?
    let representations: SkinRepresentations
}

struct SkinRepresentations: Codable {
    let iphone: SkinDeviceLayouts?
    let ipad: SkinDeviceLayouts?
}

struct SkinDeviceLayouts: Codable {
    let standard: SkinOrientationLayouts?
    let edgeToEdge: SkinOrientationLayouts?
}

struct SkinOrientationLayouts: Codable {
    let portrait: SkinLayout?
    let landscape: SkinLayout?
}

struct SkinLayout: Codable {
    let assets: SkinAssets
    let mappingSize: SkinSize
    let screens: [SkinScreen]
    let translucent: Bool
    let items: [SkinItem]
}

// Manic-Emu skins use `resizable`; Delta-format skins use `small`/`medium`/`large`.
// Accept both and expose a single best-available filename via `backgroundAsset`.
struct SkinAssets: Codable {
    let resizable: String?
    let small: String?
    let medium: String?
    let large: String?

    var backgroundAsset: String? {
        return resizable ?? large ?? medium ?? small
    }
}

// Delta-format skins include `inputFrame` (source rect within the stream) alongside
// `outputFrame` (screen rect on device). MoonPad's own .manicskins only specify
// `outputFrame` and take the full stream. Keep `inputFrame` optional.
struct SkinScreen: Codable {
    let outputFrame: SkinRect
    let inputFrame: SkinRect?
}

// MARK: - Runtime Video Region (ObjC-bridgeable)

#if canImport(UIKit)
import UIKit

@objc public class SkinVideoRegion: NSObject {
    /// Source crop in the skin's native source-pixel space (e.g. 400×480 for 3DS Delta skins).
    @objc public let inputFrame: CGRect
    /// Position on the skin view, in view points.
    @objc public let outputFrame: CGRect

    @objc public init(inputFrame: CGRect, outputFrame: CGRect) {
        self.inputFrame = inputFrame
        self.outputFrame = outputFrame
    }
}
#endif

// MARK: - Geometry Types (platform-independent Codable)

struct SkinRect: Codable {
    let x: Double
    let y: Double
    let width: Double
    let height: Double

    #if canImport(CoreGraphics)
    var cgRect: CGRect {
        CGRect(x: x, y: y, width: width, height: height)
    }
    #endif
}

struct SkinSize: Codable {
    let width: Double
    let height: Double

    #if canImport(CoreGraphics)
    var cgSize: CGSize {
        CGSize(width: width, height: height)
    }
    #endif
}

struct SkinEdgeInsets: Codable {
    let top: Double
    let bottom: Double
    let left: Double
    let right: Double

    #if canImport(UIKit)
    var uiEdgeInsets: UIEdgeInsets {
        UIEdgeInsets(top: top, left: left, bottom: bottom, right: right)
    }
    #endif
}

// MARK: - Skin Items

struct SkinItemAsset: Codable {
    let normal: String
}

struct SkinThumbstickAsset: Codable {
    let name: String
    let width: Double
    let height: Double
}

struct SkinItem: Codable {
    let asset: SkinItemAsset?
    let thumbstick: SkinThumbstickAsset?
    let frame: SkinRect
    // Delta-format skins sometimes omit `extendedEdges` (thumbsticks, some
    // landscape items). Treat absence as zero insets.
    let extendedEdges: SkinEdgeInsets?
    let inputs: SkinInputs

    var isThumbstick: Bool { thumbstick != nil }
    var isDpad: Bool { asset != nil && inputs.isDirectional }
    var isButton: Bool { asset != nil && !inputs.isDirectional }
}

enum SkinInputs: Codable {
    case button([String])
    case directional([String: String])

    var isDirectional: Bool {
        if case .directional = self { return true }
        return false
    }

    var buttonLabels: [String] {
        if case .button(let labels) = self { return labels }
        return []
    }

    var directionalMap: [String: String] {
        if case .directional(let map) = self { return map }
        return [:]
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let array = try? container.decode([String].self) {
            self = .button(array)
        } else if let dict = try? container.decode([String: String].self) {
            self = .directional(dict)
        } else {
            throw DecodingError.typeMismatch(
                SkinInputs.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Expected [String] or [String: String] for inputs"
                )
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .button(let array):
            try container.encode(array)
        case .directional(let dict):
            try container.encode(dict)
        }
    }
}

// MARK: - Layout Selection (UIKit only, no ZIPFoundation needed)

#if canImport(UIKit)
import UIKit

enum SkinLoadError: Error {
    case zipExtractionFailed
    case infoJsonMissing
    case infoJsonInvalid
    case layoutNotFound
}

class SkinLoader {

    static func selectLayout(from skin: ManicSkin, isLandscape: Bool = false) -> SkinLayout? {
        // Prefer a device-matched representation, but fall back the other way if
        // the skin is single-target (e.g. Delta skins often ship iphone-only).
        let primary: SkinDeviceLayouts?
        let fallback: SkinDeviceLayouts?
        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        if isPad {
            primary = skin.representations.ipad
            fallback = skin.representations.iphone
        } else {
            primary = skin.representations.iphone
            fallback = skin.representations.ipad
        }

        let hasNotch: Bool = {
            if #available(iOS 13.0, *) {
                guard let window = UIApplication.shared.connectedScenes
                    .compactMap({ $0 as? UIWindowScene })
                    .first?.windows.first else { return false }
                return window.safeAreaInsets.top > 20
            }
            return false
        }()
        let preferEdgeToEdge = hasNotch && !isPad

        // Walk both device reps until one yields an orientation bucket.
        let orientationLayouts: SkinOrientationLayouts? = {
            for reps in [primary, fallback] {
                guard let reps else { continue }
                if let layout = (preferEdgeToEdge ? reps.edgeToEdge : reps.standard)
                    ?? reps.standard
                    ?? reps.edgeToEdge { return layout }
            }
            return nil
        }()

        if isLandscape {
            return orientationLayouts?.landscape ?? orientationLayouts?.portrait
        }
        return orientationLayouts?.portrait ?? orientationLayouts?.landscape
    }
}

#endif

// MARK: - ZIP Loading + PDF Rendering (requires ZIPFoundation)

#if canImport(UIKit) && canImport(ZIPFoundation)
import ZIPFoundation

struct LoadedSkin {
    let skin: ManicSkin
    let assets: [String: UIImage]
}

extension SkinLoader {

    static func load(from url: URL) throws -> LoadedSkin {
        guard let archive = Archive(url: url, accessMode: .read) else {
            throw SkinLoadError.zipExtractionFailed
        }

        // Parse info.json
        guard let infoEntry = archive["info.json"] else {
            throw SkinLoadError.infoJsonMissing
        }
        var infoData = Data()
        _ = try archive.extract(infoEntry) { chunk in
            infoData.append(chunk)
        }
        let skin = try JSONDecoder().decode(ManicSkin.self, from: infoData)

        // Load PDF assets (rasterize to UIImage) and PNG assets (direct decode).
        // Delta-format skins use PNG backgrounds; Manic-Emu skins use PDFs.
        var assets: [String: UIImage] = [:]
        for entry in archive where !entry.path.contains("__MACOSX") {
            let pathLower = entry.path.lowercased()
            let isPDF = pathLower.hasSuffix(".pdf")
            let isPNG = pathLower.hasSuffix(".png")
            let isJPG = pathLower.hasSuffix(".jpg") || pathLower.hasSuffix(".jpeg")
            guard isPDF || isPNG || isJPG else { continue }

            var assetData = Data()
            _ = try archive.extract(entry) { chunk in
                assetData.append(chunk)
            }
            let filename = (entry.path as NSString).lastPathComponent
            if isPDF {
                if let image = renderPDF(data: assetData) { assets[filename] = image }
            } else {
                if let image = UIImage(data: assetData) { assets[filename] = image }
            }
        }

        return LoadedSkin(skin: skin, assets: assets)
    }

    // MARK: - PDF Rendering

    static func renderPDF(data: Data, scale: CGFloat = 0) -> UIImage? {
        let renderScale = scale > 0 ? scale : UIScreen.main.scale
        guard let provider = CGDataProvider(data: data as CFData),
              let document = CGPDFDocument(provider),
              let page = document.page(at: 1) else { return nil }

        let mediaBox = page.getBoxRect(.mediaBox)
        let width = mediaBox.width * renderScale
        let height = mediaBox.height * renderScale

        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), false, 1.0)
        defer { UIGraphicsEndImageContext() }
        guard let context = UIGraphicsGetCurrentContext() else { return nil }

        context.setFillColor(UIColor.clear.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))

        // Flip coordinate system for PDF (bottom-left origin → top-left)
        context.translateBy(x: 0, y: height)
        context.scaleBy(x: renderScale, y: -renderScale)
        context.drawPDFPage(page)

        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

#endif
