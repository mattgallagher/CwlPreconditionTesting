//
//  CwlCatchBadInstruction.swift
//  CwlPreconditionTesting
//
//  Created by Matt Gallagher on 2016/01/10.
//  Copyright © 2016 Matt Gallagher ( http://cocoawithlove.com ). All rights reserved.
//
//  Permission to use, copy, modify, and distribute this software for any purpose with or without
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

// This file contains two different implementations for the `catchBadInstruction` function.
//
// The !USE_POSIX_SIGNALS configuration contains the default implementation. This implementation catches Mach BAD_INSTRUCTION_EXCEPTIONs as described on the Cocoa with Love post:
//	http://cocoawithlove.com/blog/2016/02/02/partial-functions-part-two-catching-precondition-failures.html
//
// See the USE_POSIX_SIGNALS branch below for a version portable to systems without the Objective-C
// runtime or Mach exceptions.

#if !USE_POSIX_SIGNALS && arch(x86_64)

private enum PthreadError: ErrorType { case Any }
private enum MachExcServer: ErrorType { case Any }

/// A quick function for converting Mach error results into Swift errors
private func kernCheck(f: () -> Int32) throws {
	let r = f()
	guard r == KERN_SUCCESS else {
		throw NSError(domain: NSMachErrorDomain, code: Int(r), userInfo: nil)
	}
}

/// A structure used to store context associated with the Mach message port
private struct MachContext {
	var masks = execTypesCountTuple<exception_mask_t>()
    var count: mach_msg_type_number_t = 0
    var ports = execTypesCountTuple<mach_port_t>()
    var behaviors = execTypesCountTuple<exception_behavior_t>()
    var flavors = execTypesCountTuple<thread_state_flavor_t>()
	var currentExceptionPort: mach_port_t = 0
	var handlerThread: pthread_t = nil
}

/// A function for receiving mach messages and parsing the first with mach_exc_server (and if any others are received, throwing them away).
private func machMessageHandler(arg: UnsafeMutablePointer<Void>) -> UnsafeMutablePointer<Void> {
	let context = UnsafeMutablePointer<MachContext>(arg).memory
	var request = request_mach_exception_raise_t()
	var reply = reply_mach_exception_raise_state_t()
	
	var handledfirstException = false
	do { repeat {
		// Request the next mach message from the port
		request.Head.msgh_local_port = context.currentExceptionPort
		request.Head.msgh_size = UInt32(sizeofValue(request))
		try kernCheck { withUnsafeMutablePointer(&request) {
			mach_msg(UnsafeMutablePointer<mach_msg_header_t>($0), MACH_RCV_MSG | MACH_RCV_INTERRUPT, 0, request.Head.msgh_size, context.currentExceptionPort, 0, UInt32(MACH_PORT_NULL))
		} }
		
		// Prepare the reply structure
		reply.Head.msgh_bits = MACH_MSGH_BITS(MACH_MSGH_BITS_REMOTE(request.Head.msgh_bits), 0)
		reply.Head.msgh_local_port = UInt32(MACH_PORT_NULL)
		reply.Head.msgh_remote_port = request.Head.msgh_remote_port
		reply.Head.msgh_size = UInt32(sizeofValue(reply))
		reply.NDR = NDR_record
		
		if !handledfirstException {
			// Use the MiG generated server to invoke our handler for the request and fill in the rest of the reply structure
			guard withUnsafeMutablePointers(&request, &reply, {
				mach_exc_server(UnsafeMutablePointer<mach_msg_header_t>($0), UnsafeMutablePointer<mach_msg_header_t>($1))
			}) != 0 else { throw MachExcServer.Any }
			
			handledfirstException = true
		} else {
			// If multiple fatal errors occur, don't handle subsquent errors (let the program crash)
			reply.RetCode = KERN_FAILURE
		}

		// Send the reply
		try kernCheck { withUnsafeMutablePointer(&reply) {
			mach_msg(UnsafeMutablePointer<mach_msg_header_t>($0), MACH_SEND_MSG, reply.Head.msgh_size, 0, UInt32(MACH_PORT_NULL), 0, UInt32(MACH_PORT_NULL))
		} }
	} while true } catch let error as NSError where (error.domain == NSMachErrorDomain && (error.code == Int(MACH_RCV_PORT_CHANGED) || error.code == Int(MACH_RCV_INVALID_NAME))) {
		// Port was already closed before we started or closed while we were listening.
		// This means the block completed without raising an EXC_BAD_INSTRUCTION. Not a problem.
	} catch {
		// Should never be reached but this is testing code, don't try to recover, just abort
		fatalError("Mach message error: \(error)")
	}
	
	return nil
}

