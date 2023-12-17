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

    func testExcecute() async throws {
        #if os(macOS)
        let outputDirectory = try makeOutputDirectory()
        let swiftUIImage = try getSwiftUIImage(named: "saitama", withExtension: "jpeg")

        try await AppIconGenerator.execute(outputDirectory: outputDirectory, image: swiftUIImage)

        let expectedAppIconDirectory = outputDirectory.appending(path: "AppIcon.appiconset")
        let contents = try fileManager.contentsOfDirectory(atPath: expectedAppIconDirectory.absoluteString)
        XCTAssertEqual(contents.count, 36)
        #endif
    }

    private func makeOutputDirectory() throws -> URL {
        let testDirectoryPath = #file.split(separator: "/").dropLast().joined(separator: "/")
        return try XCTUnwrap(URL(string: "/\(testDirectoryPath)"))
    }

    private func getSwiftUIImage(named name: String, withExtension fileExtension: String) throws -> Image {
        let path = try XCTUnwrap(Bundle.module.path(forResource: name, ofType: fileExtension))
        let url = URL(fileURLWithPath: path)
        let data = try Data(contentsOf: url)
        let nsImage = try XCTUnwrap(NSImage(data: data))
        return Image(nsImage: nsImage)
    }
}
