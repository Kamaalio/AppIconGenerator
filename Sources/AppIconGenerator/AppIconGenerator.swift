//
//  AppIconGenerator.swift
//
//
//  Created by Kamaal M Farah on 17/12/2023.
//

import SwiftUI

public enum AppIconGenerator {
    public static func makeImages(to outputDirectory: URL, image: Image) async -> Result<AppIconSet, AppIconGeneratorErrors> {
        let contents = getContentsJSON()
        let appIconDirectoryResult = makeAppIconDirectory(outputDirectory: outputDirectory)
        let appIconDirectory: URL
        switch appIconDirectoryResult {
        case .failure(let failure): return .failure(failure)
        case .success(let success): appIconDirectory = success
        }
        let addContentsToAppIconDirectoryResult = addContentsToAppIconDirectory(
            appIconDirectory: appIconDirectory,
            contents: contents
        )
        switch addContentsToAppIconDirectoryResult {
        case .failure(let failure): return .failure(failure)
        case .success: break
        }

        let appIconSetResult = await makeImages(contents: contents, image: image, outputDirectory: appIconDirectory)
        let appIconSet: AppIconSet
        switch appIconSetResult {
        case .failure(let failure): return .failure(failure)
        case .success(let success): appIconSet = success
        }

        for appIconSetImage in appIconSet.images {
            do {
                try appIconSetImage.data.write(to: appIconSetImage.url!)
            } catch {
                return .failure(.writeToDestinationDirectoryFailure(context: error))
            }
        }

        return .success(appIconSet)
    }

    public static func makeImages(image: Image) async -> Result<AppIconSet, AppIconGeneratorErrors> {
        let contents = getContentsJSON()
        return await makeImages(contents: contents, image: image, outputDirectory: nil)
    }
}

public enum AppIconGeneratorErrors: Error {
    case invalidImageProvided
    case destinationDirectoryCleanupFailure(context: Error)
    case destinationDirectoryCreationFailure(context: Error)
    case writeToDestinationDirectoryFailure(context: Error)
}

public struct AppIconSet {
    public let content: Contents
    public let images: [AppIconSetImage]

    public init(content: Contents, images: [AppIconSetImage]) {
        self.content = content
        self.images = images
    }

    public struct AppIconSetImage {
        public let filename: String
        public let data: Data
        public let url: URL?

        public init(filename: String, data: Data, url: URL?) {
            self.filename = filename
            self.data = data
            self.url = url
        }

        public var image: Image? {
            #if os(macOS)
            guard let nsImage = NSImage(data: data) else { return nil }
            return Image(nsImage: nsImage)
            #else
            guard let uiImage = UIImage(data: data) else { return nil }
            return Image(uiImage: uiImage)
            #endif
        }
    }
}

public struct Contents: Codable {
    public let images: [ContentImage]
    public let info: Info

    public init(images: [ContentImage], info: Info) {
        self.images = images
        self.info = info
    }

    public struct ContentImage: Codable {
        public let filename: String?
        public let idiom: String
        public let scale: String
        public let size: String
        public let subtype: String?
        public let role: String?

        public init(filename: String?, idiom: String, scale: String, size: String, subtype: String?, role: String?) {
            self.filename = filename
            self.idiom = idiom
            self.scale = scale
            self.size = size
            self.subtype = subtype
            self.role = role
        }
    }

    public struct Info: Codable {
        public let author: String
        public let version: Int

        public init(author: String, version: Int) {
            self.author = author
            self.version = version
        }
    }
}

extension AppIconGenerator {
    private static let jsonEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return encoder
    }()

    private static func makeImages(
        contents: Contents,
        image: Image,
        outputDirectory: URL?
    ) async -> Result<AppIconSet, AppIconGeneratorErrors> {
        let imagesToCreateMappedByName = resizeImage(image, basedOn: contents)
        return await withTaskGroup(
            of: (Data?, String).self,
            returning: Result<AppIconSet, AppIconGeneratorErrors>.self
        ) { group in
            for (filename, scaledImage) in imagesToCreateMappedByName {
                group.addTask { await (transformViewToPNG(view: scaledImage), filename) }
            }

            var images = [AppIconSet.AppIconSetImage]()
            for await (pngData, filename) in group {
                guard let pngData else { return .failure(.invalidImageProvided) }

                var url: URL?
                if let outputDirectory {
                    url =  URL(filePath: outputDirectory.appending(path: filename).absoluteString)
                }
                images.append(.init(filename: filename, data: pngData, url: url))
            }
            return .success(AppIconSet(content: contents, images: images))
        }
    }

    private static func resizeImage(_ image: Image, basedOn contents: Contents) -> [String: any View] {
        let resizableImage = image.resizable()
        var imagesMappedByFilename = [String: any View]()
        for contentImage in contents.images {
            guard let filename = contentImage.filename else { continue }

            guard imagesMappedByFilename[filename] == nil else { continue }
            guard let size = Double(contentImage.size.split(separator: "x")[0]) else { continue }
            guard let scale = Double(contentImage.scale.split(separator: "x")[0]) else { continue }

            let scaledSize = size * scale
            let scaledImage = resizableImage.frame(width: scaledSize, height: scaledSize)
            imagesMappedByFilename[filename] = scaledImage
        }

        return imagesMappedByFilename
    }

    @MainActor
    private static func transformViewToPNG(view: some View) -> Data? {
        #if os(iOS)
        ImageRenderer(content: view)
            .uiImage?
            .pngData()
        #else
        guard let tiffRepresentation = ImageRenderer(content: view)
            .nsImage?
            .tiffRepresentation else { return nil }

        return NSBitmapImageRep(data: tiffRepresentation)?
            .representation(using: .png, properties: [:])
        #endif
    }

    private static func addContentsToAppIconDirectory(
        appIconDirectory: URL,
        contents: Contents
    ) -> Result<Void, AppIconGeneratorErrors> {
        let contentsURL = appIconDirectory.appending(path: "Contents").appendingPathExtension("json")
        let contentsURLFileURL = URL(filePath: contentsURL.absoluteString)
        do {
            try jsonEncoder.encode(contents).write(to: contentsURLFileURL)
        } catch {
            return .failure(.writeToDestinationDirectoryFailure(context: error))
        }

        return .success(())
    }

    private static func makeAppIconDirectory(outputDirectory: URL) -> Result<URL, AppIconGeneratorErrors> {
        let outputDirectory = outputDirectory.appending(path: "AppIcon.appiconset")
        let outputDirectoryPath = outputDirectory.absoluteString
        let fileManager = FileManager.default
        let directoryExists = fileManager.fileExists(atPath: outputDirectoryPath)
        if directoryExists {
            do {
                try fileManager.removeItem(atPath: outputDirectoryPath)
            } catch {
                return .failure(.destinationDirectoryCleanupFailure(context: error))
            }
        }

        do {
            try fileManager.createDirectory(atPath: outputDirectoryPath, withIntermediateDirectories: true)
        } catch {
            return .failure(.destinationDirectoryCreationFailure(context: error))
        }

        return .success(URL(string: outputDirectoryPath)!)
    }

    private static func getContentsJSON() -> Contents {
        let path = Bundle.module.path(forResource: "Contents", ofType: "json")!
        let url = URL(fileURLWithPath: path)
        let data = try! Data(contentsOf: url)

        return try! JSONDecoder().decode(Contents.self, from: data)
    }
}
