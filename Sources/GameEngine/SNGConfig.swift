import Foundation

/// Formato Sit & Go de 1 mesa (V1: sem MTT).
public enum SNGFormat: String, Codable, Sendable, CaseIterable, Identifiable {
    case sixMax = "6-max"
    case tenMax = "10-max"

    public var id: String { rawValue }

    public var seatCount: Int {
        switch self {
        case .sixMax: return 6
        case .tenMax: return 10
        }
    }

    public var botCount: Int { seatCount - 1 }

    public var rotuloPT: String {
        switch self {
        case .sixMax: return "Sit & Go 6-max"
        case .tenMax: return "Sit & Go 10-max"
        }
    }
}

public struct SNGConfig: Codable, Sendable, Equatable {
    public var format: SNGFormat
    public var startingStack: Int
    public var schedule: [BlindLevel]

    public var botCount: Int { format.botCount }
    public var seatCount: Int { format.seatCount }

    public init(
        format: SNGFormat = .sixMax,
        startingStack: Int = 1_500,
        schedule: [BlindLevel] = BlindSchedule.padrao
    ) {
        self.format = format
        self.startingStack = max(100, startingStack)
        self.schedule = schedule.isEmpty ? BlindSchedule.padrao : schedule
    }

    public var nivelInicial: BlindLevel {
        BlindSchedule.level(at: 0, in: schedule)
    }
}
