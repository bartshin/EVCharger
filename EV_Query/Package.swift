// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "EV_Query",
    platforms: [.macOS(.v10_15)],
    products: [
        .executable(
            name: "EV_Query",
            targets: ["EV_Query"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-server/swift-aws-lambda-runtime.git", .upToNextMajor(from: "0.3.0")),
        .package(url: "https://github.com/vapor/mysql-kit.git", from: "4.0.0"),
        
    ],
    targets: [
        .target(
            name: "EV_Query",
            dependencies: [
                .product(name: "AWSLambdaRuntime", package: "swift-aws-lambda-runtime"),
                .product(name: "AWSLambdaEvents", package: "swift-aws-lambda-runtime"),
                .product(name: "MySQLKit", package: "mysql-kit")
            ]),
        .testTarget(
            name: "EV_QueryTests",
            dependencies: ["EV_Query"]),
    ]
)