/// Run the provided block. If a mach "BAD_INSTRUCTION" exception is raised, catch it and return a BadInstructionException (which captures stack information about the throw site, if desired). Otherwise return nil.
/// NOTE: This function is only intended for use in test harnesses – use in a distributed build is almost certainly a bad choice. If a "BAD_INSTRUCTION" exception is raised, the block will be exited before completion via Objective-C exception. The risks associated with an Objective-C exception apply here: most Swift/Objective-C functions are *not* exception-safe. Memory may be leaked and the program will not necessarily be left in a safe state.
public func catchBadInstruction(block: () -> Void) -> BadInstructionException? {
	var context = MachContext()
	var result: BadInstructionException? = nil
	do {
		var handlerThread: pthread_t = nil
		defer {
            // 8. Wait for the thread to terminate *if* we actually made it to the creation point
            // The mach port should be destroyed *before* calling pthread_join to avoid a deadlock.
			if handlerThread != nil {
				pthread_join(handlerThread, nil)
			}
		}

		try kernCheck {
			// 1. Create the mach port
			mach_port_allocate(mach_task_self_, MACH_PORT_RIGHT_RECEIVE, &context.currentExceptionPort)
		}
		defer {
			// 7. Cleanup the mach port
			mach_port_destroy(mach_task_self_, context.currentExceptionPort)
		}
		
		try kernCheck {
			// 2. Configure the mach port
			mach_port_insert_right(mach_task_self_, context.currentExceptionPort, context.currentExceptionPort, MACH_MSG_TYPE_MAKE_SEND)
		}
		
		try kernCheck {
			// 3. Apply the mach port as the handler for this thread
			thread_swap_exception_ports(mach_thread_self(), EXC_MASK_BAD_INSTRUCTION, context.currentExceptionPort, Int32(bitPattern: UInt32(EXCEPTION_STATE) | MACH_EXCEPTION_CODES), x86_THREAD_STATE64, &context.masks.value.0, &context.count, &context.ports.value.0, &context.behaviors.value.0, &context.flavors.value.0)
		}
		defer {
			// 6. Unapply the mach port
			thread_swap_exception_ports(mach_thread_self(), EXC_MASK_BAD_INSTRUCTION, 0, EXCEPTION_DEFAULT, THREAD_STATE_NONE, &context.masks.value.0, &context.count, &context.ports.value.0, &context.behaviors.value.0, &context.flavors.value.0)
		}
		
		try withUnsafeMutablePointer(&context) { c throws in
			// 4. Create the thread
			guard pthread_create(&handlerThread, nil, machMessageHandler, c) == 0 else { throw PthreadError.Any }
			
			// 5. Run the block
			result = BadInstructionException.catchException(block)
		}
	} catch {
		// Should never be reached but this is testing code, don't try to recover, just abort
		fatalError("Mach port error: \(error)")
	}
	return result
}

#elseif USE_POSIX_SIGNALS

// ALTERNATIVE TO MACH EXCEPTIONS AND OBJECTIVE-C RUNTIME:
// Use a SIGILL signal action and setenv/longjmp/
//
// WARNING:
// This code is quick and dirty. It's a proof of concept for using a SIGILL handler and setjmp/longjmp where Mach exceptions and the Obj-C runtime aren't available. I ran the automated tests when I first wrote this code but I don't personally use it at all so by the time you're reading this comment, it probably broke and I didn't notice.
// Obvious limitations:
//	* It doesn't work when debugging with lldb.
//	* It doesn't scope correctly to the thread (it's global)
//  * In violation of rules for signal handlers, it writes to the "red zone" on the stack
//	* It isn't re-entrant
//  * Plus all of the same caveats as the Mach exceptions version (doesn't play well with other handlers, probably leaks ARC memory, etc)
// Treat it like a loaded shotgun. Don't point it at your face.

private var env = jmp_buf(0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0)

private func triggerLongJmp() {
	longjmp(&env.0, 1)
}

private func sigIllHandler(code: Int32, info: UnsafeMutablePointer<__siginfo>, uap: UnsafeMutablePointer<Void>) -> Void {
	let context = UnsafeMutablePointer<ucontext64_t>(uap)

	// 1. Decrement the stack pointer
	context.memory.uc_mcontext64.memory.__ss.__rsp -= __uint64_t(sizeof(Int))

	// 2. Save the old Instruction Pointer to the stack.
	let rsp = context.memory.uc_mcontext64.memory.__ss.__rsp
	UnsafeMutablePointer<__uint64_t>(bitPattern: UInt(rsp)).memory = rsp

	// 3. Set the Instruction Pointer to the new function's address
	var f: @convention(c) () -> Void = triggerLongJmp
	withUnsafePointer(&f) { context.memory.uc_mcontext64.memory.__ss.__rip = UnsafePointer<__uint64_t>($0).memory }
}

/// Run the provided block. If a POSIX SIGILL is received, handle it and return a BadInstructionException (which is just an empty object in this POSIX signal version). Otherwise return nil.
/// NOTE: This function is only intended for use in test harnesses – use in a distributed build is almost certainly a bad choice. If a SIGILL is received, the block will be interrupted using a C `longjmp`. The risks associated with abrupt jumps apply here: most Swift functions are *not* interrupt-safe. Memory may be leaked and the program will not necessarily be left in a safe state.
public func catchBadInstruction(block: () -> Void) -> BadInstructionException? {
	// Construct the signal action
	var sigActionPrev = sigaction()
	let action = __sigaction_u(__sa_sigaction: sigIllHandler)
	var sigActionNew = sigaction(__sigaction_u: action, sa_mask: sigset_t(), sa_flags: SA_SIGINFO)
	
	// Install the signal action
	if sigaction(SIGILL, &sigActionNew, &sigActionPrev) != 0 {
		fatalError("Sigaction error: \(errno)")
	}

	defer {
		// Restore the previous signal action
		if sigaction(SIGILL, &sigActionPrev, nil) != 0 {
			fatalError("Sigaction error: \(errno)")
		}
	}

	// Prepare the jump point
	if setjmp(&env.0) != 0 {
		// Handle jump received
		return BadInstructionException()
	}

	// Run the block
	block()
	
	return nil
}

#endif
