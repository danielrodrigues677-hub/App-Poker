import XCTest
@testable import GameEngine

final class DealTests: XCTestCase {
    func testDeckTem52CartasUnicas() {
        var deck = Deck(seed: 42)
        var seen = Set<Card>()
        while let c = deck.deal() {
            XCTAssertFalse(seen.contains(c))
            seen.insert(c)
        }
        XCTAssertEqual(seen.count, 52)
        XCTAssertEqual(deck.remainingCount, 0)
    }

    func testShuffleSeedavelEReproduzivel() {
        var a = Deck(seed: 12345)
        var b = Deck(seed: 12345)
        let cardsA = a.deal(10)
        let cardsB = b.deal(10)
        XCTAssertEqual(cardsA, cardsB)
    }

    func testStartHandDistribuiDuasCartasEBlinds() {
        let config = CashConfig(preset: .default, botCount: 3)
        var table = HoldemEngine.makeCashTable(config: config)
        table = HoldemEngine.startHand(table, seed: 7)

        XCTAssertEqual(table.street, .preflop)
        XCTAssertEqual(table.handNumber, 1)
        let ativos = table.players.filter { !$0.isFolded }
        XCTAssertEqual(ativos.count, 4)
        for p in ativos {
            XCTAssertEqual(p.holeCards.count, 2)
        }
        // Pot mínimo = SB + BB (1+2) nos presets default
        XCTAssertGreaterThanOrEqual(table.pot, table.smallBlind + table.bigBlind)
        XCTAssertNotNil(table.currentActorIndex)
    }

    func testCashPresetsBuyIn100BB() {
        for preset in BlindPreset.all {
            XCTAssertEqual(preset.buyIn, preset.bigBlind * 100)
        }
    }
}
