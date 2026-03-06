# Release Checklist (Android/Web)

## 1. Pre-release (obrigatorio)

- [ ] Confirmar versao no `pubspec.yaml` (release alvo atual).
- [ ] Revisar changelog em `CHANGELOG.md`.
- [ ] Rodar qualidade local:
  - [ ] `flutter clean`
  - [ ] `flutter pub get`
  - [ ] `flutter analyze`
  - [ ] `flutter test`
- [ ] Validar assets e branding:
  - [ ] Icone correto
  - [ ] Nome do app (`Music Music`) em telas e metadados
  - [ ] `README.md` atualizado
- [ ] Smoke test manual:
  - [ ] Splash -> Welcome/Home
  - [ ] Scan/import de musicas
  - [ ] Player (play/pause, seek, shuffle, repeat, sleep timer)
  - [ ] Playlists (criar, adicionar, remover, tocar)
  - [ ] Favoritas, Recentes e Mais tocadas

## 2. Android (producao)

### Configuracao
- [ ] Conferir `applicationId` e package final (evitar `com.example.*` em producao).
- [ ] Conferir assinatura de release (`key.properties`/keystore).
- [ ] Conferir permissoes no `AndroidManifest.xml`.

### Build
- [ ] Gerar App Bundle:
  - [ ] `flutter build appbundle --release`
- [ ] (Opcional) Gerar APK:
  - [ ] `flutter build apk --release`

### Validacao de artefato
- [ ] Instalar build release em dispositivo real.
- [ ] Validar controles de midia/notificacao em background.
- [ ] Verificar tamanho do bundle e regressao de startup.

### Publicacao Play Console
- [ ] Subir `.aab` na trilha interna/fechada.
- [ ] Preencher notas da versao (usar `CHANGELOG.md`).
- [ ] Validar politica de permissoes e conteudo.
- [ ] Promover para producao apos validacao.

## 3. Web (producao)

### Build
- [ ] `flutter build web --release`

### Deploy
- [ ] Publicar conteudo de `build/web` no hosting/CDN.
- [ ] Configurar cache headers adequados (evitar cache agressivo do `index.html`).
- [ ] Garantir fallback de rotas para SPA (servir `index.html`).

### Validacao pos-deploy
- [ ] Testar em Chrome/Edge (desktop) e Android/iOS navegador.
- [ ] Validar upload/import web, navegacao e player.
- [ ] Verificar Lighthouse basico (Performance/Best Practices/SEO).

## 4. Pos-release

- [ ] Criar tag Git da versao (ex.: `v1.3.0`).
- [ ] Arquivar artefatos de build.
- [ ] Monitorar crashes/feedback nas primeiras 24-72h.
- [ ] Abrir backlog de hotfix se necessario.
