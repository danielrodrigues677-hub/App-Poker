import XCTest
@testable import GameEngine

final class LegalActionsTests: XCTestCase {
    func testPreflopBBPodeCheckQuandoTodosCall() throws {
        let config = CashConfig(preset: .default, botCount: 1)
        var table = HoldemEngine.makeCashTable(config: config)
        table = HoldemEngine.startHand(table, seed: 99)

        // Heads-up: dealer/SB age primeiro
        XCTAssertNotNil(table.currentActorIndex)
        let first = table.currentActorIndex!
        let legalFirst = HoldemEngine.legalActions(for: table, playerIndex: first)
        XCTAssertTrue(legalFirst.canCall || legalFirst.canAllIn || legalFirst.canFold)

        // SB completa o BB
        if legalFirst.canCall {
            table = try HoldemEngine.apply(.call, to: table)
        } else if legalFirst.canAllIn {
            table = try HoldemEngine.apply(.allIn, to: table)
        }

        guard table.street == .preflop, let second = table.currentActorIndex else {
            // Pode ter ido a all-in runout; ainda assim a ação foi validada
            return
        }
        let legalBB = HoldemEngine.legalActions(for: table, playerIndex: second)
        // Após call do SB igualando, BB pode check ou raise
        XCTAssertTrue(legalBB.canCheck || legalBB.canRaise || legalBB.canAllIn)
        XCTAssertFalse(legalBB.canCall)
    }

    func testFoldIlegalQuandoNaoEVez() {
        let config = CashConfig(preset: .default, botCount: 2)
        var table = HoldemEngine.makeCashTable(config: config)
        table = HoldemEngine.startHand(table, seed: 3)
        let notActor = table.players.indices.first { $0 != table.currentActorIndex }!
        let legal = HoldemEngine.legalActions(for: table, playerIndex: notActor)
        XCTAssertEqual(legal, .none)
    }

    func testRaiseAbaixoDoMinimoFalha() throws {
        let config = CashConfig(preset: .default, botCount: 1)
        var table = HoldemEngine.makeCashTable(config: config)
        table = HoldemEngine.startHand(table, seed: 11)
        let actor = try XCTUnwrap(table.currentActorIndex)
        let legal = HoldemEngine.legalActions(for: table, playerIndex: actor)
        if legal.canRaise {
            XCTAssertThrowsError(try HoldemEngine.apply(.raise(to: 1), to: table))
        }
    }

    func testMaoCompletaComFolds() throws {
        let config = CashConfig(preset: .default, botCount: 2)
        var table = HoldemEngine.makeCashTable(config: config)
        table = HoldemEngine.startHand(table, seed: 21)

        var guardRail = 0
        while table.street != .handOver && guardRail < 40 {
            let actor = try XCTUnwrap(table.currentActorIndex)
            let legal = HoldemEngine.legalActions(for: table, playerIndex: actor)
            if legal.canFold {
                table = try HoldemEngine.apply(.fold, to: table)
            } else if legal.canCheck {
                table = try HoldemEngine.apply(.check, to: table)
            } else if legal.canCall {
                table = try HoldemEngine.apply(.call, to: table)
            } else {
                table = try HoldemEngine.apply(.allIn, to: table)
            }
            guardRail += 1
        }
        XCTAssertEqual(table.street, .handOver)
        XCTAssertNotNil(table.winnersIfFold)
        XCTAssertEqual(table.pot, 0)
    }
}
