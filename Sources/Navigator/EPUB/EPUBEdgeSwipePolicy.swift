//
//  Copyright 2026 Readium Foundation. All rights reserved.
//  Use of this source code is governed by the BSD-style license
//  available in the top-level LICENSE file of the project.
//

import CoreGraphics
import ReadiumShared

/// Direction of a resource navigation requested by an edge swipe or tap.
enum EPUBEdgeSwipeDirection: Equatable {
    /// Move to the next resource in the reading progression.
    case forward
    /// Move to the previous resource in the reading progression.
    case backward
}

/// Decides when a horizontal drag or an edge tap turns to the previous or
/// next resource, while page turns are disabled while scrolling
/// (`disablePageTurnsWhileScrolling`).
///
/// A navigation is only honored when the end of the resource matching its
/// direction is reached: the start of the content for backward, its end for
/// forward. The edges are anticipatory: navigation unlocks up to
/// `edgeUnlockHeightFactor` viewports before actually reaching the end.
/// Content no taller than `shortContentUnlockHeightFactor` viewports can be
/// left in both directions at any position. This prevents accidental jumps
/// between resources in the middle of a chapter.
enum EPUBEdgeSwipePolicy {
    /// Height of the unlock zone in front of each vertical edge of the
    /// content, as a multiple of the viewport height.
    static let edgeUnlockHeightFactor: CGFloat = 0.75

    /// Maximum content height which can be left in both directions at any
    /// scroll position, as a multiple of the viewport height.
    static let shortContentUnlockHeightFactor: CGFloat = 2

    /// Minimum horizontal edge size which triggers a page turn on tap, in
    /// points, mirroring the defaults of `DirectionalNavigationAdapter`.
    static let tapMinimumEdgeSize: CGFloat = 80

    /// Percentage of the viewport width used as the horizontal edge size for
    /// taps, mirroring the defaults of `DirectionalNavigationAdapter`.
    static let tapEdgeThresholdPercent: CGFloat = 0.3

    /// Minimum horizontal translation in points to trigger the navigation for
    /// a slow swipe.
    static let minimumTranslation: CGFloat = 60

    /// Minimum horizontal velocity in points per second to trigger the
    /// navigation for a short but fast swipe.
    static let minimumVelocity: CGFloat = 500

    /// Whether a vertical scroll offset is within the unlock zone of the top
    /// edge of the content, including when the content is short enough to be
    /// left in both directions at any position.
    static func isNearTop(offset: CGFloat, inset: CGFloat, contentSize: CGFloat, viewportSize: CGFloat) -> Bool {
        isShortContent(contentSize: contentSize, viewportSize: viewportSize)
            || offset <= -inset + viewportSize * edgeUnlockHeightFactor
    }

    /// Whether a vertical scroll offset is within the unlock zone of the
    /// bottom edge of the content, including when the content is short enough
    /// to be left in both directions at any position.
    static func isNearBottom(offset: CGFloat, inset: CGFloat, contentSize: CGFloat, viewportSize: CGFloat) -> Bool {
        isShortContent(contentSize: contentSize, viewportSize: viewportSize)
            || offset >= contentSize - viewportSize + inset - viewportSize * edgeUnlockHeightFactor
    }

    /// Whether the content is short enough to be left in both directions at
    /// any scroll position.
    private static func isShortContent(contentSize: CGFloat, viewportSize: CGFloat) -> Bool {
        contentSize <= viewportSize * shortContentUnlockHeightFactor
    }

    /// Returns the navigation direction requested by a tap at the horizontal
    /// coordinate `x` of a viewport of the given `width`, if the tap lands in
    /// one of the edge zones, mirroring the geometry of
    /// `DirectionalNavigationAdapter`.
    static func tapDirection(
        atX x: CGFloat,
        width: CGFloat,
        readingProgression: ReadingProgression
    ) -> EPUBEdgeSwipeDirection? {
        let edge = max(tapMinimumEdgeSize, tapEdgeThresholdPercent * width)
        let atRightEdge = x >= width - edge
        let atLeftEdge = x <= edge

        // The forward edge is the right edge in LTR, and the left edge in
        // RTL. In the narrow overlapping zones, forward is preferred.
        switch readingProgression {
        case .ltr:
            if atRightEdge {
                return .forward
            }
            if atLeftEdge {
                return .backward
            }
        case .rtl:
            if atLeftEdge {
                return .forward
            }
            if atRightEdge {
                return .backward
            }
        }
        return nil
    }

    /// Returns the navigation direction requested by `translation`, if the
    /// drag should be recognized as an edge swipe.
    ///
    /// The drag must be horizontal-dominant, and the unlock zone matching the
    /// swipe direction must be reached. The edges are those of the resource's
    /// scrollable content: the vertical top and bottom in scroll mode, or the
    /// internal page boundaries in a fixed-layout spread.
    static func direction(
        for translation: CGPoint,
        readingProgression: ReadingProgression,
        backwardEdgeReached: Bool,
        forwardEdgeReached: Bool
    ) -> EPUBEdgeSwipeDirection? {
        guard
            abs(translation.x) > abs(translation.y),
            translation.x != 0
        else {
            return nil
        }

        // In LTR, swiping to the left moves to the next resource and to the
        // right to the previous one. This is mirrored in RTL.
        let requestsForward = (readingProgression == .ltr) == (translation.x < 0)
        if requestsForward {
            return forwardEdgeReached ? .forward : nil
        } else {
            return backwardEdgeReached ? .backward : nil
        }
    }

    /// Whether the drag ended with enough distance or momentum to trigger the
    /// navigation.
    ///
    /// A drag with a velocity contradicting its translation (e.g. the user
    /// flicked back before releasing) never triggers.
    static func shouldTrigger(translation: CGPoint, velocity: CGPoint) -> Bool {
        guard translation.x != 0 else {
            return false
        }
        if velocity.x != 0, (velocity.x > 0) != (translation.x > 0) {
            return false
        }
        return abs(translation.x) >= minimumTranslation
            || abs(velocity.x) >= minimumVelocity
    }
}
