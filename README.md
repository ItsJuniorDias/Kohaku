# Kohaku — iOS App

App reader de horror weird curto, estilo Junji Ito. iOS 26.5+, SwiftUI, StoreKit 2.

## Como abrir

1. Extraia o ZIP por cima da pasta atual (substitui os arquivos)
2. Abra `Kohaku.xcodeproj` no Xcode
3. O projeto usa `PBXFileSystemSynchronizedRootGroup` (Xcode 16+), então **todos os arquivos Swift e Resources novos são detectados automaticamente** — não precisa arrastar nada manualmente
4. Selecione simulador iPhone e ⌘R

## ✅ Fontes reais (Bodoni Moda + EB Garamond) integradas

As fontes estão em `Resources/Fonts/` e já registradas no `INFOPLIST_KEY_UIAppFonts` do target:

- `BodoniModa-VariableFont.ttf` — display (Bodoni Moda opsz+wght)
- `EBGaramond-VariableFont.ttf` — body (EB Garamond wght)
- `EBGaramond-Italic-VariableFont.ttf` — body italic (EB Garamond Italic wght)

Ambas são **Variable Fonts** — um único arquivo com múltiplos pesos, controlados via `.fontWeight()` modifier no SwiftUI. Mais leve que ter arquivos separados por peso.

Licenças SIL Open Font License 1.1 estão em `OFL-BodoniModa.txt` e `OFL-EBGaramond.txt`. Uso comercial permitido. Se você precisar dar créditos no App Store ou About page, use:

- "Bodoni Moda" — © 2020 Bodoni Moda Project Authors, indestructible.type
- "EB Garamond" — © 2017 EB Garamond Project Authors, Georg Duffner + Octavio Pardo

### Verificando se as fontes carregaram

Em debug builds, o console mostra logo no launch:

```
─── Kohaku Font Verification ───
  ✓ BodoniModa-Regular loaded
  ✓ EBGaramond-Regular loaded
  ✓ EBGaramond-Italic loaded

  Available custom font families containing 'Bodoni' or 'Garamond':
    Family: Bodoni Moda
      → BodoniModa-Regular
    Family: EB Garamond
      → EBGaramond-Regular
      → EBGaramond-Italic
─────────────────────────────────
```

Se aparecer `❌ NOT loaded`, confira:
1. Se os `.ttf` estão em `Resources/Fonts/` do projeto (Xcode target member)
2. Se `INFOPLIST_KEY_UIAppFonts` no build settings lista os 3 arquivos exatos
3. Se o PostScript name em `Theme/Typography.swift` casa (rodou o log e viu o nome real)

Código do debug em `Theme/FontDebug.swift`.

## Testando a Subscription (StoreKit 2 local)

Antes de rodar a subscription, configure o StoreKit Configuration file:

1. Xcode → **Product → Scheme → Edit Scheme**
2. **Run → Options**
3. Em **StoreKit Configuration**, selecione `Kohaku.storekit`
4. Rode o app novamente

Agora ao clicar "Continue with Kohaku" no paywall, você vê os planos ($2.99 Monthly, $24.99 Yearly) e pode simular compra local. Não gasta dinheiro real, não precisa de sandbox tester.

**Pra produção**: você precisa criar esses products em App Store Connect com os mesmos IDs:
- `com.alexandrejunior.kohaku.subscription.monthly`
- `com.alexandrejunior.kohaku.subscription.yearly`

## Estrutura

