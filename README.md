# Music Music

Aplicativo Flutter para reprodução de música local com foco em UX premium, organização da biblioteca e performance.

## Destaques

- Player completo com controles de fila, shuffle, repeat e sleep timer.
- Biblioteca por músicas, álbuns, artistas, gêneros e pastas.
- Playlists locais com adição/remoção de faixas.
- Favoritas, recentes e mais tocadas.
- Tela de boas-vindas personalizada com nome do usuário.
- Suporte multiplataforma: Android, iOS, Web, Windows, macOS e Linux.

## Stack

- Flutter + Provider (gerenciamento de estado)
- just_audio + just_audio_background + audio_session (áudio)
- sqflite / sqflite_common_ffi / sqflite_common_ffi_web (persistência)
- on_audio_query (metadados e artwork local)
- shared_preferences (preferências do usuário)

## Arquitetura

Estrutura baseada em features:

- `lib/features/` telas e viewmodels por domínio (home, player, playlists, library etc.)
- `lib/data/` modelos e acesso a banco local
- `lib/core/` tema, utilitários, plataforma e serviços compartilhados
- `lib/shared/` widgets reutilizáveis

## Como executar

```bash
flutter pub get
flutter run
```

## Qualidade

```bash
flutter analyze
flutter test
```

## Build de release (exemplos)

```bash
flutter build apk --release
flutter build appbundle --release
flutter build web --release
```

## Gestão de release

- Changelog: `CHANGELOG.md`
- Checklist de publicação: `RELEASE_CHECKLIST.md`
