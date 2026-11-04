//
//  Copyright 2026 Readium Foundation. All rights reserved.
//  Use of this source code is governed by the BSD-style license
//  available in the top-level LICENSE file of the project.
//

import CoreGraphics
@testable import ReadiumNavigator
import Testing

enum EPUBEdgeSwipePolicyTests {
    struct IsNearTop {
        /// Viewport 800, top inset 40, unlock factor 0.75 => zone up to offset 560
        @Test func atTopEdge() {
            #expect(EPUBEdgeSwipePolicy.isNearTop(offset: -40, inset: 40, contentSize: 10000, viewportSize: 800))
        }

        @Test func withinUnlockZone() {
            #expect(EPUBEdgeSwipePolicy.isNearTop(offset: 560, inset: 40, contentSize: 10000, viewportSize: 800))
            #expect(EPUBEdgeSwipePolicy.isNearTop(offset: 300, inset: 40, contentSize: 10000, viewportSize: 800))
        }

        @Test func outsideUnlockZone() {
            #expect(!EPUBEdgeSwipePolicy.isNearTop(offset: 561, inset: 40, contentSize: 10000, viewportSize: 800))
            #expect(!EPUBEdgeSwipePolicy.isNearTop(offset: 5000, inset: 40, contentSize: 10000, viewportSize: 800))
        }

        @Test("Content no taller than two viewports is always unlockable")
        func shortContent() {
            #expect(EPUBEdgeSwipePolicy.isNearTop(offset: 800, inset: 40, contentSize: 1600, viewportSize: 800))
            #expect(!EPUBEdgeSwipePolicy.isNearTop(offset: 800, inset: 40, contentSize: 1601, viewportSize: 800))
        }
    }

    struct IsNearBottom {
        /// Viewport 800, content 10000, bottom inset 20 => max offset 9180,
        /// unlock zone from offset 8620
        @Test func atBottomEdge() {
            #expect(EPUBEdgeSwipePolicy.isNearBottom(offset: 9180, inset: 20, contentSize: 10000, viewportSize: 800))
        }

        @Test func withinUnlockZone() {
            #expect(EPUBEdgeSwipePolicy.isNearBottom(offset: 8620, inset: 20, contentSize: 10000, viewportSize: 800))
            #expect(EPUBEdgeSwipePolicy.isNearBottom(offset: 9000, inset: 20, contentSize: 10000, viewportSize: 800))
        }

        @Test func outsideUnlockZone() {
            #expect(!EPUBEdgeSwipePolicy.isNearBottom(offset: 8619, inset: 20, contentSize: 10000, viewportSize: 800))
            #expect(!EPUBEdgeSwipePolicy.isNearBottom(offset: 100, inset: 20, contentSize: 10000, viewportSize: 800))
        }

        @Test("Content no taller than two viewports is always unlockable")
        func shortContent() {
            #expect(EPUBEdgeSwipePolicy.isNearBottom(offset: 0, inset: 0, contentSize: 1600, viewportSize: 800))
            #expect(!EPUBEdgeSwipePolicy.isNearBottom(offset: 0, inset: 0, contentSize: 1601, viewportSize: 800))
        }
    }

    struct TapDirection {
        /// Width 800, edge threshold 30% => edge of 240 points
        @Test("LTR right edge moves forward, left edge backward")
        func ltr() {
            #expect(tapDirection(x: 790, progression: .ltr) == .forward)
            #expect(tapDirection(x: 10, progression: .ltr) == .backward)
        }

        @Test("RTL left edge moves forward, right edge backward")
        func rtl() {
            #expect(tapDirection(x: 10, progression: .rtl) == .forward)
            #expect(tapDirection(x: 790, progression: .rtl) == .backward)
        }

        @Test("Tap in the middle of the viewport is ignored")
        func middleOfViewport() {
            #expect(tapDirection(x: 400) == nil)
        }

        @Test("Small viewports use the minimum edge size")
        func minimumEdgeSize() {
            // Width 200, 30% = 60 < minimum 80 => zones [0...80] and [120...200]
            #expect(tapDirection(x: 90, width: 200) == nil)
            #expect(tapDirection(x: 80, width: 200) == .backward)
            #expect(tapDirection(x: 120, width: 200) == .forward)
        }

        @Test("Overlapping zones prefer forward")
        func overlappingZones() {
            // Width 120, minimum edge 80 => zones [0...80] and [40...120]
            #expect(tapDirection(x: 60, width: 120) == .forward)
        }
    }

