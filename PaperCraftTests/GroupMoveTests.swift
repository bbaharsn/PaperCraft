//
//  GroupMoveTests.swift
//  PaperCraftTests
//

import Testing
@testable import PaperCraft

struct GroupMoveTests {

    private func frame(x: Double, width: Double, y: Double = 0.2, height: Double = 0.1) -> NormalizedFrame {
        NormalizedFrame(x: x, y: y, width: width, height: height)
    }

    private func isClose(_ a: Double, _ b: Double) -> Bool { abs(a - b) < 1e-9 }

    @Test func passesThroughWhenInside() {
        let move = GroupMove.clamped(dx: 0.1, dy: 0.1, frames: [frame(x: 0.2, width: 0.2), frame(x: 0.5, width: 0.1)],
                                     keepsOnScreen: false)
        #expect(isClose(move.dx, 0.1) && isClose(move.dy, 0.1))
    }

    @Test func clampsWholeGroupAtLeftEdge() {
        let move = GroupMove.clamped(dx: -0.3, dy: 0, frames: [frame(x: 0.1, width: 0.1), frame(x: 0.5, width: 0.1)],
                                     keepsOnScreen: false)
        #expect(isClose(move.dx, -0.1))
    }

    @Test func clampsWholeGroupAtRightEdge() {
        let move = GroupMove.clamped(dx: 0.3, dy: 0, frames: [frame(x: 0.2, width: 0.1), frame(x: 0.7, width: 0.2)],
                                     keepsOnScreen: false)
        #expect(isClose(move.dx, 0.1))
    }

    @Test func clampsAtTopButNotBottom() {
        let frames = [frame(x: 0.1, width: 0.1, y: 0.05)]
        #expect(isClose(GroupMove.clamped(dx: 0, dy: -0.2, frames: frames, keepsOnScreen: false).dy, -0.05))
        #expect(isClose(GroupMove.clamped(dx: 0, dy: 5, frames: frames, keepsOnScreen: false).dy, 5))
    }

    @Test func keepsOnScreenClampsBottom() {
        let frames = [frame(x: 0, width: 1, y: 0.85, height: 0.1)]
        #expect(isClose(GroupMove.clamped(dx: 0, dy: 0.2, frames: frames, keepsOnScreen: true).dy, 0.05))
    }
}
