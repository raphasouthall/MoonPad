#if canImport(UIKit) && canImport(SwiftUI) && canImport(ZIPFoundation)
import SwiftUI
import ZIPFoundation

struct SkinPreview: Identifiable {
    let id: String          // filename
    let name: String
    let identifier: String
    let thumbnail: UIImage?

    var filename: String { id }
}

@available(iOS 15.0, *)
struct SkinPickerView: View {
    @SwiftUI.State private var skins: [SkinPreview] = []
    @Binding var selectedSkin: String
    let skinsDirectories: [URL]     // bundled + user directories

    var body: some View {
        List(skins) { skin in
            Button {
                selectedSkin = skin.filename
            } label: {
                HStack(spacing: 12) {
                    if let thumb = skin.thumbnail {
                        Image(uiImage: thumb)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 140)
                            .cornerRadius(8)
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 80, height: 140)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(skin.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text(skin.identifier)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    if skin.filename == selectedSkin {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.accentColor)
                            .font(.title3)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .navigationTitle("Controller Skin")
        .onAppear { loadSkins() }
    }

    private func loadSkins() {
        var results: [SkinPreview] = []
        let fm = FileManager.default

        for directory in skinsDirectories {
            guard let files = try? fm.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: nil
            ) else { continue }

            for fileURL in files where fileURL.pathExtension == "manicskin" {
                guard let preview = loadPreview(from: fileURL) else { continue }
                results.append(preview)
            }
        }

        skins = results.sorted { $0.name < $1.name }
    }

    private func loadPreview(from url: URL) -> SkinPreview? {
        guard let archive = Archive(url: url, accessMode: .read),
              let infoEntry = archive["info.json"] else { return nil }

        var infoData = Data()
        _ = try? archive.extract(infoEntry) { chunk in
            infoData.append(chunk)
        }

        guard let skin = try? JSONDecoder().decode(ManicSkin.self, from: infoData) else {
            return nil
        }

        // Extract a background PDF for the thumbnail (prefer iPhone portrait)
        let bgFilename: String? =
            skin.representations.iphone?.edgeToEdge?.portrait?.assets.resizable
            ?? skin.representations.iphone?.standard?.portrait?.assets.resizable
            ?? skin.representations.ipad?.standard?.portrait?.assets.resizable

        var thumbnail: UIImage? = nil
        if let bg = bgFilename, let bgEntry = archive[bg] {
            var pdfData = Data()
            _ = try? archive.extract(bgEntry) { chunk in
                pdfData.append(chunk)
            }
            thumbnail = renderThumbnail(pdfData: pdfData, maxHeight: 140)
        }

        return SkinPreview(
            id: url.lastPathComponent,
            name: skin.name,
            identifier: skin.identifier,
            thumbnail: thumbnail
        )
    }

    private func renderThumbnail(pdfData: Data, maxHeight: CGFloat) -> UIImage? {
        guard let provider = CGDataProvider(data: pdfData as CFData),
              let document = CGPDFDocument(provider),
              let page = document.page(at: 1) else { return nil }

        let mediaBox = page.getBoxRect(.mediaBox)
        let scale = maxHeight / mediaBox.height
        let size = CGSize(width: mediaBox.width * scale, height: maxHeight)

        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        defer { UIGraphicsEndImageContext() }
        guard let context = UIGraphicsGetCurrentContext() else { return nil }

        context.setFillColor(UIColor.clear.cgColor)
        context.fill(CGRect(origin: .zero, size: size))

        context.translateBy(x: 0, y: size.height)
        context.scaleBy(x: scale, y: -scale)
        context.drawPDFPage(page)

        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

#endif
