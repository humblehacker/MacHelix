//
//  FinderModel.swift
//  FileManager
//
//  Created by David Whetstone on 12/26/22.
//

import Foundation

class FinderModel: ObservableObject {
    private var currentDirectory: URL
    @Published var currentDirectoryContents: [String] = []

    init(currentDirectory: URL) {
        self.currentDirectory = currentDirectory
    }

    func setCurrentDirectory(_ currentDirectory: URL) {
        self.currentDirectory = currentDirectory

        let fm = FileManager.default

        do {
            currentDirectoryContents = try fm.contentsOfDirectory(atPath: currentDirectory.path)

        } catch {
            currentDirectoryContents = []
        }
    }
}
