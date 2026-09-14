import Foundation

public enum FoldEvent: String, Codable, CaseIterable, Sendable {
    case opened, closed
    public var title: String { self == .opened ? "Opening" : "Closing" }
}

/// App-defined thresholds, NOT Apple hardware specifications.
/// First observation establishes a silent baseline. Opening means leaving the
/// closed position, not reaching 180 degrees. Deadband + dwell prevent chatter.
public struct FoldDetector: Sendable {
    public private(set) var state: FoldEvent?
    public private(set) var deadline: Double?
    private let closeAngle: Double
    private let openAngle: Double
    private let dwell: Double
    private var candidate: FoldEvent?
    private var latestAngle: Double?
    private var latestTime: Double?

    public init(closeAngle: Double = 8, openAngle: Double = 22, dwell: Double = 0.08) {
        precondition(closeAngle.isFinite && openAngle.isFinite && dwell.isFinite)
        precondition(0 <= closeAngle && closeAngle < openAngle && openAngle <= 180 && dwell >= 0)
        self.closeAngle = closeAngle
        self.openAngle = openAngle
        self.dwell = dwell
    }

    public mutating func reset() {
        state = nil; deadline = nil; candidate = nil; latestAngle = nil; latestTime = nil
    }

    public mutating func ingest(angle: Double, at time: Double) -> FoldEvent? {
        guard angle.isFinite, time.isFinite, (0...180).contains(angle) else {
            cancelCandidate(); return nil
        }
        guard latestTime.map({ time >= $0 }) ?? true else {
            cancelCandidate(); return nil
        }
        latestTime = time
        latestAngle = angle
        let target: FoldEvent?
        if angle <= closeAngle { target = .closed }
        else if angle >= openAngle { target = .opened }
        else { target = nil }
        guard let target else { cancelCandidate(); return nil }
        guard let state else {
            self.state = target
            cancelCandidate()
            return nil
        }
        guard target != state else { cancelCandidate(); return nil }
        if candidate != target {
            candidate = target
            deadline = time + dwell
        }
        guard let deadline, time + 0.000_000_001 >= deadline else { return nil }
        self.state = target
        cancelCandidate()
        return target
    }

    /// Called by a cancellable one-shot timer. Endpoint-only callbacks must work
    /// even when the OS sends no further samples after the hinge stops moving.
    public mutating func advance(to time: Double) -> FoldEvent? {
        guard deadline != nil, let latestAngle else { return nil }
        return ingest(angle: latestAngle, at: time)
    }

    private mutating func cancelCandidate() { candidate = nil; deadline = nil }
}
