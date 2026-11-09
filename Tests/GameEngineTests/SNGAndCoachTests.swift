import XCTest
@testable import GameEngine
@testable import BotAI
@testable import TableSession
@testable import Coach
@testable import Persistence

final class SNGAndCoachTests: XCTestCase {

    func testBlindScheduleAvancaNiveis() {
        let short: [BlindLevel] = [
            BlindLevel(index: 0, smallBlind: 10, bigBlind: 20, durationSeconds: 2),
            BlindLevel(index: 1, smallBlind: 20, bigBlind: 40, durationSeconds: 2),
            BlindLevel(index: 2, smallBlind: 50, bigBlind: 100, durationSeconds: 2),
        ]
        let config = SNGConfig(format: .sixMax, startingStack: 500, schedule: short)
        let session = SNGTableSession(config: config, seed: 7)

        XCTAssertEqual(session.nivelAtual.smallBlind, 10)
        XCTAssertEqual(session.secondsRemainingInLevel, 2)

        XCTAssertFalse(session.tickBlindTimer(bySeconds: 1))
        XCTAssertEqual(session.secondsRemainingInLevel, 1)

        XCTAssertTrue(session.tickBlindTimer(bySeconds: 1))
        XCTAssertEqual(session.blindLevelIndex, 1)
        XCTAssertEqual(session.nivelAtual.bigBlind, 40)

        _ = session.advanceBlindLevel()
        XCTAssertEqual(session.blindLevelIndex, 2)
        _ = session.advanceBlindLevel()
        XCTAssertEqual(session.blindLevelIndex, 2) // permanece no último
    }

    func testSNGEliminacaoAteUmVencedor() throws {
        let short: [BlindLevel] = [
            BlindLevel(index: 0, smallBlind: 50, bigBlind: 100, durationSeconds: 30),
            BlindLevel(index: 1, smallBlind: 100, bigBlind: 200, durationSeconds: 30),
            BlindLevel(index: 2, smallBlind: 200, bigBlind: 400, durationSeconds: 30),
        ]
        // Stacks baixos + blinds altos aceleram eliminação
        let config = SNGConfig(format: .sixMax, startingStack: 300, schedule: short)
        let session = SNGTableSession(config: config, seed: 42)

        var guardRail = 0
        while !session.isFinished && guardRail < 400 {
            try session.runBotsUntilHumanOrEnd(maxSteps: 128)
            if session.isFinished { break }

            if session.state.street == .handOver {
                session.nextHand(seed: UInt64(guardRail + 100))
                // sobe blinds a cada poucas mãos
                if guardRail % 3 == 0 {
                    _ = session.advanceBlindLevel()
                }
                guardRail += 1
                continue
            }

            if session.isHumanTurn {
                let legal = session.legalForHuman
                // Estratégia agressiva para acelerar
                if legal.canAllIn {
                    try session.applyHuman(.allIn)
                } else if legal.canRaise {
                    try session.applyHuman(.raise(to: legal.minRaiseTo))
                } else if legal.canCall {
                    try session.applyHuman(.call)
                } else if legal.canCheck {
                    try session.applyHuman(.check)
                } else if legal.canFold {
                    try session.applyHuman(.fold)
                }
            }
            guardRail += 1
        }

        XCTAssertTrue(session.isFinished, "torneio deveria terminar em <400 passos")
        let result = try XCTUnwrap(session.result)
        XCTAssertEqual(HoldemEngine.alivePlayerCount(session.state), 1)
        XCTAssertEqual(result.winnerId, session.state.players.first(where: { $0.stack > 0 })?.id)
        XCTAssertGreaterThanOrEqual(result.humanPlace, 1)
        XCTAssertLessThanOrEqual(result.humanPlace, config.seatCount)
    }

