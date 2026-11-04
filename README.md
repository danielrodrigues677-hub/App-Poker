# App Poker

App nativo de **Texas Hold'em No-Limit** para iPhone, focado em iniciantes: cash e (em breve) Sit & Go contra bots, em **português (PT-BR)**, **100% grátis**, sem dinheiro real e sem multiplayer.

## Escopo atual (Fase A)

- Motor Hold'em puro (`GameEngine`) + bots amigáveis (`BotAI`) + sessão cash (`TableSession`)
- UI SwiftUI mínima: Home → Cash (presets 1/2, 2/5, 5/10 @ 100 BB) → mesa jogável vs bots
- Torneio: placeholder “em breve” (Fase B)
- Sem coach/tutorial completo, sem persistência de histórico, sem MTT

## Estrutura

```
AppPoker/                  (Swift Package)
├── Package.swift
├── Sources/
│   ├── GameEngine/        regras, baralho, pot, showdown
│   ├── BotAI/             heurística “amigável”
│   └── TableSession/      orquestra cash vs bots
├── Tests/GameEngineTests/
└── App/AppPoker/          app SwiftUI (abrir no Xcode no Mac)
```

## Abrir no Xcode (Mac)

1. Clone o repositório e abra `Package.swift` no Xcode **ou** use o gerador abaixo.
2. Para o app iOS completo:
   - **Opção A (recomendada):** `brew install xcodegen` e rode `./Scripts/generate-app.sh`, depois abra `AppPoker.xcodeproj`
   - **Opção B:** File → New → Project → App (SwiftUI, iOS 17+), adicione o pacote local (este diretório) e inclua os fontes de `App/AppPoker/`
3. Selecione o scheme **AppPoker** / destino iPhone Simulator e rode ⌘R

O pacote em si (engine + testes) também abre direto via `Package.swift`.

## Testes

No Mac (Xcode ou Terminal):

```bash
swift test
```

No Xcode: scheme do pacote → Product → Test (⌘U).

Os testes cobrem baralho/deal, ações legais, ranking de mãos e uma sessão cash vs bots.

## Requisitos

- Xcode 15+ / iOS 17+
- Swift 5.9+

## Fora do V1 / Fase A

Multiplayer, dinheiro real, MTT, variantes (Omaha etc.), UI em inglês, IAP.
