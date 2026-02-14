# Release Checklist (Android/Web)

## 1. Pré-release (obrigatório)

- [ ] Confirmar versão no `pubspec.yaml` (`version: 1.1.0+2`).
- [ ] Revisar changelog em `CHANGELOG.md`.
- [ ] Rodar qualidade local:
  - [ ] `flutter clean`
  - [ ] `flutter pub get`
  - [ ] `flutter analyze`
  - [ ] `flutter test`
- [ ] Validar assets e branding:
  - [ ] Ícone correto
  - [ ] Nome do app (`Music Music`) em telas e metadados
  - [ ] `README.md` atualizado
- [ ] Smoke test manual:
  - [ ] Splash -> Welcome/Home
  - [ ] Scan/import de músicas
  - [ ] Player (play/pause, seek, shuffle, repeat, sleep timer)
  - [ ] Playlists (criar, adicionar, remover, tocar)
  - [ ] Favoritas, Recentes e Mais tocadas

## 2. Android (produção)

### Configuração
- [ ] Conferir `applicationId` e package final (evitar `com.example.*` em produção).
- [ ] Conferir assinatura de release (`key.properties`/keystore).
- [ ] Conferir permissões no `AndroidManifest.xml`.

### Build
- [ ] Gerar App Bundle:
  - [ ] `flutter build appbundle --release`
- [ ] (Opcional) Gerar APK:
  - [ ] `flutter build apk --release`

### Validação de artefato
- [ ] Instalar build release em dispositivo real.
- [ ] Validar controles de mídia/notification em background.
- [ ] Verificar tamanho do bundle e regressões de startup.

### Publicação Play Console
- [ ] Subir `.aab` na trilha interna/fechada.
- [ ] Preencher notas da versão (usar `CHANGELOG.md`).
- [ ] Validar política de permissões e conteúdo.
- [ ] Promover para produção após validação.

## 3. Web (produção)

### Build
- [ ] `flutter build web --release`

### Deploy
- [ ] Publicar conteúdo de `build/web` no hosting/CDN.
- [ ] Configurar cache headers adequados (evitar cache agressivo do `index.html`).
- [ ] Garantir fallback de rotas para SPA (servir `index.html`).

### Validação pós-deploy
- [ ] Testar em Chrome/Edge (desktop) e Android/iOS navegador.
- [ ] Validar upload/import web, navegação e player.
- [ ] Verificar Lighthouse básico (Performance/Best Practices/SEO).

## 4. Pós-release

- [ ] Criar tag Git da versão (`v1.1.0`).
- [ ] Arquivar artefatos de build.
- [ ] Monitorar crashes/feedback nas primeiras 24-72h.
- [ ] Abrir backlog de hotfix se necessário.

