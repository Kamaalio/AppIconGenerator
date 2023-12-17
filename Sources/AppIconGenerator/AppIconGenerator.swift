//
//  AppIconGenerator.swift
//
//
//  Created by Kamaal M Farah on 17/12/2023.
//

import Foundation

public struct AppIconGenerator {
    private init() { }

    public static func execute(outputDirectory: URL, input: Data) throws {
        let contents = getContentsJSON()
        let appIconDirectory = try makeAppIconDirectory(outputDirectory: outputDirectory)
        try addContentsToAppIconDirectory(appIconDirectory: appIconDirectory, contents: contents)
    }

    private static func addContentsToAppIconDirectory(appIconDirectory: URL, contents: Contents) throws {
        let contentsURL = appIconDirectory.appending(path: "Contents").appendingPathExtension("json")
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        try encoder.encode(contents).write(to: URL(filePath: contentsURL.absoluteString))
    }

    private static func makeAppIconDirectory(outputDirectory: URL) throws -> URL {
        let outputDirectory = outputDirectory.appending(path: "AppIcon").appendingPathExtension("appiconset")
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
}