    struct Direction {
        @Test("LTR swipe to the left at the bottom moves forward")
        func ltrForwardAtBottom() {
            #expect(direction(CGPoint(x: -30, y: 0), forwardEdge: true) == .forward)
        }

        @Test("LTR swipe to the right at the top moves backward")
        func ltrBackwardAtTop() {
            #expect(direction(CGPoint(x: 30, y: 0), backwardEdge: true) == .backward)
        }

        @Test("RTL swipe to the right at the bottom moves forward")
        func rtlForwardAtBottom() {
            #expect(direction(CGPoint(x: 30, y: 0), progression: .rtl, forwardEdge: true) == .forward)
        }

        @Test("RTL swipe to the left at the top moves backward")
        func rtlBackwardAtTop() {
            #expect(direction(CGPoint(x: -30, y: 0), progression: .rtl, backwardEdge: true) == .backward)
        }

        @Test("Swipe in the wrong direction at an edge is rejected")
        func wrongDirectionAtEdge() {
            // At the backward edge, only backward is allowed; and vice versa.
            #expect(direction(CGPoint(x: -30, y: 0), backwardEdge: true) == nil)
            #expect(direction(CGPoint(x: 30, y: 0), forwardEdge: true) == nil)
        }

        @Test("Swipe with no edge reached is rejected")
        func noEdgeReached() {
            #expect(direction(CGPoint(x: -30, y: 0)) == nil)
            #expect(direction(CGPoint(x: 30, y: 0)) == nil)
        }

        @Test("Both edges reached allows both directions")
        func bothEdges() {
            #expect(direction(CGPoint(x: -30, y: 0), backwardEdge: true, forwardEdge: true) == .forward)
            #expect(direction(CGPoint(x: 30, y: 0), backwardEdge: true, forwardEdge: true) == .backward)
        }

        @Test("Vertical-dominant drag is rejected")
        func verticalDominantDrag() {
            #expect(direction(CGPoint(x: 10, y: 50), backwardEdge: true, forwardEdge: true) == nil)
            #expect(direction(CGPoint(x: 50, y: 50), backwardEdge: true, forwardEdge: true) == nil)
            #expect(direction(CGPoint(x: 0, y: 0), backwardEdge: true, forwardEdge: true) == nil)
        }
    }

    struct ShouldTrigger {
        @Test("Long enough drag triggers even without momentum")
        func longDrag() {
            #expect(EPUBEdgeSwipePolicy.shouldTrigger(
                translation: CGPoint(x: -80, y: 0),
                velocity: CGPoint(x: -50, y: 0)
            ))
            #expect(EPUBEdgeSwipePolicy.shouldTrigger(
                translation: CGPoint(x: -EPUBEdgeSwipePolicy.minimumTranslation, y: 0),
                velocity: .zero
            ))
        }

        @Test("Short but fast drag triggers")
        func fastDrag() {
            #expect(EPUBEdgeSwipePolicy.shouldTrigger(
                translation: CGPoint(x: -30, y: 0),
                velocity: CGPoint(x: -600, y: 0)
            ))
        }

        @Test("Short and slow drag does not trigger")
        func shortSlowDrag() {
            #expect(!EPUBEdgeSwipePolicy.shouldTrigger(
                translation: CGPoint(x: -30, y: 0),
                velocity: CGPoint(x: -100, y: 0)
            ))
        }

        @Test("Velocity contradicting the translation does not trigger")
        func contradictingVelocity() {
            #expect(!EPUBEdgeSwipePolicy.shouldTrigger(
                translation: CGPoint(x: -80, y: 0),
                velocity: CGPoint(x: 200, y: 0)
            ))
        }

        @Test("No translation does not trigger")
        func noTranslation() {
            #expect(!EPUBEdgeSwipePolicy.shouldTrigger(
                translation: .zero,
                velocity: CGPoint(x: -800, y: 0)
            ))
        }
    }
}

// MARK: - Helpers

private func tapDirection(
    x: CGFloat,
    progression: ReadiumNavigator.ReadingProgression = .ltr,
    width: CGFloat = 800
) -> EPUBEdgeSwipeDirection? {
    EPUBEdgeSwipePolicy.tapDirection(atX: x, width: width, readingProgression: progression)
}

private func direction(
    _ translation: CGPoint,
    progression: ReadiumNavigator.ReadingProgression = .ltr,
    backwardEdge: Bool = false,
    forwardEdge: Bool = false
) -> EPUBEdgeSwipeDirection? {
    EPUBEdgeSwipePolicy.direction(
        for: translation,
        readingProgression: progression,
        backwardEdgeReached: backwardEdge,
        forwardEdgeReached: forwardEdge
    )
}
