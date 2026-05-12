# Changelog

## [1.8.2](https://github.com/Juiiceee/Facio/compare/Facio-v1.8.1...Facio-v1.8.2) (2026-05-12)


### Corrections de bugs

* **auth:** secure Supabase sessions ([d615670](https://github.com/Juiiceee/Facio/commit/d615670dca2132e17bbd1ec40ef0470c0e7360b0))
* **data:** protect local JSON recovery ([f69a97a](https://github.com/Juiiceee/Facio/commit/f69a97a3e0e57ef3d7ea79e60078d6284f614ffb))
* harden Facio audit findings ([#56](https://github.com/Juiiceee/Facio/issues/56)) ([da891a1](https://github.com/Juiiceee/Facio/commit/da891a131a41a866d894f44a4fa94901242a43e6))
* **pdf:** isolate logo validation helpers ([1a2e597](https://github.com/Juiiceee/Facio/commit/1a2e5970f53b950c7c8e02f910a06c98725e0933))
* **pdf:** sanitize exported documents ([fdce0c8](https://github.com/Juiiceee/Facio/commit/fdce0c8691e24712d2856b8650b5fe2515d9601c))
* **release:** harden macOS publishing ([aa5a67d](https://github.com/Juiiceee/Facio/commit/aa5a67d54a82657c661448773b38b9158d49b7c0))
* **sync:** harden Supabase data safety ([875eea8](https://github.com/Juiiceee/Facio/commit/875eea83696a9778bee9b38cfc506e3734898b61))


### Documentation

* add repository contributor guide ([5821f6d](https://github.com/Juiiceee/Facio/commit/5821f6d37cc9eec4ac88c06b79364c00b29794bc))

## [1.8.1](https://github.com/Juiiceee/Facio/compare/Facio-v1.8.0...Facio-v1.8.1) (2026-04-18)


### Corrections de bugs

* **updates:** extract semver from tag like Facio-v1.8.0 for version comparison ([#33](https://github.com/Juiiceee/Facio/issues/33)) ([3a9b37d](https://github.com/Juiiceee/Facio/commit/3a9b37d0b30a1b2b03735753608ab811398b619a))

## [1.8.0](https://github.com/Juiiceee/Facio/compare/Facio-v1.7.4...Facio-v1.8.0) (2026-04-18)


### Nouvelles fonctionnalites

* **web:** add GitHub Pages landing page for Facio ([bfe966a](https://github.com/Juiiceee/Facio/commit/bfe966a8f73881643efc4b96f89d8492e7feaa49))
* **web:** add GitHub Pages landing page for Facio ([2f93306](https://github.com/Juiiceee/Facio/commit/2f933065ce5e285a2e9be7e0c0ce40ab8d5bd0dd))

## [1.7.4](https://github.com/Juiiceee/Facio/compare/Facio-v1.7.3...Facio-v1.7.4) (2026-04-18)


### Corrections de bugs

* **pdf:** render notes section in PDF output ([#25](https://github.com/Juiiceee/Facio/issues/25)) ([60f795f](https://github.com/Juiiceee/Facio/commit/60f795f4610871774fb6b3f4be3a1c786ab090b3))

## [1.7.3](https://github.com/Juiiceee/Facio/compare/Facio-v1.7.2...Facio-v1.7.3) (2026-04-09)


### Corrections de bugs

* **pdf:** round QR code amount to 2 decimals to match invoice total ([54ed26f](https://github.com/Juiiceee/Facio/commit/54ed26f4abf47f33fae6a38c3b1f548088486254))
* **pdf:** round QR code amount to 2 decimals to match invoice total ([5d95fb7](https://github.com/Juiiceee/Facio/commit/5d95fb7005b90e2c2e6e4fa34a7c3ad4a682397e))

## [1.7.2](https://github.com/Juiiceee/Facio/compare/Facio-v1.7.1...Facio-v1.7.2) (2026-04-04)


### Corrections de bugs

* **pdf:** replace Bundle.module with safe resource loading ([1fac5e4](https://github.com/Juiiceee/Facio/commit/1fac5e4b69a563d5e7d801379a8f51f6e0bc3ff2))

## [1.7.1](https://github.com/Juiiceee/Facio/compare/Facio-v1.7.0...Facio-v1.7.1) (2026-04-04)


### Corrections de bugs

* **build:** copy SPM resource bundle into .app to prevent crash ([706f381](https://github.com/Juiiceee/Facio/commit/706f3818a9ae14e6aa61ba17dc1d6580a4143359))
* **build:** copy SPM resource bundle into .app to prevent crash ([11bbfe9](https://github.com/Juiiceee/Facio/commit/11bbfe9a30b870d88d625b67ca4545ae62abc50a))

## [1.7.0](https://github.com/Juiiceee/Facio/compare/Facio-v1.6.3...Facio-v1.7.0) (2026-04-04)


### Nouvelles fonctionnalites

* **pdf:** add Solana Pay QR code to crypto invoices ([f901964](https://github.com/Juiiceee/Facio/commit/f901964ef45a9e20952d169f76087799647479ff))


### Ameliorations

* **pdf:** enlarge QR code, add Solana logo and align layout ([cf47d7a](https://github.com/Juiiceee/Facio/commit/cf47d7a547f85c6ad60027f24b338fe111124679))

## [1.6.3](https://github.com/Juiiceee/Facio/compare/Facio-v1.6.2...Facio-v1.6.3) (2026-04-03)


### Ameliorations

* **dmg:** remove Security Settings app and clean up script ([3e75c4b](https://github.com/Juiiceee/Facio/commit/3e75c4bbf915ecaf7cacbcc09e32cdb66f22cdec))

## [1.6.2](https://github.com/Juiiceee/Facio/compare/Facio-v1.6.1...Facio-v1.6.2) (2026-04-03)


### Corrections de bugs

* **sync:** remove unused variable warnings in SyncService ([98b8a80](https://github.com/Juiiceee/Facio/commit/98b8a803aacda097fc91d13e1f6b5693b91a5ef9))


### Ameliorations

* **dmg:** add Security Settings shortcut app with gear icon ([d82fd04](https://github.com/Juiiceee/Facio/commit/d82fd046f72e79b91a5a6e2a3b4e4eca4c61f3ce))

## [1.6.1](https://github.com/Juiiceee/Facio/compare/Facio-v1.6.0...Facio-v1.6.1) (2026-04-03)


### Corrections de bugs

* **timesheet:** sync overtime calculation across month boundaries ([ac0e1a3](https://github.com/Juiiceee/Facio/commit/ac0e1a36a6694744f72903abeeb0bd44a0c7f8b6))
* **ui:** expand settings tab hit area to full padding zone ([569f470](https://github.com/Juiiceee/Facio/commit/569f4703ce598380d492b8456c80ea8741d2d786))

## [1.6.0](https://github.com/Juiiceee/Facio/compare/Facio-v1.5.1...Facio-v1.6.0) (2026-04-02)


### Nouvelles fonctionnalites

* **i18n:** add FR/EN language support per document and UI ([6c9eea6](https://github.com/Juiiceee/Facio/commit/6c9eea6c01826bef9c3bdd017c6fe892e4b3374c))
* **settings:** add Customisation tab with theme color picker ([4c7a524](https://github.com/Juiiceee/Facio/commit/4c7a5248fa594794ec17354d2b12815101f6a371))


### Corrections de bugs

* **sync:** prevent reset from deleting remote data on next sync ([7208240](https://github.com/Juiiceee/Facio/commit/720824020e741d4a7601e03da971a6cb20250f7e))
* **ui:** improve responsive layout and minimum window sizing ([715aed7](https://github.com/Juiiceee/Facio/commit/715aed751c0740f6ee515c9e5d5f21e9d29873c6))


### Refactorings

* **i18n:** split L10n.swift into domain-specific extensions ([5efe5af](https://github.com/Juiiceee/Facio/commit/5efe5afcb3dd0315f0b9bd18fb43ede7f9aa0f58))

## [1.5.1](https://github.com/Juiiceee/Facio/compare/Facio-v1.5.0...Facio-v1.5.1) (2026-04-01)


### Corrections de bugs

* **crypto:** allow wallet selection when multiple on same chain ([38b83fb](https://github.com/Juiiceee/Facio/commit/38b83fb610d0ccdbf89121c2487c632e94193da5))
* **pdf:** remove wallet label from PDF output ([c17a14a](https://github.com/Juiiceee/Facio/commit/c17a14a9247c8e479e95392a1f8811d86ff01610))
* **security:** harden file permissions, input validation and auth flow ([885801f](https://github.com/Juiiceee/Facio/commit/885801f3f8983d957a013e2756a82e03772dbb48))
* **sync:** add missing wallet label, bank name and wallet id fields ([2d39cf7](https://github.com/Juiiceee/Facio/commit/2d39cf77c4bccb3563d27cb3ff9275a8d8c8c089))


### Refactorings

* migrate config to .env, remove unused files and dead code ([ccce71c](https://github.com/Juiiceee/Facio/commit/ccce71c7d3df7be64685611a3faa4658ef6b4930))


### Ameliorations

* **settings:** add wallet label and bank name fields ([dc6d80a](https://github.com/Juiiceee/Facio/commit/dc6d80a0fac7becf2b05efdf0128e4a812f559ba))
* **timesheet:** add month picker and auto-repair truncated weeks ([e8b5247](https://github.com/Juiiceee/Facio/commit/e8b5247058b3792a271597a70087eb5de7bd6689))

## [1.5.0](https://github.com/Juiiceee/Facio/compare/Facio-v1.4.1...Facio-v1.5.0) (2026-03-31)


### Nouvelles fonctionnalites

* **sync:** normalized DB schema and email-only auth ([fb602b8](https://github.com/Juiiceee/Facio/commit/fb602b8c85ca38d53a57ed5c114947d5d03c3ea8))


### Corrections de bugs

* **auth:** replace password auth with email OTP verification ([f572c9d](https://github.com/Juiiceee/Facio/commit/f572c9d78c452714397fcfe9ec65e74cdae03913))
* **build:** add codesign and DMG with install instructions ([fc62e2a](https://github.com/Juiiceee/Facio/commit/fc62e2ab88bdfed3907d79fcb430757343521176))
* **security:** inject Supabase secrets at build time via CI ([72c1eca](https://github.com/Juiiceee/Facio/commit/72c1eca4bca4016e3800dc3f3eeb39ac5a529d67))
* **security:** move Supabase credentials out of source code ([1256b82](https://github.com/Juiiceee/Facio/commit/1256b82e842dcf826fef6936ac2dee8b81e0b56d))

## [1.4.1](https://github.com/Juiiceee/Facio/compare/Facio-v1.4.0...Facio-v1.4.1) (2026-03-31)


### Corrections de bugs

* **ui:** fix "Deviss" typo and status badge truncation ([bb491b2](https://github.com/Juiiceee/Facio/commit/bb491b204b28cdc33ae219bf8006f533057e25b8))
* **ui:** redesign settings and make entire app responsive ([5134005](https://github.com/Juiiceee/Facio/commit/51340055b5911122a606ded2917c3fd535b3f1cb))


### Ameliorations

* **ui:** replace Form/grouped style with GroupBox layout, add adaptive grids for dashboard and timesheet, reduce minimum window size to 900x600, use scrollable tab bar in settings ([5134005](https://github.com/Juiiceee/Facio/commit/51340055b5911122a606ded2917c3fd535b3f1cb))

## [1.4.0](https://github.com/Juiiceee/Facio/compare/Facio-v1.3.0...Facio-v1.4.0) (2026-03-30)


### Nouvelles fonctionnalites

* add first launch alert to FacioApp ([8ce310d](https://github.com/Juiiceee/Facio/commit/8ce310dfa196ff9f085f630f7fc464c993712bb3))
* add reset functionality to DataStore and update SettingsInlineView ([f7692d9](https://github.com/Juiiceee/Facio/commit/f7692d964fd483a43feda71f23694e411575559b))


### Documentation

* update README with macOS app launch instructions ([5dd9629](https://github.com/Juiiceee/Facio/commit/5dd96297a2eda9feeb13a0490be18a6d8a76cc54))

## [1.3.0](https://github.com/Juiiceee/Facio/compare/Facio-v1.2.0...Facio-v1.3.0) (2026-03-30)


### Nouvelles fonctionnalites

* add timesheet management functionality to DataStore and UI ([b2fce1d](https://github.com/Juiiceee/Facio/commit/b2fce1d2d4f3adff78b1dc9a74e1e3b2caaee613))
* display weekly cost in TimesheetEditorView ([06e500c](https://github.com/Juiiceee/Facio/commit/06e500c0233586bde370e7a16b422c8848b1f417))
* integrate sync and authentication services into FacioApp and DataStore ([db1fa36](https://github.com/Juiiceee/Facio/commit/db1fa3627f8d702918cefea3ee63f502bd00c5ff))

## [1.2.0](https://github.com/Juiiceee/Facio/compare/Facio-v1.1.0...Facio-v1.2.0) (2026-03-30)


### Nouvelles fonctionnalites

* setup Release Please CI/CD avec build .app automatique ([afc5cad](https://github.com/Juiiceee/Facio/commit/afc5cad3d429300852c3a4a412ce242185922ffe))


### Corrections de bugs

* use config file for release-please and remove package-name ([98c7b08](https://github.com/Juiiceee/Facio/commit/98c7b0877255dd26b39b2e59ad60a00d5037bc90))

## [1.1.0](https://github.com/Juiiceee/generateurFactureDevis/compare/GenerateurFiles-v1.0.0...GenerateurFiles-v1.1.0) (2026-03-30)


### Nouvelles fonctionnalites

* setup Release Please CI/CD avec build .app automatique ([afc5cad](https://github.com/Juiiceee/generateurFactureDevis/commit/afc5cad3d429300852c3a4a412ce242185922ffe))


### Corrections de bugs

* use config file for release-please and remove package-name ([98c7b08](https://github.com/Juiiceee/generateurFactureDevis/commit/98c7b0877255dd26b39b2e59ad60a00d5037bc90))
