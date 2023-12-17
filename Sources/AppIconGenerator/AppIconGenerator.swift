//
//  AppIconGenerator.swift
//
//
//  Created by Kamaal M Farah on 17/12/2023.
//

import SwiftUI

enum AppIconGeneratorErrors: Error {
    case invalidImageProvided
}

public enum AppIconGenerator {
    public static func execute(outputDirectory: URL, image: Image) async throws {
        #if !os(macOS)
        fatalError("This method is only supported on macOS")
        #else
        let contents = getContentsJSON()
        let appIconDirectory = try makeAppIconDirectory(outputDirectory: outputDirectory)
        try addContentsToAppIconDirectory(appIconDirectory: appIconDirectory, contents: contents)
        try await makeImages(contents: contents, image: image, destination: appIconDirectory)
        #endif
    }

    #if os(macOS)
    private static func makeImages(contents: Contents, image: Image, destination: URL) async throws {
        let resizableImage = image.resizable()
        let imagesToCreateMap = contents.images
            .reduce([URL: any View]()) { result, contentImage in
                guard let filename = contentImage.filename else { return result }

                let fileURL =  URL(filePath: destination.appending(path: filename).absoluteString)
                guard result[fileURL] == nil else { return result }
                guard let size = Double(contentImage.size.split(separator: "x")[0]) else { return result }
                guard let scale = Double(contentImage.scale.split(separator: "x")[0]) else { return result }

                let scaledSize = size * scale
                let scaledImage = resizableImage.frame(width: scaledSize, height: scaledSize)
                var result = result
                result[fileURL] = scaledImage
                return result
            }

        try await withThrowingTaskGroup(of: (Data?, URL).self) { group in
            for (imageURL, scaledImage) in imagesToCreateMap {
                group.addTask { await (transformViewToPNG(view: scaledImage), imageURL) }
            }

            for try await (pngData, imageURL) in group {
                guard let pngData else { throw AppIconGeneratorErrors.invalidImageProvided }

                try pngData.write(to: imageURL)
            }
        }
    }

    @MainActor
    private static func transformViewToPNG(view: some View) -> Data? {
        guard let nsImage = ImageRenderer(content: view).nsImage else { return nil }
        guard let tiffRepresentation = nsImage.tiffRepresentation  else { return nil }
        guard let imageRepresentation = NSBitmapImageRep(data: tiffRepresentation)  else { return nil }
        guard let pngData = imageRepresentation.representation(using: .png, properties: [:])  else { return nil }

        return pngData
    }

    private static func addContentsToAppIconDirectory(appIconDirectory: URL, contents: Contents) throws {
        let contentsURL = appIconDirectory.appending(path: "Contents").appendingPathExtension("json")
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        try encoder.encode(contents).write(to: URL(filePath: contentsURL.absoluteString))
    }

    private static func makeAppIconDirectory(outputDirectory: URL) throws -> URL {
        let outputDirectory = outputDirectory.appending(path: "AppIcon.appiconset")
        let outputDirectoryPath = outputDirectory.absoluteString
        let fileManager = FileManager.default
        let directoryExists = fileManager.fileExists(atPath: outputDirectoryPath)
        if directoryExists {
            try fileManager.removeItem(atPath: outputDirectoryPath)
        }
        try fileManager.createDirectory(atPath: outputDirectoryPath, withIntermediateDirectories: true)

        return URL(string: outputDirectoryPath)!
    }

    private static func getContentsJSON() -> Contents {
        let path = Bundle.module.path(forResource: "Contents", ofType: "json")!
        let url = URL(fileURLWithPath: path)
        let data = try! Data(contentsOf: url)

        return try! JSONDecoder().decode(Contents.self, from: data)
    }
    #endif
}
