// swift-tools-version: 5.7

import PackageDescription

extension Target.Dependency {
    static let TCA = Self.product(
        name: "ComposableArchitecture",
        package: "swift-composable-architecture"
    )

    static let SwiftTerm = Self.product(
        name: "SwiftTerm",
        package: "SwiftTerm"
    )

    static let AppFeature: Self = "AppFeature"
    static let FinderFeature: Self = "FinderFeature"
    static let TerminalFeature: Self = "TerminalFeature"
}

extension Target {
    static let AppFeature = Target.target(
        "AppFeature",
        group: "Feature",
        dependencies: [ .FinderFeature, .TerminalFeature ]
    )

    static let FinderFeature = Target.target(
        "FinderFeature",
        group: "Feature",
        dependencies: [ .TCA ]
    )

    static let TerminalFeature = Target.target(
        "TerminalFeature",
        group: "Feature",
        dependencies: [ .TCA, .SwiftTerm ]
    )
}

let package = Package(
    name: "Modules",
    platforms: [ .macOS(.v13) ],
    products: [
        .library(name: Target.AppFeature.name, targets: [ .AppFeature ]),
        .library(name: Target.FinderFeature.name, targets: [ .FinderFeature ]),
        .library(name: Target.TerminalFeature.name, targets: [ .TerminalFeature ])
    ],
    dependencies: [
        .package(
            url: "https://github.com/pointfreeco/swift-composable-architecture",
            from: "0.47.0"),
        .package(
            url: "https://github.com/migueldeicaza/SwiftTerm",
            from: "1.0.0"),
    ],
    targets: [
        .AppFeature,
        .FinderFeature,
        .TerminalFeature
    ]
)

for target in package.targets {
    target.swiftSettings = [
        .unsafeFlags([
            "-Xfrontend", "-enable-actor-data-race-checks",
            "-Xfrontend", "-warn-concurrency",
        ])
    ]
}

// ---------------------------------
// Extensions to reduce repetition

extension Target {
    public static func target(_ name: String, group: String, dependencies: [PackageDescription.Target.Dependency] = [], exclude: [String] = [], sources: [String]? = nil, resources: [PackageDescription.Resource]? = nil, publicHeadersPath: String? = nil, cSettings: [PackageDescription.CSetting]? = nil, cxxSettings: [PackageDescription.CXXSetting]? = nil, swiftSettings: [PackageDescription.SwiftSetting]? = nil, linkerSettings: [PackageDescription.LinkerSetting]? = nil, plugins: [PackageDescription.Target.PluginUsage]? = nil) -> PackageDescription.Target {
        target(name: name, dependencies: dependencies, path: "\(group)/\(name)", exclude: exclude, sources: sources, resources: resources, cSettings: cSettings, cxxSettings: cxxSettings, linkerSettings: linkerSettings, plugins: plugins)
    }
}

extension Product {
    public static func library(name: String, type: PackageDescription.Product.Library.LibraryType? = nil, targets: [Target]) -> PackageDescription.Product {
        library(name: name, type: type, targets: targets.map { $0.name })
    }
}

