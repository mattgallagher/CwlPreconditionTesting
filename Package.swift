// swift-tools-version:4.0
import PackageDescription

let package = Package(
	name: "CwlPreconditionTesting",
	dependencies: [
		.package(url: "https://github.com/mattgallagher/CwlCatchException.git", .branch("xcode10")),
	],
	targets: [
		.target(
			name: "CwlPreconditionTesting",
			dependencies: [
				"CwlMachBadInstructionHandler"
			],
			exclude: [
				"./Mach/CwlPreconditionTesting.h",
				"./Posix/CwlPreconditionTesting.h",
				"./CwlCatchBadInstructionPosix.swift",
			]
		),
		.target(name: "CwlMachBadInstructionHandler", dependencies: [.product(name: "CwlCatchException")]),
		.testTarget(name: "CwlPreconditionTestingTests", dependencies: ["CwlPreconditionTesting"])
	]
)
