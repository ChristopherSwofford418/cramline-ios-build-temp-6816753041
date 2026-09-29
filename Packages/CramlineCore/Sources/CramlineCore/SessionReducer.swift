import Foundation

public enum SessionAction: Equatable, Sendable {
  case scheduled
  case shieldApplied
  case authorizationLost
  case pauseRequested(now: Date, duration: TimeInterval)
  case resume(now: Date)
  case ended(now: Date, checkIn: LocalCheckIn?)
  case stateCouldNotBeVerified
}

public enum SessionReducer {
  public static func reduce(_ session: SessionState, action: SessionAction) -> SessionState {
    var next = session
    switch action {
    case .scheduled:
      next.state = .scheduled
    case .shieldApplied:
      guard next.endedAt == nil else { return next }
      next.state = .active
      next.emergencyPauseUntil = nil
    case .authorizationLost:
      next.state = .authorizationNeeded
      next.emergencyPauseUntil = nil
    case let .pauseRequested(now, duration):
      guard next.endedAt == nil else { return next }
      next.state = .paused
      next.emergencyPauseUntil = min(now.addingTimeInterval(max(0, duration)), next.plannedEnd)
    case let .resume(now):
      guard next.endedAt == nil else { return next }
      if now < next.plannedEnd {
        next.state = .active
        next.emergencyPauseUntil = nil
      } else {
        next.state = .ended
        next.endedAt = now
      }
    case let .ended(now, checkIn):
      next.state = .ended
      next.endedAt = now
      next.emergencyPauseUntil = nil
      next.localCheckIn = checkIn
    case .stateCouldNotBeVerified:
      guard next.endedAt == nil else { return next }
      next.state = .unknown
    }
    return next
  }
}
