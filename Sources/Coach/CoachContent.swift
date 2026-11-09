import Foundation
import GameEngine

/// Conteúdo estático do coach / tutorial / glossário (PT-BR).
public enum CoachContent {
    public static let tutorialPaginas: [TutorialPage] = [
        TutorialPage(
            titulo: "Objetivo da mão",
            corpo: "Forme a melhor mão de 5 cartas combinando suas 2 cartas fechadas com as comunitárias. Ou faça os outros desistirem e leve o pote."
        ),
        TutorialPage(
            titulo: "Blinds",
            corpo: "Small blind e big blind são apostas forçadas que começam a mão. No cash os blinds são fixos; no Sit & Go eles sobem com o tempo."
        ),
        TutorialPage(
            titulo: "Rodadas de aposta",
            corpo: "Pré-flop → Flop (3 cartas) → Turn (1) → River (1). Em cada street você pode desistir, passar, pagar, aumentar ou ir all-in."
        ),
        TutorialPage(
            titulo: "Coach",
            corpo: "Com o coach ligado, você recebe dicas curtas antes de agir. Dá para desligar depois em Ajustes. O app é 100% grátis e só em português."
        ),
    ]

    public static let glossario: [GlossaryEntry] = [
        GlossaryEntry(termo: "Pote", definicao: "Total de fichas apostadas na mão atual."),
        GlossaryEntry(termo: "Side pot", definicao: "Pote extra quando alguém está all-in e outros continuam apostando."),
        GlossaryEntry(termo: "All-in", definicao: "Apostar todas as fichas restantes."),
        GlossaryEntry(termo: "BB (big blind)", definicao: "Blind maior da mão; unidade comum para medir stacks e aumentos."),
        GlossaryEntry(termo: "SB (small blind)", definicao: "Blind menor, posto antes do big blind."),
        GlossaryEntry(termo: "Fold", definicao: "Desistir da mão e abrir mão das cartas."),
        GlossaryEntry(termo: "Call", definicao: "Pagar o valor necessário para igualar a aposta atual."),
        GlossaryEntry(termo: "Raise", definicao: "Aumentar a aposta além do valor atual."),
        GlossaryEntry(termo: "Check", definicao: "Passar a vez sem apostar, só quando ninguém aumentou nesta street."),
        GlossaryEntry(termo: "Sit & Go", definicao: "Torneio de 1 mesa que começa assim que os assentos enchem; sobe blinds até restar 1 vencedor."),
    ]
}

public struct TutorialPage: Identifiable, Sendable, Equatable {
    public var id: String { titulo }
    public let titulo: String
    public let corpo: String

    public init(titulo: String, corpo: String) {
        self.titulo = titulo
        self.corpo = corpo
    }
}

public struct GlossaryEntry: Identifiable, Sendable, Equatable {
    public var id: String { termo }
    public let termo: String
    public let definicao: String

    public init(termo: String, definicao: String) {
        self.termo = termo
        self.definicao = definicao
    }
}

/// Gera dicas contextuais simples (não joga por você).
public struct CoachAdvisor: Sendable {
    public init() {}

    public func tip(for state: TableState, legal: LegalActions) -> String? {
        guard let idx = state.humanIndex, state.currentActorIndex == idx else { return nil }
        let toCall = legal.callAmount
        let stack = state.players[idx].stack
        let hole = state.players[idx].holeCards

        if state.street == .preflop, hole.count == 2 {
            let a = hole[0]
            let b = hole[1]
            if a.rank == b.rank {
                return "Par de bolso: em geral vale pagar ou aumentar, especialmente se for par alto."
            }
            if max(a.rank.rawValue, b.rank.rawValue) >= 13, toCall <= state.bigBlind * 3 {
                return "Carta alta forte. Considere pagar ou um aumento pequeno se a mesa estiver passiva."
            }
            if toCall > state.bigBlind * 6, stack > toCall {
                return "Aumento grande pré-flop: mãos médias costumam ser fold. Só continue com força real."
            }
        }

        if legal.canCheck {
            return "Ninguém apostou: você pode passar de graça ou aumentar para pressionar."
        }

        if toCall > 0 {
            let potOdds = Double(toCall) / Double(max(1, state.pot + toCall))
            if potOdds > 0.4 {
                return "Call caro em relação ao pote. Só pague se achar que está na frente ou com ótimo draw."
            }
            return "Call relativamente barato. Avalie sua mão e quantos oponentes ainda estão na mão."
        }

        if legal.canAllIn, stack <= state.bigBlind * 8 {
            return "Stack curto (≤ 8 BB): all-in ou fold costuma ser mais simples do que calls médios."
        }

        return "Lembre: posição e tamanho do pote importam tanto quanto as cartas."
    }
}
