# TraceLens

TraceLens é um pacote Swift para iOS 17+ que observa tráfego HTTP temporariamente dentro do app. Ele foi pensado para desenvolvimento, QA e debug — não para telemetria de produção.

## Instalação e início

Adicione este repositório pelo Swift Package Manager, importe apenas `TraceLens` e inicie-o no app hospedeiro:

```swift
import TraceLens

TraceLens.start(configuration: .init(
    defaultCapture: .metadata,
    configuredScopes: [.host("api.exemplo.com", capture: .full)],
    endpointPresentation: .serviceAfterPathPrefix("/api/v2"),
    serviceAliases: ["payments": "Pagamentos"]
))
```

Para stacks simples, sem `URLSessionDelegate` customizado ou SSL Pinning, é possível instrumentar a configuração antes de criar a `URLSession`:

```swift
let configuration = TraceLens.instrument(.default)
let session = URLSession(configuration: configuration)
```

Para SDCore e outros stacks que controlam SSL Pinning, delegates ou a configuração da sessão, use a observação passiva. O stack continua executando a request real; o TraceLens apenas recebe os eventos:

```swift
let observation = await TraceLens.beginObservation(finalURLRequest)

// SDCore executa a request com sua URLSession e SSL Pinning originais.

if let observation {
    await TraceLens.recordResponse(
        urlResponse,
        body: responseData,
        for: observation
    )
}
```

Em caso de erro, registre-o com `await TraceLens.recordFailure(error, for: observation)`. Se o SDCore expuser métricas, use `await TraceLens.recordMetrics(metrics, for: observation)`.

Apresente `TraceLensView` em uma `fullScreenCover`, destino de navegação ou janela de debug. Use `await TraceLens.clearSession()` para limpar a sessão e `try await TraceLens.exportSession()` para exportá-la.

## Configurações da tela Settings

Por padrão, todos os controles são visíveis. A captura padrão é `Metadata`, a captura de rede e métricas ficam ativadas, e dados sensíveis ficam mascarados (`.redacted`).

O app hospedeiro pode esconder controles que não devem ficar disponíveis ao usuário:

```swift
TraceLens.start(configuration: .init(
    settingsControls: .init(
        defaultCapture: true,
        networkCapture: false,
        taskMetrics: false,
        sensitiveDataPolicy: false,
        maskTokens: false,
        transactionLimit: false,
        clearSession: true,
        exportSession: true
    )
))
```

Os parâmetros omitidos em `TraceLensSettingsControls` permanecem ativados.

## Escopos e privacidade

As regras configuradas ficam no código do app hospedeiro. A aba Escopos pode criar regras de captura completa para a sessão atual ou apenas para a próxima request a partir de hosts descobertos.

A prioridade é: próxima request, sessão, regra configurada e, por último, captura padrão. Dentro da mesma origem, a regra mais específica vence.

A política padrão é `.redacted`: ela mascara headers sensíveis na interface, no comando cURL e na exportação. Use `.visible` apenas em ambientes de debug aprovados.

`Detalhes completos` captura headers e body de request/response. `Metadata` mantém URL, método, status e duração. Recomenda-se usar `Metadata` como padrão e `Detalhes completos` apenas em hosts seguros durante uma investigação.

### Título do serviço na lista de requests

Use `endpointPresentation` para definir qual parte do path será exibida como título da request. Para APIs no formato `/v1/sicredi/<microserviço>/...` ou `/v2/sicredi/<microserviço>/...`, configure o índice `2` (a contagem começa em zero):

```swift
TraceLens.start(configuration: .init(
    endpointPresentation: .serviceAtPathIndex(2),
    serviceAliases: [
        "payments": "Pagamentos",
        "accounts": "Contas"
    ]
))
```

Assim, `/v2/sicredi/payments/orders` aparece com o título `Pagamentos` e endpoint `/orders`, sem que `v1` ou `v2` sejam usados como serviço.

## Organização com múltiplos repositórios

Mantenha os módulos de feature sem dependência do TraceLens:

```text
FeatureRepository/
  Sources/
  Tests/
  Example/FeatureDemoApp  ← importa a feature e TraceLens
```

O exemplo incluído em `Examples/TraceLensDemo` ilustra essa organização em um app hospedeiro independente.

## Limites e limitações

TraceLens mantém apenas a sessão atual e remove arquivos temporários de body ao limpar/parar uma sessão e na inicialização. Os limites padrão são 1.000 transações, 5 MB por body e 100 MB de armazenamento temporário.

A captura por `URLProtocol` é suportada para instâncias de `URLSessionConfiguration` instrumentadas explicitamente e em primeiro plano, mas não deve ser usada em stacks com delegate customizado ou SSL Pinning. Para esses casos, use a observação passiva. Sessões criadas antes da instrumentação, sessões em background, outras bibliotecas de rede e todos os detalhes de redirecionamento podem não ser observados. Uma falha de captura nunca deve bloquear a request original.
