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
}

extension Color {
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


// origin: https://chat.openai.com/share/23d90922-b701-4c91-b40c-08e58974ce11
extension Color {
    public func isDark() -> Bool {
        let red = Double(red)/256
        let green = Double(green)/256
        let blue = Double(blue)/256

        // Convert sRGB values to linear values
        let linearRed = (red <= 0.04045) ? red / 12.92 : pow((red + 0.055) / 1.055, 2.4)
        let linearGreen = (green <= 0.04045) ? green / 12.92 : pow((green + 0.055) / 1.055, 2.4)
        let linearBlue = (blue <= 0.04045) ? blue / 12.92 : pow((blue + 0.055) / 1.055, 2.4)

        // Calculate relative luminance
        let luminance = 0.2126 * linearRed + 0.7152 * linearGreen + 0.0722 * linearBlue

        // Use a threshold to determine if the color is dark
        return luminance < 0.5
    }
}

