# App Poker

App nativo de **Texas Hold'em No-Limit** para iPhone, focado em iniciantes: cash e Sit & Go contra bots, em **português (PT-BR)**, **100% grátis**, sem dinheiro real e sem multiplayer.

## Escopo atual (Fase B + polimento UI)

- Motor Hold'em puro (`GameEngine`) + bots amigáveis (`BotAI`) + sessões cash/SNG (`TableSession`)
- Sit & Go 1 mesa (6–max / 10–max), blind schedule com timer, eliminação até 1 vencedor + tela de resultado
- Coach ligado no 1º uso (toggle em Ajustes), tutorial e glossário PT-BR
- Replay da última mão (streets + ações)
- Persistência local de preferências, sessões e replay (`UserDefaults` via módulo `Persistence`)
- UI SwiftUI portrait-first: Home → Cash / Torneio / Ajustes, mesa com pote/stacks/ações legíveis
- Sem MTT, multiplayer ou dinheiro real

## Estrutura

```
.
├── Package.swift              ← pacote Swift (engine + testes); abra no Xcode
├── project.yml                ← definição XcodeGen do app iOS
├── Scripts/generate-app.sh    ← gera AppPoker.xcodeproj (requer xcodegen)
├── Sources/
│   ├── GameEngine/            regras, baralho, pot, showdown, SNG/blinds, hand history
│   ├── BotAI/                 heurística “amigável”
│   ├── TableSession/          cash + Sit & Go
│   ├── Coach/                 dicas, tutorial, glossário
│   └── Persistence/           preferências e histórico local
├── Tests/GameEngineTests/
└── App/AppPoker/              app SwiftUI (telas + tema)
```

## Abrir no Xcode (Mac) e rodar no Simulator

### Pré-requisitos

- macOS com **Xcode 15+** (iOS 17+)
- (Opcional, recomendado) [Homebrew](https://brew.sh) + **XcodeGen**: `brew install xcodegen`

### Opção A — App iOS completo (recomendada)

Gera o projeto de app a partir de `project.yml` e `Package.swift`:

```bash
git clone https://github.com/danielrodrigues677-hub/App-Poker.git
cd App-Poker
chmod +x Scripts/generate-app.sh   # se necessário
./Scripts/generate-app.sh
open AppPoker.xcodeproj
```

No Xcode:

1. Selecione o scheme **AppPoker**
2. Destino: um **iPhone Simulator** (ex.: iPhone 15 / 16)
3. Rode com **⌘R**

O script `Scripts/generate-app.sh` chama `xcodegen generate`. Se o `xcodegen` não estiver instalado, o script explica o erro e sugere a Opção B.

### Opção B — Sem XcodeGen

1. Xcode → **File → New → Project → App** (SwiftUI, iOS 17+, idioma Swift)
2. Adicione o pacote local: **File → Add Package Dependencies… → Add Local…** e escolha a pasta do repositório (`Package.swift`)
3. Inclua os fontes de `App/AppPoker/` no target do app
4. Ligue os products: `GameEngine`, `BotAI`, `TableSession`, `Coach`, `Persistence`
5. Scheme do app → iPhone Simulator → **⌘R**

### Só o pacote (engine + testes)

Abra `Package.swift` no Xcode (ou `open Package.swift` no Terminal). Isso basta para editar o motor e rodar testes — **não** inclui a UI do app em `App/AppPoker/`.

## Testes

No Mac (Xcode ou Terminal), na raiz do repositório:

```bash
swift test
```

No Xcode: scheme do pacote **AppPoker** → **Product → Test** (⌘U).

Os testes cobrem baralho/deal, ações legais, ranking, sessão cash, Sit & Go/blinds, coach prefs e persistência. A UI SwiftUI não faz parte do `swift test`; valide no Simulator.

## Requisitos

- Xcode 15+ / iOS 17+
- Swift 5.9+
- Orientação: portrait (iPhone)

## Fora do V1

Multiplayer, dinheiro real, MTT, variantes (Omaha etc.), UI em inglês, IAP.
