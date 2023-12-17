//
//  Contents.swift
//  
//
//  Created by Kamaal M Farah on 17/12/2023.
//

import Foundation

struct Contents: Codable {
    let images: [Image]
    let info: Info

    struct Image: Codable {
        let filename: String?
        let idiom: String
        let scale: String
        let size: String
        let subtype: String?
        let role: String?
    }

    struct Info: Codable {
        let author: String
        let version: Int
    }
}
