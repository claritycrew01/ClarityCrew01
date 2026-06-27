# ClarityCrew Agent Rules

## Main rule
Do not treat this repo like a prototype. Treat it like a real app under active development.

## Product direction
ClarityCrew is an academic study app for neurodivergent learners. It is not a disorder education app.

## Non-negotiables
- Keep the current app base unless a specific part blocks the product goal.
- Do not rebuild the app from scratch unless explicitly requested.
- Do not add placeholder screens.
- Do not add dummy buttons.
- Do not leave empty content shells.
- Do not leave video placeholders without real sources or local media.
- Do not make AI hidden or decorative.
- Do not change the product into a disorder-help app.

## AI rules
- AI must be explicit and visible in the UI.
- AI should help with academic study.
- AI should drive recommendations, explanations, and study flow.
- AI should not be merely decorative or rule-based-looking.

## Data rules
- Use real structured content for subjects, lessons, quizzes, videos, and progress.
- Seed missing content with actual example data.
- Persist learner state locally.
- Do not rely on demo values for core flows.
- Content data (subjects, chapters, lessons, videos) is loaded from Firestore when Firebase is configured, falling back to bundled JSON assets in `assets/content/`.
- Video sources are stored in the `assetPath` field of each video document/record. URLs starting with `http` are played via `VideoPlayerController.networkUrl()`, local paths via `VideoPlayerController.asset()` (mobile) or `VideoPlayerController.networkUrl()` (web).

## Layout rules
- Fix bottom overflow issues.
- Use SafeArea where needed.
- Make content scrollable on small screens.
- Test on constrained mobile heights.
- On desktop and tablet, content is constrained to `maxContentWidth` (480px) and centered.

## Workflow rules
- Before implementing a feature, define the data model.
- Before adding a screen, define the content it will render.
- After implementing, verify the feature with real data.
- Prefer small focused changes over broad rewrites.
- If a feature is missing required data, create the data schema and seed data first.
- All builds are done via GitHub Actions CI. Do not attempt local builds — Flutter is not installed locally.

## Build & Deploy (Android)
- Trigger APK build by pushing to `master` on GitHub.
- Download the APK artifact via `gh run download <run-id> --name claritycrew-apk --dir <path>`.
- Do not run `flutter build` locally. Always use the CI pipeline.

## Build & Deploy (Website)
- The website is automatically built and deployed to GitHub Pages on push to `master`.
- The `Deploy Website` workflow builds the Flutter web app and deploys with `actions/deploy-pages`.
- The website URL will be `https://claritycrew01.github.io/ClarityCrew01/`.
- To trigger a manual deploy, go to Actions > Deploy Website > Run workflow.

## Web-specific notes
- Flutter web platform files live in `web/` directory.
- `kIsWeb` is used to guard platform-specific code (e.g., `HapticFeedback`).
- Video assets on web are served via `VideoPlayerController.networkUrl()` since `asset()` is not supported on web.
- The responsive wrapper in `lib/widgets/responsive_wrapper.dart` constrains content to app-like width on desktop.
- Firebase is optional on web — app works fully with bundled JSON assets.

## Done means
A feature is only done when:
- it renders real data,
- it works on mobile,
- it does something useful,
- and it does not leave placeholder UI behind.
