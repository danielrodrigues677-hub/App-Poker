import XCTest
@testable import GameEngine

final class HandRankTests: XCTestCase {
    private func c(_ rank: Rank, _ suit: Suit) -> Card {
        Card(rank: rank, suit: suit)
    }

    func testRoyalFlushBateQuadra() {
        let royal = [
            c(.ace, .spades), c(.king, .spades), c(.queen, .spades),
            c(.jack, .spades), c(.ten, .spades),
        ]
        let quads = [
            c(.nine, .hearts), c(.nine, .diamonds), c(.nine, .clubs),
            c(.nine, .spades), c(.two, .hearts),
        ]
        let a = HandEvaluator.evaluateFive(royal)
        let b = HandEvaluator.evaluateFive(quads)
        XCTAssertEqual(a.category, .straightFlush)
        XCTAssertEqual(b.category, .fourOfAKind)
        XCTAssertGreaterThan(a, b)
    }

    func testWheelStraight() {
        let wheel = [
            c(.ace, .clubs), c(.two, .diamonds), c(.three, .hearts),
            c(.four, .spades), c(.five, .clubs),
        ]
        let rank = HandEvaluator.evaluateFive(wheel)
        XCTAssertEqual(rank.category, .straight)
        XCTAssertEqual(rank.tiebreakers.first, 5)
    }

    func testParVenceHighCard() {
        let pair = [
            c(.king, .clubs), c(.king, .diamonds), c(.three, .hearts),
            c(.eight, .spades), c(.two, .clubs),
        ]
        let high = [
            c(.ace, .clubs), c(.queen, .diamonds), c(.jack, .hearts),
            c(.nine, .spades), c(.seven, .clubs),
        ]
        XCTAssertGreaterThan(HandEvaluator.evaluateFive(pair), HandEvaluator.evaluateFive(high))
    }

    func testBestOfSevenEscolheFlush() {
        let cards = [
            c(.ace, .hearts), c(.king, .hearts), // hole
            c(.two, .hearts), c(.seven, .hearts), c(.nine, .hearts),
            c(.three, .clubs), c(.queen, .diamonds),
        ]
        let best = HandEvaluator.bestHand(from: cards)
        XCTAssertEqual(best.category, .flush)
    }

    func testFullHouseOrdenacao() {
        let fh = [
            c(.ten, .clubs), c(.ten, .diamonds), c(.ten, .hearts),
            c(.four, .spades), c(.four, .clubs),
        ]
        let trips = [
            c(.ace, .clubs), c(.ace, .diamonds), c(.ace, .hearts),
            c(.king, .spades), c(.two, .clubs),
        ]
        XCTAssertGreaterThan(HandEvaluator.evaluateFive(fh), HandEvaluator.evaluateFive(trips))
    }
}
