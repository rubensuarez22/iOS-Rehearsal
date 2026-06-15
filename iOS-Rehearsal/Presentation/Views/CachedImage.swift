//
//  CachedImage.swift
//  iOS-Rehearsal
//
//  Created by Rubén Suárez on 14/06/26.
//

import SwiftUI

/// Un gestor de caché persistente en disco para las imágenes descargadas.
/// Ignora las cabeceras Cache-Control del servidor para garantizar que las imágenes
/// cargadas se muestren de forma instantánea y offline, incluso bajo Rate Limiting (HTTP 429).
public final class ImageCacheManager {
    public static let shared = ImageCacheManager()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    private init() {
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDirectory = paths[0].appendingPathComponent("CharacterImagesCache")
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    private func getImagePath(for urlString: String) -> URL? {
        guard let data = urlString.data(using: .utf8) else { return nil }
        let hash = data.base64EncodedString()
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        return cacheDirectory.appendingPathComponent(hash)
    }
    
    public func loadImageFromDisk(for urlString: String) -> UIImage? {
        guard let path = getImagePath(for: urlString),
              fileManager.fileExists(atPath: path.path),
              let data = try? Data(contentsOf: path) else {
            return nil
        }
        return UIImage(data: data)
    }
    
    public func saveImageToDisk(data: Data, for urlString: String) {
        guard let path = getImagePath(for: urlString) else { return }
        try? data.write(to: path)
    }
}

/// Una vista de imagen que carga de forma síncrona/asíncrona desde caché de disco
/// local, y descarga de red sólo si es la primera vez que se accede a ella.
public struct CachedImage<Content: View, Placeholder: View>: View {
    private let urlString: String
    private let content: (Image) -> Content
    private let placeholder: () -> Placeholder
    
    @State private var image: UIImage? = nil
    @State private var isLoading = false
    
    public init(
        urlString: String,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.urlString = urlString
        self.content = content
        self.placeholder = placeholder
    }
    
    public var body: some View {
        Group {
            if let image = image {
                content(Image(uiImage: image))
            } else {
                placeholder()
                    .onAppear {
                        loadImage()
                    }
            }
        }
    }
    
    private func loadImage() {
        // 1. Intentamos cargar de disco inmediatamente (síncrono) para evitar parpadeos
        if let cached = ImageCacheManager.shared.loadImageFromDisk(for: urlString) {
            self.image = cached
            return
        }
        
        guard !isLoading else { return }
        guard let url = URL(string: urlString) else { return }
        
        isLoading = true
        
        // 2. Si no está en disco, descargamos en segundo plano de forma limpia
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data, let downloadedImage = UIImage(data: data) else {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                return
            }
            
            // Guardamos en el caché de disco para futuros renders
            ImageCacheManager.shared.saveImageToDisk(data: data, for: urlString)
            
            DispatchQueue.main.async {
                self.image = downloadedImage
                self.isLoading = false
            }
        }.resume()
    }
}
