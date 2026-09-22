# Integração do TraceLens com gesto de chacoalhar

Use este guia no app que consome o TraceLens.

## 1. Adicione o pacote local

No Xcode:

1. Abra o projeto do app.
2. Acesse `File > Add Package Dependencies...`.
3. Escolha `Add Local...`.
4. Selecione a pasta local do pacote:

```text
/Users/rodrigo/Projetos/TraceLens
```

5. Adicione o produto `TraceLens` ao target do app.

## 2. Inicie o TraceLens na abertura do app

No ponto de entrada do app, inicialize o TraceLens antes das primeiras requests:

```swift
import SwiftUI
import TraceLens

@main
struct MeuApp: App {
    init() {
        TraceLens.start(configuration: .init(
            defaultCapture: .metadata,
            configuredScopes: [
                .host("api.exemplo.com", capture: .full)
            ],
            sensitiveDataPolicy: .redacted
        ))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
```

## 3. Instrumente a URLSession do app

Ao criar a `URLSession` usada pelas requests, use uma configuração instrumentada:

```swift
import Foundation
import TraceLens

let configuration = TraceLens.instrument(.default)
let session = URLSession(configuration: configuration)
```

Se o app já tem uma `URLSessionConfiguration` personalizada, instrumente essa instância:

```swift
let configuration = URLSessionConfiguration.default
configuration.timeoutIntervalForRequest = 30
configuration.timeoutIntervalForResource = 60

let instrumentedConfiguration = TraceLens.instrument(configuration)
let session = URLSession(configuration: instrumentedConfiguration)
```

## 4. Adicione um detector de chacoalhar

Crie `ShakeToPresentTraceLens.swift` no target do app:

```swift
import SwiftUI

struct ShakeToPresentTraceLens: UIViewControllerRepresentable {
    let onShake: () -> Void

    func makeUIViewController(context: Context) -> ShakeViewController {
        let controller = ShakeViewController()
        controller.onShake = onShake
        return controller
    }

    func updateUIViewController(_ uiViewController: ShakeViewController, context: Context) {}

    final class ShakeViewController: UIViewController {
        var onShake: (() -> Void)?

        override var canBecomeFirstResponder: Bool { true }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            becomeFirstResponder()
        }

        override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
            guard motion == .motionShake else { return }
            onShake?()
        }
    }
}
```

## 5. Apresente o TraceLens a partir da RootView

Envolva a raiz do app com uma apresentação de tela cheia:

```swift
import SwiftUI
import TraceLens

struct RootView: View {
    @State private var isTraceLensPresented = false

    var body: some View {
        MainAppView()
            .background {
                ShakeToPresentTraceLens {
                    isTraceLensPresented = true
                }
            }
            .fullScreenCover(isPresented: $isTraceLensPresented) {
                TraceLensView {
                    isTraceLensPresented = false
                }
            }
    }
}
```

Substitua `MainAppView()` pela view raiz real do app.

## 6. Teste no simulador

1. Execute o app em um simulador iOS.
2. Faça requests pela aplicação.
3. Chacoalhe o simulador usando `Device > Shake` ou `Control + Command + Z`.
4. O TraceLens abrirá em tela cheia.
5. Confira as requests capturadas.

## Observações

- Mantenha `sensitiveDataPolicy: .redacted` ao testar tráfego com dados reais.
- Não registre, versione ou exponha tokens, chaves de API ou credenciais.
- Use `.metadata` como captura padrão e `.full` somente em hosts seguros para desenvolvimento.
- Se as requests não aparecerem, confirme que o app usa uma `URLSession` criada a partir de `TraceLens.instrument(...)`.
