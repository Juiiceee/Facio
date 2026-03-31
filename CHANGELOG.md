# Changelog

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
