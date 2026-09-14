// swift-tools-version: 5.9
import PackageDescription
let package = Package(
    name: "DuoSoundCore",
    platforms: [.iOS(.v17), .macOS(.v13)],
    products: [
        .library(name: "DuoSoundCore", targets: ["DuoSoundCore"]),
        .executable(name: "SoundPreview", targets: ["SoundPreview"])
    ],
    targets: [
        .target(name: "DuoSoundCore"),
        .executableTarget(name: "SoundPreview", dependencies: ["DuoSoundCore"], path: "Tools/SoundPreview"),
        .testTarget(name: "DuoSoundCoreTests", dependencies: ["DuoSoundCore"])
    ]
)
