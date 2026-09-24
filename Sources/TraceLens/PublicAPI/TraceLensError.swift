import Foundation

public enum TraceLensError: Error, LocalizedError {
  case notStarted

  public var errorDescription: String? {
    "O TraceLens ainda não foi iniciado."
  }
}
