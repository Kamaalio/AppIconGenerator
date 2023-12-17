//
//  AppIconGeneratorTests.swift
//
//
//  Created by Kamaal M Farah on 17/12/2023.
//

import XCTest
@testable import AppIconGenerator

final class AppIconGeneratorTests: XCTestCase {
    func testExcecute() throws {
        let path = try XCTUnwrap(Bundle.module.path(forResource: "yami", ofType: "jpg"))
        let url = URL(fileURLWithPath: path)
        let data = try Data(contentsOf: url)
        let testDirectoryPath = #file.split(separator: "/").dropLast().joined(separator: "/")
        let outputDirectory = try XCTUnwrap(URL(string: "/\(testDirectoryPath)"))
        try AppIconGenerator.execute(outputDirectory: outputDirectory, input: data)
    }
}
