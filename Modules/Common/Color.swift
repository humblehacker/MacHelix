//
//  File.swift
//  
//
//  Created by David Whetstone on 8/31/23.
//

import Foundation

public struct Color: Equatable, Sendable {
    public let red: Int
    public let green: Int
    public let blue: Int

    public init(hexColorString: String) {
        // Ensure the string has the expected length
        guard hexColorString.count == 7 else { fatalError("malformed hex color string: \(hexColorString)") }

        // Remove the # prefix
        let colorString = hexColorString.dropFirst()

        // Extract the red, green, and blue substrings
        guard let red = Int(colorString.prefix(2), radix: 16),
              let green = Int(colorString.dropFirst(2).prefix(2), radix: 16),
              let blue = Int(colorString.dropFirst(4).prefix(2), radix: 16)
        else { fatalError("malformed hex color string: \(hexColorString)") }

        self.red = red
        self.green = green
        self.blue = blue
    }
}