```
Kohaku/Kohaku/
├── KohakuApp.swift              # Entry point + FontDebug
├── ContentView.swift            # Onboarding gate
│
├── Theme/                       # Design tokens
│   ├── Colors.swift             # 5 tokens PB (v0.2)
│   ├── Typography.swift         # Bodoni Moda + EB Garamond (REAL)
│   ├── Spacing.swift            # 4pt scale
│   ├── Motion.swift             # No springs, dread curve
│   └── FontDebug.swift          # Log fontes no launch
│
├── Components/                  # Design system atoms
│   ├── KohakuText.swift         # ⚠ SEMPRE use, nunca Text() direto
│   ├── KohakuButton.swift       # 3 variants: primary/secondary/ghost
│   ├── KohakuCard.swift
│   ├── OrnamentDivider.swift    # full + minimal
│   ├── SpiralShape.swift        # + KohakuGlyph
│   ├── EyeShape.swift
│   └── EmptyCocoonShape.swift
│
├── Models/
│   └── Story.swift
│
├── Data/
│   ├── MockStories.swift        # 3 contos reais (matcham as 3 capas)
│   └── StoryRepository.swift    # @Observable, in-memory
│
├── Store/
│   ├── SubscriptionManager.swift  # StoreKit 2 real
│   └── Kohaku.storekit            # Config pra testes locais
│
├── Screens/
│   ├── RootTabView.swift        # Tab bar custom monochrome
│   ├── Common/
│   │   ├── EmptyStateView.swift
│   │   └── StoryCardView.swift
│   ├── Onboarding/
│   │   └── OnboardingView.swift
│   ├── Library/
│   │   └── LibraryView.swift
│   ├── Discover/
│   │   └── DiscoverView.swift
│   ├── Story/
│   │   └── StoryDetailView.swift
│   ├── Reader/
│   │   ├── ReaderView.swift
│   │   └── ReaderSettingsView.swift
│   ├── Subscription/
│   │   └── SubscriptionView.swift
│   ├── Settings/
│   │   └── SettingsView.swift
│   └── About/
│       └── AboutView.swift
│
├── Resources/
│   └── Fonts/
│       ├── BodoniModa-VariableFont.ttf
│       ├── EBGaramond-VariableFont.ttf
│       ├── EBGaramond-Italic-VariableFont.ttf
│       ├── OFL-BodoniModa.txt          # SIL Open Font License
│       └── OFL-EBGaramond.txt
│
└── Assets.xcassets/
    ├── the-coil.imageset/
    ├── the-well.imageset/
    ├── quiet-house.imageset/
    ├── onboarding-1-closed-eye.imageset/
    ├── onboarding-2-staircase.imageset/
    └── onboarding-3-empty-chair.imageset/
```

## Fluxo do app

```
Launch
  ↓
Onboarding (3 páginas, primeira execução)
  ↓
RootTabView
  ├── Library ─── (empty state se vazio)
  ├── Discover ─── grid de contos
  │       ↓
  │   StoryDetailView (capa + metadata + excerpt + CTAs)
  │       ↓
  │   ReaderView (chrome oculto, progress bar bone)
  │       ↓
  │   ReaderSettingsView (font size)
  │
  └── Settings ─── About / Subscription / Restore
          ↓
      SubscriptionView (paywall StoreKit 2)
```

## TODOs pra produção

### Persistência
Substitua `StoryRepository` in-memory por SwiftData ou CloudKit.

### Catálogo remoto
Mova `MockStories` pra um backend (o Grimoire Analytics seu tem uma boa base) e faça fetch dinâmico.

### App icon
Crie um ícone 1024x1024 baseado no `KohakuGlyph` e adicione em `Assets.xcassets/AppIcon.appiconset/`.

### Localização
Se for lançar pt-BR também, crie `Localizable.strings` (en-US + pt-BR).

## Convenções

- **NUNCA use `Text(...)` direto**. Sempre `KohakuText(..., style: .xxx)`.
- **NUNCA use SF Symbols**. Sempre custom Shapes (ver `Components/`).
- **NUNCA use `.spring()`**. Sempre `KohakuMotion.fast/medium/slow/dread`.
- **NUNCA use cores fora dos 5 tokens** (`kohakuVoid/Ink/Bone/Ash/Pallor`).

Ver o PDF `Kohaku-DesignSystem.pdf` pra detalhes.
