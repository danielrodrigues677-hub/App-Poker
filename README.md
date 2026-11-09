# App Poker

App nativo de **Texas Hold'em No-Limit** para iPhone, focado em iniciantes: cash e Sit & Go contra bots, em **português (PT-BR)**, **100% grátis**, sem dinheiro real e sem multiplayer.

## Escopo atual (Fase B)

- Motor Hold'em puro (`GameEngine`) + bots amigáveis (`BotAI`) + sessões cash/SNG (`TableSession`)
- Sit & Go 1 mesa (6–max / 10–max), blind schedule com timer, eliminação até 1 vencedor + tela de resultado
- Coach ligado no 1º uso (toggle em Ajustes), tutorial e glossário PT-BR
- Replay da última mão (streets + ações)
- Persistência local de preferências, sessões e replay (`UserDefaults` via módulo `Persistence`)
- UI SwiftUI: Home → Cash / Torneio / Ajustes
- Sem MTT, multiplayer ou dinheiro real

## Estrutura

```
AppPoker/                  (Swift Package)
├── Package.swift
├── Sources/
│   ├── GameEngine/        regras, baralho, pot, showdown, SNG/blinds, hand history
│   ├── BotAI/             heurística “amigável”
│   ├── TableSession/      cash + Sit & Go
│   ├── Coach/             dicas, tutorial, glossário
│   └── Persistence/       preferências e histórico local
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

Os testes cobrem baralho/deal, ações legais, ranking, sessão cash, Sit & Go/blinds, coach prefs e persistência.

## Requisitos

- Xcode 15+ / iOS 17+
- Swift 5.9+

## Fora do V1

Multiplayer, dinheiro real, MTT, variantes (Omaha etc.), UI em inglês, IAP.
