import XCTest
@testable import GameEngine
@testable import BotAI
@testable import TableSession

final class BotAndSessionTests: XCTestCase {
    func testBotSempreRetornaAcaoLegal() {
        let config = CashConfig(preset: .default, botCount: 2)
        var table = HoldemEngine.makeCashTable(config: config)
        table = HoldemEngine.startHand(table, seed: 55)
        var ai = FriendlyBotAI(seed: 55)

        var steps = 0
        while table.street != .handOver && steps < 80 {
            let actor = try! XCTUnwrap(table.currentActorIndex)
            let legal = HoldemEngine.legalActions(for: table, playerIndex: actor)
            let action: PlayerAction
            if table.players[actor].kind == .bot {
                action = ai.decide(state: table, playerIndex: actor)
            } else if legal.canCheck {
                action = .check
            } else if legal.canCall {
                action = .call
            } else if legal.canFold {
                action = .fold
            } else {
                action = .allIn
            }
            // all-in sempre que stack > 0 na legalidade do motor
            XCTAssertNoThrow(try {
                table = try HoldemEngine.apply(action, to: table)
            }())
            steps += 1
        }
        XCTAssertEqual(table.street, .handOver)
    }

    func testSessaoCashRodaAteFimComHumanoPassivo() throws {
        let session = CashTableSession(config: CashConfig(preset: .default, botCount: 2), seed: 101)
        try session.runBotsUntilHumanOrEnd()

        var guardRail = 0
        while session.state.street != .handOver && guardRail < 60 {
            if session.isHumanTurn {
                let legal = session.legalForHuman
                if legal.canCheck {
                    try session.applyHuman(.check)
                } else if legal.canCall {
                    try session.applyHuman(.call)
                } else if legal.canFold {
                    try session.applyHuman(.fold)
                } else {
                    try session.applyHuman(.allIn)
                }
            }
            try session.runBotsUntilHumanOrEnd()
            guardRail += 1
        }
        XCTAssertEqual(session.state.street, .handOver)
        XCTAssertEqual(session.state.pot, 0)
    }
}
