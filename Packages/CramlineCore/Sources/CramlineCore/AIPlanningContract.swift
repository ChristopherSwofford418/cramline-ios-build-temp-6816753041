import Foundation

public struct AIPlanningRequest: Codable, Equatable, Sendable {
  public let sprintEndDate: String
  public let broadStudyDomain: BroadStudyDomain?
  public let desiredWeeklyHours: Double
  public let preferredTimes: [PreferredStudyTime]
  public let selfReportedConfidence: Int?
  public let consentAcknowledged: Bool

  public init(
    sprintEndDate: String,
    broadStudyDomain: BroadStudyDomain?,
    desiredWeeklyHours: Double,
    preferredTimes: [PreferredStudyTime],
    selfReportedConfidence: Int?,
    consentAcknowledged: Bool
  ) {
    self.sprintEndDate = sprintEndDate
    self.broadStudyDomain = broadStudyDomain
    self.desiredWeeklyHours = desiredWeeklyHours
    self.preferredTimes = preferredTimes
    self.selfReportedConfidence = selfReportedConfidence
    self.consentAcknowledged = consentAcknowledged
  }

  public static let disclosure =
    "Send this planning request to AI? Block Your Phone to Study will send only the plan details shown here. It will not send selected apps, app activity, messages, social content, browser history, or device identity."
}

public struct AIPlanningResponse: Codable, Equatable, Sendable {
  public let draft: PlanningDraft
  public let modelLabel: String
  public let retainedByCramline: Bool

  public init(draft: PlanningDraft, modelLabel: String, retainedByCramline: Bool = false) {
    self.draft = draft
    self.modelLabel = modelLabel
    self.retainedByCramline = retainedByCramline
  }
}
