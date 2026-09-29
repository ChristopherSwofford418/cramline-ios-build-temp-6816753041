import CramlineCore
import Foundation

struct AIPlannerClient {
  enum ClientError: LocalizedError {
    case notConfigured
    case consentRequired
    case invalidResponse
    case serviceUnavailable

    var errorDescription: String? {
      switch self {
      case .notConfigured:
        return "AI planning is not configured in this build. The on-device planner is available."
      case .consentRequired:
        return "Review and approve the fields before sending this planning request."
      case .invalidResponse: return "The AI returned an invalid draft. Nothing was saved."
      case .serviceUnavailable:
        return "AI planning is temporarily unavailable. The on-device planner still works."
      }
    }
  }

  private let baseURL: URL?
  private let session: URLSession

  init(baseURL: URL? = AppEnvironment.aiBaseURL) {
    self.baseURL = baseURL
    let configuration = URLSessionConfiguration.ephemeral
    configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
    configuration.urlCache = nil
    configuration.httpCookieStorage = nil
    configuration.httpShouldSetCookies = false
    configuration.waitsForConnectivity = false
    session = URLSession(configuration: configuration)
  }

  func makeDraft(_ request: AIPlanningRequest) async throws -> AIPlanningResponse {
    guard request.consentAcknowledged else { throw ClientError.consentRequired }
    guard let baseURL else { throw ClientError.notConfigured }
    var urlRequest = URLRequest(url: baseURL.appendingPathComponent("v1/plan"))
    urlRequest.httpMethod = "POST"
    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
    urlRequest.setValue("no-store", forHTTPHeaderField: "Cache-Control")
    urlRequest.timeoutInterval = 30
    urlRequest.httpBody = try JSONEncoder.cramline.encode(request)

    do {
      let (data, response) = try await session.data(for: urlRequest)
      guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
        throw ClientError.serviceUnavailable
      }
      return try JSONDecoder.cramline.decode(AIPlanningResponse.self, from: data)
    } catch let error as ClientError {
      throw error
    } catch is DecodingError {
      throw ClientError.invalidResponse
    } catch {
      throw ClientError.serviceUnavailable
    }
  }
}

extension JSONEncoder {
  fileprivate static var cramline: JSONEncoder {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    return encoder
  }
}

extension JSONDecoder {
  fileprivate static var cramline: JSONDecoder {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return decoder
  }
}
