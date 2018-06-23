// swift-tools-version:4.0
import PackageDescription

let package = Package(
	name: "CwlPreconditionTesting",
	products: [
		.library(name: "CwlPreconditionTesting", type: .dynamic, targets: ["CwlPreconditionTesting"]),
	],
	dependencies: [
		.package(url: "https://github.com/mattgallagher/CwlCatchException.git", .revision("d590bbd49017bec2dccdd6ea7d3cb5491734c032")),
	],
	targets: [
		.target(
			name: "CwlPreconditionTesting",
			dependencies: [
				.target(name: "CwlMachBadInstructionHandler"),
				.product(name: "CwlCatchException")
			],
			exclude: [
				"./Mach/CwlPreconditionTesting.h",
				"./Posix/CwlPreconditionTesting.h",
				"./CwlCatchBadInstructionPosix.swift"
			]
		),
		.target(name: "CwlMachBadInstructionHandler"),
		.testTarget(name: "CwlPreconditionTestingTests", dependencies: ["CwlPreconditionTesting"])
	]
)
