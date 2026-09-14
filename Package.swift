// swift-tools-version: 5.9
import PackageDescription
let package = Package(
    name: "DuoSoundCore",
    platforms: [.iOS(.v17), .macOS(.v13)],
    products: [.library(name: "DuoSoundCore", targets: ["DuoSoundCore"])],
    targets: [
        .target(name: "DuoSoundCore"),
        .testTarget(name: "DuoSoundCoreTests", dependencies: ["DuoSoundCore"])
    ]
)