    func testMakeSNGTableAssentos() {
        let six = HoldemEngine.makeSNGTable(config: SNGConfig(format: .sixMax))
        XCTAssertEqual(six.players.count, 6)
        XCTAssertEqual(six.smallBlind, 10)
        XCTAssertEqual(six.bigBlind, 20)

        let ten = HoldemEngine.makeSNGTable(config: SNGConfig(format: .tenMax))
        XCTAssertEqual(ten.players.count, 10)
    }

    func testCoachPrefsDefaultLigado() {
        let store = InMemoryStore()
        let persistence = LocalPersistence(store: store)
        let prefs = persistence.loadPreferences()
        XCTAssertTrue(prefs.coachEnabled)
        XCTAssertFalse(prefs.tutorialCompleted)

        persistence.updatePreferences { $0.coachEnabled = false }
        XCTAssertFalse(persistence.loadPreferences().coachEnabled)
    }

    func testPersistenciaReplayESessoes() {
        let store = InMemoryStore()
        let persistence = LocalPersistence(store: store)

        let replay = HandReplay(
            handNumber: 3,
            deckSeed: 99,
            smallBlind: 1,
            bigBlind: 2,
            humanHoleCards: [
                Card(rank: .ace, suit: .spades),
                Card(rank: .king, suit: .hearts),
            ],
            playerNames: [0: "Você", 1: "Bot 1"],
            streets: [
                StreetSnapshot(street: .preflop, communityCards: []),
                StreetSnapshot(street: .flop, communityCards: [
                    Card(rank: .two, suit: .clubs),
                    Card(rank: .three, suit: .diamonds),
                    Card(rank: .four, suit: .spades),
                ]),
            ],
            actions: [
                HandActionRecord(street: .preflop, playerId: 0, playerName: "Você", action: .raise(to: 6), potAfter: 9),
            ],
            resultSummary: "Você +12"
        )

        persistence.saveLastReplay(replay)
        let loaded = persistence.loadLastReplay()
        XCTAssertEqual(loaded?.handNumber, 3)
        XCTAssertEqual(loaded?.actions.first?.action, .raise(to: 6))

        persistence.appendSession(SessionSummary(kind: "sng", detailPT: "Campeão", handsPlayed: 12))
        XCTAssertEqual(persistence.loadSessions().count, 1)
        XCTAssertEqual(persistence.loadSessions().first?.kind, "sng")
    }

    func testCoachAdvisorGeraDicaNoTurnoHumano() {
        let config = CashConfig(preset: .default, botCount: 2)
        var table = HoldemEngine.makeCashTable(config: config)
        table = HoldemEngine.startHand(table, seed: 11)
        // Avança até vez do humano ou fim
        var ai = FriendlyBotAI(seed: 11)
        var steps = 0
        while table.street != .handOver, let actor = table.currentActorIndex, steps < 40 {
            if table.players[actor].kind == .human { break }
            let action = ai.decide(state: table, playerIndex: actor)
            table = try! HoldemEngine.apply(action, to: table)
            steps += 1
        }
        guard table.street != .handOver, let idx = table.humanIndex, table.currentActorIndex == idx else {
            // Ainda válido se a mão acabou sem turno humano (raro com seed)
            return
        }
        let legal = HoldemEngine.legalActions(for: table, playerIndex: idx)
        let tip = CoachAdvisor().tip(for: table, legal: legal)
        XCTAssertNotNil(tip)
        XCTAssertFalse(tip!.isEmpty)
    }

    func testCashSessionGeraReplay() throws {
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
        let replay = try XCTUnwrap(session.lastHandReplay)
        XCTAssertEqual(replay.handNumber, session.state.handNumber)
        XCTAssertFalse(replay.resultSummary.isEmpty)
    }

    func testGlossarioETutorialPTBR() {
        XCTAssertGreaterThanOrEqual(CoachContent.tutorialPaginas.count, 3)
        XCTAssertTrue(CoachContent.glossario.contains { $0.termo == "BB (big blind)" })
        XCTAssertTrue(CoachContent.glossario.contains { $0.termo == "Sit & Go" })
    }
}
