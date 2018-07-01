// swift-tools-version:4.0
import PackageDescription

let package = Package(
	name: "CwlPreconditionTesting",
	products: [
		.library(name: "CwlPreconditionTesting", type: .dynamic, targets: ["CwlPreconditionTesting", "CwlMachBadInstructionHandler"]),
		.library(name: "CwlCatchException", type: .dynamic, targets: ["CwlCatchException"])
	],
	dependencies: [],
	targets: [
		.target(
			name: "CwlPreconditionTesting",
			dependencies: [
				.target(name: "CwlMachBadInstructionHandler"),
				.target(name: "CwlCatchException")
			],
			exclude: [
				"./Mach/CwlPreconditionTesting.h",
				"./Posix/CwlPreconditionTesting.h",
				"./CwlCatchBadInstructionPosix.swift"
			]
		),
		.target(
			name: "CwlCatchException",
			dependencies: [
				.target(name: "CwlCatchExceptionSupport")
			]
		),
		.target(name: "CwlCatchExceptionSupport"),
		.target(name: "CwlMachBadInstructionHandler"),
		.testTarget(name: "CwlPreconditionTestingTests", dependencies: ["CwlPreconditionTesting"]),
		.testTarget(name: "CwlCatchExceptionTests", dependencies: ["CwlCatchException"])
	]
)
