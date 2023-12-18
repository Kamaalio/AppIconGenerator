//
//  AppIconGeneratorTests.swift
//
//
//  Created by Kamaal M Farah on 17/12/2023.
//

import XCTest
import SwiftUI
@testable import AppIconGenerator

final class AppIconGeneratorTests: XCTestCase {
    private let fileManager = FileManager.default

    func testMakeAppIconSet() async throws {
        let expectedAmountOfImages = 35
        let swiftUIImage = try getSwiftUIImage(named: "saitama", withExtension: "jpeg")
        #if os(macOS)
        let outputDirectory = try makeOutputDirectory()

        let appIconSet = try await AppIconGenerator.makeAppIconSet(to: outputDirectory, outOf: swiftUIImage).get()

        let expectedAppIconDirectory = outputDirectory.appending(path: "AppIcon.appiconset")
        let contents = try fileManager.contentsOfDirectory(atPath: expectedAppIconDirectory.absoluteString)
        XCTAssertEqual(contents.count, expectedAmountOfImages + 1)
        XCTAssertEqual(appIconSet.images.count, expectedAmountOfImages)
        #else
        let appIconSet = try await AppIconGenerator.makeAppIconSet(outOf: swiftUIImage).get()

        XCTAssertEqual(appIconSet.images.count, expectedAmountOfImages)
        #endif
    }

    #if os(macOS)
    func testAppIconSetContents() async throws {
        let swiftUIImage = try getSwiftUIImage(named: "yami", withExtension: "jpg")
        let outputDirectory = try makeOutputDirectory()

        let appIconSet = try await AppIconGenerator.makeAppIconSet(to: outputDirectory, outOf: swiftUIImage).get()

        let contentsJSONURL = outputDirectory
            .appending(path: "AppIcon.appiconset")
            .appending(path: "Contents")
            .appendingPathExtension("json")
        let contentsJSONFileURL = URL(filePath: contentsJSONURL.absoluteString)
        let contentsJSON = try Data(contentsOf: contentsJSONFileURL)
        let contents = try JSONDecoder().decode(Contents.self, from: contentsJSON)

        XCTAssertEqual(contents, appIconSet.content)
    }

    func testAppIconSetImages() async throws {
        let expectedAmountOfImages = 35
        let swiftUIImage = try getSwiftUIImage(named: "yami", withExtension: "jpg")
        let outputDirectory = try makeOutputDirectory()

        let appIconSet = try await AppIconGenerator.makeAppIconSet(to: outputDirectory, outOf: swiftUIImage).get()

        let expectedAppIconDirectory = outputDirectory.appending(path: "AppIcon.appiconset")
        let contents = try fileManager.contentsOfDirectory(atPath: expectedAppIconDirectory.absoluteString)
            .filter({ name in name.contains(".png") })

        XCTAssertEqual(contents.count, expectedAmountOfImages)
        XCTAssertEqual(appIconSet.images.map(\.filename).sorted(), contents.sorted())
    }
    #endif

    #if os(macOS)
    private func makeOutputDirectory() throws -> URL {
        let testDirectoryPath = #file.split(separator: "/").dropLast().joined(separator: "/")
        return try XCTUnwrap(URL(string: "/\(testDirectoryPath)"))
    }
    #endif

    private func getSwiftUIImage(named name: String, withExtension fileExtension: String) throws -> Image {
        let path = try XCTUnwrap(Bundle.module.path(forResource: name, ofType: fileExtension))
        let url = URL(fileURLWithPath: path)
        let data = try Data(contentsOf: url)
        #if os(macOS)
        let nsImage = try XCTUnwrap(NSImage(data: data))
        return Image(nsImage: nsImage)
        #else
        let uiImage = try XCTUnwrap(UIImage(data: data))
        return Image(uiImage: uiImage)
        #endif
    }
}
