//
//  CwlCatchBadInstructionTests.swift
//  CwlPreconditionTesting
//
//  Created by Matt Gallagher on 2016/01/10.
//  Copyright © 2016 Matt Gallagher ( http://cocoawithlove.com ). All rights reserved.
//
//  Permission to use, copy, modify, and/or distribute this software for any purpose with or without
//  fee is hereby granted, provided that the above copyright notice and this permission notice
//  appear in all copies.
//
//  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS
//  SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE
//  AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
//  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT,
//  NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE
//  OF THIS SOFTWARE.
//

import Foundation
import XCTest
import CwlPreconditionTesting

class CatchBadInstructionTests: XCTestCase {
	func testCatchBadInstruction() {
	#if arch(x86_64)
		// Test catching an assertion failure
		var reachedPoint1 = false
		var reachedPoint2 = false
		let exception1: BadInstructionException? = catchBadInstruction {
			// Must invoke this block
			reachedPoint1 = true
			
			// Fatal error raised
			precondition(false, "EXC_BAD_INSTRUCTION raised here")

			// Exception must be thrown so that this point is never reached
			reachedPoint2 = true
		}
		// We must get a valid BadInstructionException
		XCTAssert(exception1 != nil)
		XCTAssert(reachedPoint1)
		XCTAssert(!reachedPoint2)
		
		// Test without catching an assertion failure
		var reachedPoint3 = false
		let exception2: BadInstructionException? = catchBadInstruction {
			// Must invoke this block
			reachedPoint3 = true
		}
		// We must not get a BadInstructionException without an assertion
		XCTAssert(reachedPoint3)
		XCTAssert(exception2 == nil)
	#endif
	}

	func testExecTypesCountTuple() {
	#if arch(x86_64)
		// I don't normally write a lot of internal logic tests (I believe in keeping tests at the interface level where possible) but it's important to confirm that creating an UnsafeMutablePointer to the zero-th index of a tuple properly edits the tuple in-place rather than copying the first element to another location and making the pointer to that other location. We need in-place behavior otherwise our code which passes a pointer to the zero-th element to the mach C functions would be memory unsafe.
		// This code also confirms the length of the tuple is 14 elements and I haven't simply made a visually hard to spot typo in the execTypesCountTuple declaration.
		var tuple = execTypesCountTuple<Int>()
		XCTAssert(sizeofValue(tuple) == sizeof(Int) * 14)
		withUnsafeMutablePointer(&tuple.value.0) { v in
			let fullTuple = UnsafeMutablePointer<(Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int)>(v)
			fullTuple.memory.0 = 1
			fullTuple.memory.1 = 2
			fullTuple.memory.2 = 3
			fullTuple.memory.3 = 4
			fullTuple.memory.4 = 5
			fullTuple.memory.5 = 6
			fullTuple.memory.6 = 7
			fullTuple.memory.7 = 8
			fullTuple.memory.8 = 9
			fullTuple.memory.9 = 10
			fullTuple.memory.10 = 11
			fullTuple.memory.11 = 12
			fullTuple.memory.12 = 13
			fullTuple.memory.13 = 14
		}
		XCTAssert(tuple.value.0 == 1)
		XCTAssert(tuple.value.1 == 2)
		XCTAssert(tuple.value.2 == 3)
		XCTAssert(tuple.value.3 == 4)
		XCTAssert(tuple.value.4 == 5)
		XCTAssert(tuple.value.5 == 6)
		XCTAssert(tuple.value.6 == 7)
		XCTAssert(tuple.value.7 == 8)
		XCTAssert(tuple.value.8 == 9)
		XCTAssert(tuple.value.9 == 10)
		XCTAssert(tuple.value.10 == 11)
		XCTAssert(tuple.value.11 == 12)
		XCTAssert(tuple.value.12 == 13)
		XCTAssert(tuple.value.13 == 14)
	#endif
	}
}
