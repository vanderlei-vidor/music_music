# Changelog

Todas as mudancas relevantes deste projeto serao documentadas aqui.

## [1.4.0] - 2026-03-06

### Added
- **Gapless Playback**: Reproducao continua sem silencio entre faixas do mesmo album.
- **Crossfade**: Transicao suave com sobreposicao gradual de faixas (2-12 segundos).
- **PlaybackPreferences**: Gerenciamento de configuracoes de playback no SharedPreferences.
- **PlaybackSettingsView**: Tela de configuracoes dedicada para Gapless e Crossfade.
- **Controle de duracao do Crossfade**: Slider de 0-12 segundos com feedback visual.
- **Fade in/out automatico**: Implementacao manual de crossfade via controle de volume.

### Changed
- `PlaylistViewModel` agora carrega configuracoes de playback na inicializacao.
- `_setAudioSource` otimizado para usar `setAudioSources` com lista direta.
- `AboutView` atualizado com link para configuracoes de reproducao.
- Lista de recursos principais agora menciona "Gapless playback e crossfade".
- **Menu de Reproducao movido para os drawers**: Acesso agora pela Home e Player Principal.

### Fixed
- **Crossfade lock**: Adicionado `_isChangingTrack` para evitar processamento multiplo simultaneo.
- **Listener de sequenceState**: Agora usa `await` em vez de `unawaited` para crossfade.
- **Volume do crossfade**: Corrigido para sempre retornar a 1.0 ao final.
- **Comparacao de tracks**: Usa ID ou audioUrl para evitar falsos positivos.
- **UI delay na transicao**: Crossfade agora usa `Timer.periodic` para nao bloquear o listener (antes delay de 7s na UI).
- **Crossfade nao-bloqueante**: Listener atualiza a UI imediatamente enquanto fade ocorre em background.

### Technical
- `PlaybackConfig`: Modelo imutavel para configuracoes de playback.
- `_applyCrossfade()`: Implementa fade in gradual com 20 steps para suavidade.
- Getters publicos para `gaplessEnabled`, `crossfadeEnabled`, `crossfadeSeconds`.
- Persistencia automatica das preferencias via `SharedPreferences`.

### UX
- Configuracoes acessiveis via tela "Sobre" > "Reproducao (Gapless/Crossfade)".
- Valores padrao: Gapless habilitado, Crossfade desabilitado (0s).
- Info card explica diferenca entre Gapless e Crossfade.

## [1.3.0] - 2026-03-06

### Added
- Componente compartilhado de estado de tela `AppStateView` com variantes:
  - `loading`
  - `empty`
  - `error` (com CTA opcional)
- Observabilidade base para diagnostico de erros em runtime:
  - `AppLogger` com buffer em memoria de logs recentes
  - exportacao/copia de logs pela tela `Sobre`
- Smoke tests de rotas principais (`test/smoke_routes_test.dart`) para detectar regressao de navegacao.

### Changed
- Padronizacao de estados de UI nas telas principais da biblioteca e playlists:
  - `lib/features/home/widgets/home_tabs.dart`
  - `lib/features/library/view/all_musics_screen.dart`
  - `lib/features/library/view/trash_library_view.dart`
  - `lib/features/playlists/view/playlist_view.dart`
  - `lib/features/playlists/view/playlists_screen.dart`
  - `lib/features/playlists/view/music_selection_screen.dart`
  - `lib/features/favorites/view/favorites_view.dart`
  - `lib/features/player/view/player_view.dart`
- Fluxos de empty/error agora oferecem mensagens mais claras e acoes de recuperacao (`Tentar novamente`, `Reescanear`, `Atualizar`).
- `main.dart` reforcado para captura global de excecoes Flutter/Dart com envio para logger central.

### Fixed
- Eliminacao de inconsistencias visuais entre telas que usavam estados manuais diferentes.
- Remocao de loaders de tela redundantes/legados, mantendo spinners somente em acoes locais (ex.: botoes de salvar).

### Quality
- `flutter analyze` sem issues apos a padronizacao.
- `flutter test` com suite existente passando (incluindo smoke routes).

## [1.2.0] - 2026-03-04

### Added
- Equalizador avancado com presets padrao e presets custom do usuario (salvar/aplicar/renomear/excluir).
- Export/import de presets custom em JSON direto pela UI do equalizador.
- Perfis de saida por dispositivo (`Fone`, `Bluetooth`, `Carro`) com persistencia por perfil.
- Troca automatica de perfil por rota de audio usando `audio_session` (`devicesStream`).
- Ferramenta de reprocessamento de generos em lote para biblioteca local.
- Modo experimental de processamento iOS do EQ:
  - `Preamp-only`
  - `Tonal synthesis`
  - `True multiband (WIP)`

### Changed
- Visual do equalizador reformulado para padrao premium:
  - sliders verticais por banda
  - curva de resposta animada
  - area de ganho/perda preenchida
  - escala lateral `+12 / 0 / -12 dB`
  - trilha visual de picos (ghost/trailing curve)
- `EqualizerSheet` tornou-se responsiva com scroll e altura maxima para evitar overflow em telas menores.
- Fluxo de genero no player reforcado com fallback por pasta e heuristica textual.

### iOS
- Inicio do caminho de fork local do `just_audio` para evoluir EQ nativo:
  - `dependency_overrides` apontando para `third_party/just_audio`
  - API Dart no player do fork: `darwinSetEqualizer(...)`
  - hook nativo por player no Darwin plugin para receber estado do EQ
- Preamp iOS aplicado com efeito audivel imediato no backend atual (composicao de volume + ganho em dB).
- Bandas no iOS atualmente usando fallback tonal (`Tonal synthesis`) ate fechamento do `True multiband`.

### Performance
- Aplicacao do EQ serializada por backend para evitar condicoes de corrida.
- Persistencia debounce de estado do equalizador mantida para reduzir I/O.

### Fixed
- Correcao de `RenderFlex overflow` na folha do equalizador.
- Correcao de estado condicionado por pasta em navegacao de biblioteca (desacoplamento para fluxo global).

### Quality
- `flutter analyze` sem issues apos as mudancas.
- `flutter test` com testes existentes passando.

## [1.1.0] - 2026-02-12

### Added
- Tela de boas-vindas personalizada com nome do usuario e resumo da biblioteca.
- Persistencia de preferencias de boas-vindas (nome e controle de exibicao diaria).
- Arquivo central de identidade do app (`AppInfo`) para nome/descricao.
- README de produto com stack, arquitetura e fluxo de build.

### Changed
- Fluxo de entrada atualizado: `Splash -> Welcome/Home` conforme regra diaria.
- Aba de playlists na Home otimizada para usar estado em memoria (sem `FutureBuilder` recorrente no build).
- Metadados de release atualizados (`pubspec` versao `1.1.0+2` e descricao de produto).
- Label Android atualizado para `Music Music`.
- Textos principais alinhados para PT-BR.

### Performance
- Import/scan de musicas otimizado com insercao em lote e transacao no SQLite.
- Indices adicionados no banco para favoritos, recentes, mais tocadas e relacao de playlist.
- Player com reducao de rebuilds globais (selecao de estado mais fina).
- Cache de artwork no player para evitar consultas repetidas em rebuild.

### Fixed
- Acoes do drawer da Home que estavam sem navegacao.
- Filtro da tela de detalhe de playlist (lista filtrada agora aplicada corretamente).

### Quality
- `flutter analyze` sem issues apos as mudancas.
- Testes existentes (`flutter test`) passando.

