# Release Checklist 1.2.0 (Android/Web/iOS)

## 1. Pre-release (obrigatorio)

- [x] Confirmar versao no `pubspec.yaml` (release final `1.2.0+N`).
- [x] Revisar changelog em `CHANGELOG.md` (`[1.2.0-rc]` -> `[1.2.0]`).
- [ ] Rodar qualidade local:
  - [ ] `flutter clean`
  - [ ] `flutter pub get`
  - [x] `flutter analyze`
  - [x] `flutter test`
- [ ] Validar migracoes de estado do EQ:
  - [ ] Presets custom existentes continuam carregando
  - [ ] Perfis `Fone/Bluetooth/Carro` preservam configuracoes separadas
  - [ ] Import/export JSON sem perda de dados
- [ ] Smoke test manual do fluxo de audio:
  - [ ] Play/Pause/Seek/Next/Previous
  - [ ] Shuffle/Repeat/Sleep Timer
  - [ ] Equalizador: preamp, bandas, presets, reset

## 2. Equalizer QA Matrix

### Android
- [ ] Preamp audivel em toda faixa de -12 a +12 dB.
- [ ] Bandas alteram timbre conforme esperado.
- [ ] Auto-headroom reduz clipping perceptivel.
- [ ] Troca automatica de perfil por dispositivo funcionando.

### iOS
- [ ] Modo `Preamp-only` funcionando sem artefatos.
- [ ] Modo `Tonal synthesis` responde a mudancas de banda.
- [ ] Modo `True multiband` marcado como WIP na UI.
- [ ] Mudanca de perfil por rota de audio funcionando.
- [ ] Regressao zero em reproducoes longas/background.

### Web
- [ ] UI do EQ sem overflow em layouts menores.
- [ ] Persistencia de presets/perfis funcionando apos reload.

## 3. Biblioteca e Metadados

- [ ] Reprocessamento de generos em lote atualizado em biblioteca real.
- [ ] Verificar contagem de itens atualizados e consistencia por genero.
- [ ] Confirmar que fallback por pasta/texto nao degrada classificacao.

## 4. Build Artifacts

### Android
- [ ] `flutter build appbundle --release`
- [ ] Instalar build release em dispositivo real
- [ ] Validar notificacao/controles em background

### Web
- [ ] `flutter build web --release`
- [ ] Publicar `build/web`
- [ ] Validar cache headers e fallback SPA

### iOS
- [ ] Build release em Xcode (Runner)
- [ ] Teste em device real (nao apenas simulador)
- [ ] Assinatura/provisioning validos

## 5. Go/No-Go

- [ ] Sem crashes bloqueantes em 24h de beta interno.
- [ ] Sem regressao critica no player.
- [ ] Igual ou melhor consumo de bateria vs 1.1.0.
- [ ] Aprovar publicacao da `1.2.0`.

## 6. Pos-release

- [ ] Tag Git `v1.2.0`
- [ ] Arquivar artefatos
- [ ] Monitorar feedback/crashes por 72h
- [ ] Abrir hotfixes se necessario

