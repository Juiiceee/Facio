# Changelog

## [2.7.0](https://github.com/Juiiceee/Facio/compare/Facio-v2.6.0...Facio-v2.7.0) (2026-08-18)


### Nouvelles fonctionnalites

* **dashboard:** hover a bar for its amount, click it for the invoices behind it ([5dcf653](https://github.com/Juiiceee/Facio/commit/5dcf6536e61097171e0410581e29ae45b39583ef))
* **dashboard:** let the order of the blocks be a setting ([9177033](https://github.com/Juiiceee/Facio/commit/9177033bb9241a1158bd9ba9d310e9fc0430da13))
* **design:** finish the component catalogue — button, field, panel, toast ([4a5fa1c](https://github.com/Juiiceee/Facio/commit/4a5fa1c431f98de4dc0eb24aa7d8f6eb020bb0bc))
* **design:** give the dashboard a series and a basis (P3, direction 1a) ([2a3c8d0](https://github.com/Juiiceee/Facio/commit/2a3c8d011fc7a5892f8f68b98ab85f03cfc170f1))
* **design:** line items — header everywhere, free VAT, written errors (P5) ([a0cc7aa](https://github.com/Juiiceee/Facio/commit/a0cc7aa744b9d73ed7ef1c9e96406562ac4fecb0))
* **design:** make the document lifecycle drive the editor (P5) ([493db07](https://github.com/Juiiceee/Facio/commit/493db07fdb3c98e605c686df11af01d81eacc709))
* **design:** make the PDF a real invoice (P14, direction 2a) ([ddd367b](https://github.com/Juiiceee/Facio/commit/ddd367bfea9c23eb648964fdc15bab4f050590d7))
* **design:** one stable three-column shell, five destinations ([d67789b](https://github.com/Juiiceee/Facio/commit/d67789b0e4beb5f233261322188be94414968ea3))
* **design:** permanent compliance inspector, deposits against the totals (P5) ([a8b611b](https://github.com/Juiiceee/Facio/commit/a8b611b2cc78ac097ff6ae2ee470a13622851556))
* **design:** promote the timer to a window-level control ([d69b9ec](https://github.com/Juiiceee/Facio/commit/d69b9ec618460ff19cba6ba8681c144c2807012c))
* **design:** put the component catalogue on the new token layer ([d87ac3d](https://github.com/Juiiceee/Facio/commit/d87ac3d107da9d2190b735f23fbc2cd0be2233dc))
* **design:** rebuild the lock screen (P13) ([83a5ee7](https://github.com/Juiiceee/Facio/commit/83a5ee7a8e37ca855e50ba10006c90be4dcb15bb))
* **design:** rebuild the token scale on the new foundations ([49e24b1](https://github.com/Juiiceee/Facio/commit/49e24b17c642b522b9dab7fab991518676e67128))
* **design:** rebuild the token scale on the new foundations ([ebf1fb4](https://github.com/Juiiceee/Facio/commit/ebf1fb4eac2bb24fa6bf160f102ee599d5fc3aa2))
* **design:** refonte de l'interface, écrans P1 à P14 ([118d3a3](https://github.com/Juiiceee/Facio/commit/118d3a3310b0f97ff0c227fbb29c8fde2cab3dc6))
* **security:** lock Facio behind a passcode ([#104](https://github.com/Juiiceee/Facio/issues/104)) ([1a4c070](https://github.com/Juiiceee/Facio/commit/1a4c07064fc439248ed7a33ac2404c022faaa555))
* **temps:** grid first, one capture system, one billing sheet with preview ([c4842e9](https://github.com/Juiiceee/Facio/commit/c4842e90682a4c3a77dab9b4be1600d5691caa1d))


### Corrections de bugs

* **clients:** link documents to clients by id, not by name ([#107](https://github.com/Juiiceee/Facio/issues/107)) ([a1853bf](https://github.com/Juiiceee/Facio/commit/a1853bf288b48d99664a2538fc240c2dc00b205e))
* **dashboard:** put the chart tooltip above the bar it describes ([5fc5467](https://github.com/Juiiceee/Facio/commit/5fc5467df01bec7739aee5afda9a6180563cb1a4))
* **dashboard:** show the accounting basis on the pending tile ([8deb582](https://github.com/Juiiceee/Facio/commit/8deb5820217e5b6f48c36d3179b1ae9740702c24))
* **diagnostics:** restore the brace lost in the merge ([535ea54](https://github.com/Juiiceee/Facio/commit/535ea545137ebb7519051e42b0016bf40dec9853))
* five defects found in the UX audit (copy, empty states, calendar, brand green) ([#106](https://github.com/Juiiceee/Facio/issues/106)) ([c36ada9](https://github.com/Juiiceee/Facio/commit/c36ada93393f3e34e29c0c8338316ac9335879ec))
* **pdf:** print with ⌘P, and stop the two exports sharing one filename ([e12a18d](https://github.com/Juiiceee/Facio/commit/e12a18d89bd8eb568899266f7927f6e5e6103c26))
* **security:** number the passcode steps and allow going back ([812d429](https://github.com/Juiiceee/Facio/commit/812d42995b96d8862748b4e9436cb72d1497c50c))
* **shell:** collapse the list column instead of railing it, and unpin Clients ([22e9fff](https://github.com/Juiiceee/Facio/commit/22e9fffc5c3039955ae6615b61dda0faa32e10a2))
* **shell:** give every toolbar item an explicit, unique identifier ([87fb0d2](https://github.com/Juiiceee/Facio/commit/87fb0d24e489ec102e872c273daf01f2f325dbfd))
* **shell:** publish the measured width outside AppKit's layout pass ([292b74a](https://github.com/Juiiceee/Facio/commit/292b74ada9ffad20b37e05ef493d49670b111e3f))
* **shell:** stop rebuilding the view tree inside AppKit's layout pass ([e2f427f](https://github.com/Juiiceee/Facio/commit/e2f427f2d070f42a1e251ab6430cdce966681e34))
* **ui:** left-align pickers, unify the settings sidebar, open company details ([2771e1b](https://github.com/Juiiceee/Facio/commit/2771e1bce1be23af5b2a6572db6488b074ff649f))
* **ui:** stop truncating amounts, align list rows, and unstack field hints ([192a8bc](https://github.com/Juiiceee/Facio/commit/192a8bcdf097a1f68e209388f7d257efe0ba07dd))

## [2.6.0](https://github.com/Juiiceee/Facio/compare/Facio-v2.5.0...Facio-v2.6.0) (2026-07-28)


### Nouvelles fonctionnalites

* **documents:** "Partiel" invoice status with deposit tracking ([#102](https://github.com/Juiiceee/Facio/issues/102)) ([0afc741](https://github.com/Juiiceee/Facio/commit/0afc7418bdb477649f8d4a4a16d816440edba6bf))
* **ui:** privacy mode — hide all on-screen amounts (eye toggle) ([#99](https://github.com/Juiiceee/Facio/issues/99)) ([b22b205](https://github.com/Juiiceee/Facio/commit/b22b205ce72f8e1d0379623f4adfff23bb947a54))

## [2.5.0](https://github.com/Juiiceee/Facio/compare/Facio-v2.4.0...Facio-v2.5.0) (2026-06-25)


### Nouvelles fonctionnalites

* **documents:** record payment date and bucket monthly revenue by it ([#98](https://github.com/Juiiceee/Facio/issues/98)) ([887c572](https://github.com/Juiiceee/Facio/commit/887c5727ac8c1ebd7832075e270fa540a0fb8d21))
* **lists:** sort & Notion-style filters for invoices, quotes and clients ([#97](https://github.com/Juiiceee/Facio/issues/97)) ([aeb83bd](https://github.com/Juiiceee/Facio/commit/aeb83bd823c60b4e743cd3a243c16ef521b68448))


### Corrections de bugs

* **documents:** resync DecimalField text when bound value changes ([#95](https://github.com/Juiiceee/Facio/issues/95)) ([3a9bde0](https://github.com/Juiiceee/Facio/commit/3a9bde0440fe580700e3c157dfd64b357482ef6a))

## [2.4.0](https://github.com/Juiiceee/Facio/compare/Facio-v2.3.1...Facio-v2.4.0) (2026-06-24)


### Nouvelles fonctionnalites

* **facturx:** EN 16931 Factur-X e-invoice generation (Phase 1) ([#93](https://github.com/Juiiceee/Facio/issues/93)) ([d04301d](https://github.com/Juiiceee/Facio/commit/d04301d3c23c3524ff3e6246b51d5a9aac194611))

## [2.3.1](https://github.com/Juiiceee/Facio/compare/Facio-v2.3.0...Facio-v2.3.1) (2026-06-16)


### Corrections de bugs

* **email:** nommer les pièces jointes d'après leur libellé ([#90](https://github.com/Juiiceee/Facio/issues/90)) ([455756f](https://github.com/Juiiceee/Facio/commit/455756f3461e517494d1443fce27edfb4aac9c4c))


### Documentation

* translate git workflow section to English ([c2bcde1](https://github.com/Juiiceee/Facio/commit/c2bcde15ab1cb816feb42ed65665694329646afc))
* workflow git (issue + branche + PR, jamais de commit direct sur main) ([0869e5a](https://github.com/Juiiceee/Facio/commit/0869e5aead5e0023380b5a28d4b181b62ebdcac6))

## [2.3.0](https://github.com/Juiiceee/Facio/compare/Facio-v2.2.0...Facio-v2.3.0) (2026-06-15)


### Nouvelles fonctionnalites

* **justificatifs:** aperçu intégré, report en ligne, TVA par ligne ([#88](https://github.com/Juiiceee/Facio/issues/88)) ([4b0ff5d](https://github.com/Juiiceee/Facio/commit/4b0ff5da50bfe3bffef3a1b385e937f0a8494dfe))

## [2.2.0](https://github.com/Juiiceee/Facio/compare/Facio-v2.1.2...Facio-v2.2.0) (2026-06-11)


### Nouvelles fonctionnalites

* **design:** design-system overhaul for a consistent, responsive UI ([#75](https://github.com/Juiiceee/Facio/issues/75)) ([ce39d70](https://github.com/Juiiceee/Facio/commit/ce39d7090b3bec5f67950aaa2f205e89c5fcc029))
* **documents:** attach expense receipts to invoices and send by email ([#78](https://github.com/Juiiceee/Facio/issues/78)) ([b1f4bda](https://github.com/Juiiceee/Facio/commit/b1f4bdad1de8806aab97f10ebf656ddfede0eef7))
* **ux:** retours visuels — toasts, confirmations et CTA ([#85](https://github.com/Juiiceee/Facio/issues/85)) ([1c0d546](https://github.com/Juiiceee/Facio/commit/1c0d5467fbfa4e13f86af59b91ec711c19fce54b))


### Corrections de bugs

* **documents:** corriger les fragilités email & justificatifs ([#79](https://github.com/Juiiceee/Facio/issues/79)) ([100a151](https://github.com/Juiiceee/Facio/commit/100a15105869cc9ec4a4532fb3d7d7ad6d27d980))


### Refactorings

* **design:** adoption complète du design system ([#82](https://github.com/Juiiceee/Facio/issues/82)) ([c681c43](https://github.com/Juiiceee/Facio/commit/c681c43e750aad4df534e462367a7b4e1c1fe331))


### Ameliorations

* **pdf:** rafraîchir la mise en page de la facture ([#81](https://github.com/Juiiceee/Facio/issues/81)) ([abdf0b2](https://github.com/Juiiceee/Facio/commit/abdf0b2fd2249c1d4bd809399c1ccb70a556f9de))
* **theme:** dark mode soigné — variantes sombres des tokens ([#86](https://github.com/Juiiceee/Facio/issues/86)) ([3278c97](https://github.com/Juiiceee/Facio/commit/3278c97305827fdc1ac8b7d8e1459a30e3db06f5))
* **ui:** FacioMotion tokens and whitelisted micro-interactions ([#84](https://github.com/Juiiceee/Facio/issues/84)) ([e24f829](https://github.com/Juiiceee/Facio/commit/e24f8292e228e51b734ab29b221107672ddd44bb))
* **ui:** responsivité — layouts adaptatifs et fenêtre minimale 960 pt ([#83](https://github.com/Juiiceee/Facio/issues/83)) ([6075c02](https://github.com/Juiiceee/Facio/commit/6075c0248c810c6ffff6a0aec22952e0363380fa))

## [2.1.2](https://github.com/Juiiceee/Facio/compare/Facio-v2.1.1...Facio-v2.1.2) (2026-05-30)


### Corrections de bugs

* **data:** fail closed on malformed JSON fields ([#71](https://github.com/Juiiceee/Facio/issues/71)) ([46ffa34](https://github.com/Juiiceee/Facio/commit/46ffa345a4507960b63bf6b9ba8d209cde791e2c))
* **security:** encrypt local persistence files ([#72](https://github.com/Juiiceee/Facio/issues/72)) ([ce7e21f](https://github.com/Juiiceee/Facio/commit/ce7e21ffd590ece69956a3770344804067a689b0))
* **sync:** distrust remote payment snapshots ([#70](https://github.com/Juiiceee/Facio/issues/70)) ([863bc09](https://github.com/Juiiceee/Facio/commit/863bc096f46b08a7e305ddace36f0157ba16d0d7))

## [2.1.1](https://github.com/Juiiceee/Facio/compare/Facio-v2.1.0...Facio-v2.1.1) (2026-05-29)


### Corrections de bugs

* **i18n:** localize remaining user-facing strings ([#68](https://github.com/Juiiceee/Facio/issues/68)) ([be126fb](https://github.com/Juiiceee/Facio/commit/be126fb4495458b70c886c5abd35b29a9ea054d2))

## [2.1.0](https://github.com/Juiiceee/Facio/compare/Facio-v2.0.0...Facio-v2.1.0) (2026-05-29)


### Nouvelles fonctionnalites

* add first launch alert to FacioApp ([2f38440](https://github.com/Juiiceee/Facio/commit/2f38440b5f804ed18cc32d616dfd3a2cac5aac59))
* add reset functionality to DataStore and update SettingsInlineView ([adb281f](https://github.com/Juiiceee/Facio/commit/adb281fd4d985dfe28c806cccb80d8ce354c06f0))
* add timesheet management functionality to DataStore and UI ([db73415](https://github.com/Juiiceee/Facio/commit/db7341523bedfffced7a3ecff3175d44bc5f7a37))
* display weekly cost in TimesheetEditorView ([d9d5d8c](https://github.com/Juiiceee/Facio/commit/d9d5d8cc3de527ac20f268fc9f11e6bb7d1da49f))
* **i18n:** add FR/EN language support per document and UI ([6c9eea6](https://github.com/Juiiceee/Facio/commit/6c9eea6c01826bef9c3bdd017c6fe892e4b3374c))
* integrate sync and authentication services into FacioApp and DataStore ([a6c0924](https://github.com/Juiiceee/Facio/commit/a6c0924e0c92760cbb63bb8c7a36801bcd274c55))
* **payments:** support multiple bank accounts ([81d6487](https://github.com/Juiiceee/Facio/commit/81d6487d69c744d35943a6417ddf668dbe477491))
* **pdf:** add Solana Pay QR code to crypto invoices ([f901964](https://github.com/Juiiceee/Facio/commit/f901964ef45a9e20952d169f76087799647479ff))
* **settings:** add Customisation tab with theme color picker ([4c7a524](https://github.com/Juiiceee/Facio/commit/4c7a5248fa594794ec17354d2b12815101f6a371))
* setup Release Please CI/CD avec build .app automatique ([bb32829](https://github.com/Juiiceee/Facio/commit/bb32829af5283c75d1f8f2e3c47b2605015d0aa7))
* **sync:** normalized DB schema and email-only auth ([fb602b8](https://github.com/Juiiceee/Facio/commit/fb602b8c85ca38d53a57ed5c114947d5d03c3ea8))
* **timesheets:** support client-scoped invoice generation ([84b21b5](https://github.com/Juiiceee/Facio/commit/84b21b5644b36aa67ec4eb38cc7c9ee833df4577))
* **timesheets:** support custom billing ranges ([dbc1938](https://github.com/Juiiceee/Facio/commit/dbc193836924f43decfba1c7ecdace46b7d09907))
* **web:** add GitHub Pages landing page for Facio ([bfe966a](https://github.com/Juiiceee/Facio/commit/bfe966a8f73881643efc4b96f89d8492e7feaa49))
* **web:** add GitHub Pages landing page for Facio ([2f93306](https://github.com/Juiiceee/Facio/commit/2f933065ce5e285a2e9be7e0c0ce40ab8d5bd0dd))


### Corrections de bugs

* **audit:** resolve payment and timesheet regressions ([e69c12a](https://github.com/Juiiceee/Facio/commit/e69c12aa424f9d25c32a77105affc22c49d72711)), closes [#61](https://github.com/Juiiceee/Facio/issues/61)
* **auth:** replace password auth with email OTP verification ([f572c9d](https://github.com/Juiiceee/Facio/commit/f572c9d78c452714397fcfe9ec65e74cdae03913))
* **auth:** secure Supabase sessions ([d615670](https://github.com/Juiiceee/Facio/commit/d615670dca2132e17bbd1ec40ef0470c0e7360b0))
* **build:** add codesign and DMG with install instructions ([fc62e2a](https://github.com/Juiiceee/Facio/commit/fc62e2ab88bdfed3907d79fcb430757343521176))
* **build:** copy SPM resource bundle into .app to prevent crash ([706f381](https://github.com/Juiiceee/Facio/commit/706f3818a9ae14e6aa61ba17dc1d6580a4143359))
* **build:** copy SPM resource bundle into .app to prevent crash ([11bbfe9](https://github.com/Juiiceee/Facio/commit/11bbfe9a30b870d88d625b67ca4545ae62abc50a))
* **crypto:** allow wallet selection when multiple on same chain ([38b83fb](https://github.com/Juiiceee/Facio/commit/38b83fb610d0ccdbf89121c2487c632e94193da5))
* **dashboard:** convert revenue to accounting currency ([2e816d3](https://github.com/Juiiceee/Facio/commit/2e816d33ac5fb38c842a5449ea703dc8b38f7e34))
* **data:** protect local JSON recovery ([f69a97a](https://github.com/Juiiceee/Facio/commit/f69a97a3e0e57ef3d7ea79e60078d6284f614ffb))
* harden Facio audit findings ([#56](https://github.com/Juiiceee/Facio/issues/56)) ([da891a1](https://github.com/Juiiceee/Facio/commit/da891a131a41a866d894f44a4fa94901242a43e6))
* **pdf:** isolate logo validation helpers ([1a2e597](https://github.com/Juiiceee/Facio/commit/1a2e5970f53b950c7c8e02f910a06c98725e0933))
* **pdf:** remove wallet label from PDF output ([c17a14a](https://github.com/Juiiceee/Facio/commit/c17a14a9247c8e479e95392a1f8811d86ff01610))
* **pdf:** render notes section in PDF output ([#25](https://github.com/Juiiceee/Facio/issues/25)) ([60f795f](https://github.com/Juiiceee/Facio/commit/60f795f4610871774fb6b3f4be3a1c786ab090b3))
* **pdf:** replace Bundle.module with safe resource loading ([1fac5e4](https://github.com/Juiiceee/Facio/commit/1fac5e4b69a563d5e7d801379a8f51f6e0bc3ff2))
* **pdf:** round QR code amount to 2 decimals to match invoice total ([54ed26f](https://github.com/Juiiceee/Facio/commit/54ed26f4abf47f33fae6a38c3b1f548088486254))
* **pdf:** round QR code amount to 2 decimals to match invoice total ([5d95fb7](https://github.com/Juiiceee/Facio/commit/5d95fb7005b90e2c2e6e4fa34a7c3ad4a682397e))
* **pdf:** sanitize exported documents ([fdce0c8](https://github.com/Juiiceee/Facio/commit/fdce0c8691e24712d2856b8650b5fe2515d9601c))
* **release:** allow ad-hoc publishing without Apple secrets ([176bb52](https://github.com/Juiiceee/Facio/commit/176bb52f47057bb01cde1c3b02ff94e968e9b0d0))
* **release:** harden macOS publishing ([aa5a67d](https://github.com/Juiiceee/Facio/commit/aa5a67d54a82657c661448773b38b9158d49b7c0))
* **security:** harden file permissions, input validation and auth flow ([885801f](https://github.com/Juiiceee/Facio/commit/885801f3f8983d957a013e2756a82e03772dbb48))
* **security:** inject Supabase secrets at build time via CI ([72c1eca](https://github.com/Juiiceee/Facio/commit/72c1eca4bca4016e3800dc3f3eeb39ac5a529d67))
* **security:** move Supabase credentials out of source code ([1256b82](https://github.com/Juiiceee/Facio/commit/1256b82e842dcf826fef6936ac2dee8b81e0b56d))
* **sync:** add missing wallet label, bank name and wallet id fields ([2d39cf7](https://github.com/Juiiceee/Facio/commit/2d39cf77c4bccb3563d27cb3ff9275a8d8c8c089))
* **sync:** harden Supabase data safety ([875eea8](https://github.com/Juiiceee/Facio/commit/875eea83696a9778bee9b38cfc506e3734898b61))
* **sync:** prevent reset from deleting remote data on next sync ([7208240](https://github.com/Juiiceee/Facio/commit/720824020e741d4a7601e03da971a6cb20250f7e))
* **sync:** remove unused variable warnings in SyncService ([98b8a80](https://github.com/Juiiceee/Facio/commit/98b8a803aacda097fc91d13e1f6b5693b91a5ef9))
* **timesheet:** sync overtime calculation across month boundaries ([ac0e1a3](https://github.com/Juiiceee/Facio/commit/ac0e1a36a6694744f72903abeeb0bd44a0c7f8b6))
* **ui:** expand clickable hit areas ([35cbdcc](https://github.com/Juiiceee/Facio/commit/35cbdcce6c8d34385667a7c698693c961e5cc06f))
* **ui:** expand settings tab hit area to full padding zone ([569f470](https://github.com/Juiiceee/Facio/commit/569f4703ce598380d492b8456c80ea8741d2d786))
* **ui:** fix "Deviss" typo and status badge truncation ([9fcc545](https://github.com/Juiiceee/Facio/commit/9fcc545b603c292dee9c90c3d6b235eba1518c6a))
* **ui:** improve responsive layout and minimum window sizing ([715aed7](https://github.com/Juiiceee/Facio/commit/715aed751c0740f6ee515c9e5d5f21e9d29873c6))
* **ui:** polish clients and overdue invoices ([d949830](https://github.com/Juiiceee/Facio/commit/d9498301461e743e24237b7c84fe1ac99dbb2b35))
* **ui:** redesign settings and make entire app responsive ([e30cc73](https://github.com/Juiiceee/Facio/commit/e30cc7355efd21816bfa46f80cc377ada02c3d74))
* **ui:** remove empty split panels ([01e1151](https://github.com/Juiiceee/Facio/commit/01e1151a55319932335d5a8dd3e05c4efc50ec24))
* **updates:** extract semver from tag like Facio-v1.8.0 for version comparison ([#33](https://github.com/Juiiceee/Facio/issues/33)) ([3a9b37d](https://github.com/Juiiceee/Facio/commit/3a9b37d0b30a1b2b03735753608ab811398b619a))
* use config file for release-please and remove package-name ([72601ec](https://github.com/Juiiceee/Facio/commit/72601ec4c9e8aaa8ff2bc3293beaf609debbae05))


### Refactorings

* **i18n:** split L10n.swift into domain-specific extensions ([5efe5af](https://github.com/Juiiceee/Facio/commit/5efe5afcb3dd0315f0b9bd18fb43ede7f9aa0f58))
* migrate config to .env, remove unused files and dead code ([ccce71c](https://github.com/Juiiceee/Facio/commit/ccce71c7d3df7be64685611a3faa4658ef6b4930))
* rename project from GenerateurFiles to Facio and remove unused files ([3f622e6](https://github.com/Juiiceee/Facio/commit/3f622e652c45489dc8175c766dc403a450783fea))


### Ameliorations

* **dmg:** add Security Settings shortcut app with gear icon ([d82fd04](https://github.com/Juiiceee/Facio/commit/d82fd046f72e79b91a5a6e2a3b4e4eca4c61f3ce))
* **dmg:** remove Security Settings app and clean up script ([3e75c4b](https://github.com/Juiiceee/Facio/commit/3e75c4bbf915ecaf7cacbcc09e32cdb66f22cdec))
* **pdf:** enlarge QR code, add Solana logo and align layout ([cf47d7a](https://github.com/Juiiceee/Facio/commit/cf47d7a547f85c6ad60027f24b338fe111124679))
* **settings:** add wallet label and bank name fields ([dc6d80a](https://github.com/Juiiceee/Facio/commit/dc6d80a0fac7becf2b05efdf0128e4a812f559ba))
* **timesheet:** add month picker and auto-repair truncated weeks ([e8b5247](https://github.com/Juiiceee/Facio/commit/e8b5247058b3792a271597a70087eb5de7bd6689))
* **ui:** redesign core workflows ([f0eb7e9](https://github.com/Juiiceee/Facio/commit/f0eb7e9adcf220b830c65cbf1dd645b52b8d1635))
* **ui:** replace Form/grouped style with GroupBox layout, add adaptive grids for dashboard and timesheet, reduce minimum window size to 900x600, use scrollable tab bar in settings ([e30cc73](https://github.com/Juiiceee/Facio/commit/e30cc7355efd21816bfa46f80cc377ada02c3d74))


### Documentation

* add repository contributor guide ([5821f6d](https://github.com/Juiiceee/Facio/commit/5821f6d37cc9eec4ac88c06b79364c00b29794bc))
* update README with macOS app launch instructions ([376c380](https://github.com/Juiiceee/Facio/commit/376c380553d0c1af32b8f0a64140b91857f063ff))

## [1.10.2](https://github.com/Juiiceee/Facio/compare/Facio-v1.10.1...Facio-v1.10.2) (2026-05-14)


### Ameliorations

* **ui:** redesign core workflows ([f0eb7e9](https://github.com/Juiiceee/Facio/commit/f0eb7e9adcf220b830c65cbf1dd645b52b8d1635))

## [1.10.1](https://github.com/Juiiceee/Facio/compare/Facio-v1.10.0...Facio-v1.10.1) (2026-05-13)


### Corrections de bugs

* **audit:** resolve payment and timesheet regressions ([e69c12a](https://github.com/Juiiceee/Facio/commit/e69c12aa424f9d25c32a77105affc22c49d72711)), closes [#61](https://github.com/Juiiceee/Facio/issues/61)

## [1.10.0](https://github.com/Juiiceee/Facio/compare/Facio-v1.9.0...Facio-v1.10.0) (2026-05-13)


### Nouvelles fonctionnalites

* **payments:** support multiple bank accounts ([81d6487](https://github.com/Juiiceee/Facio/commit/81d6487d69c744d35943a6417ddf668dbe477491))


### Corrections de bugs

* **ui:** polish clients and overdue invoices ([d949830](https://github.com/Juiiceee/Facio/commit/d9498301461e743e24237b7c84fe1ac99dbb2b35))

## [1.9.0](https://github.com/Juiiceee/Facio/compare/Facio-v1.8.3...Facio-v1.9.0) (2026-05-13)


### Nouvelles fonctionnalites

* **timesheets:** support client-scoped invoice generation ([84b21b5](https://github.com/Juiiceee/Facio/commit/84b21b5644b36aa67ec4eb38cc7c9ee833df4577))
* **timesheets:** support custom billing ranges ([dbc1938](https://github.com/Juiiceee/Facio/commit/dbc193836924f43decfba1c7ecdace46b7d09907))


### Corrections de bugs

* **dashboard:** convert revenue to accounting currency ([2e816d3](https://github.com/Juiiceee/Facio/commit/2e816d33ac5fb38c842a5449ea703dc8b38f7e34))
* **ui:** expand clickable hit areas ([35cbdcc](https://github.com/Juiiceee/Facio/commit/35cbdcce6c8d34385667a7c698693c961e5cc06f))
* **ui:** remove empty split panels ([01e1151](https://github.com/Juiiceee/Facio/commit/01e1151a55319932335d5a8dd3e05c4efc50ec24))

## [1.8.3](https://github.com/Juiiceee/Facio/compare/Facio-v1.8.2...Facio-v1.8.3) (2026-05-12)


### Corrections de bugs

* **release:** allow ad-hoc publishing without Apple secrets ([176bb52](https://github.com/Juiiceee/Facio/commit/176bb52f47057bb01cde1c3b02ff94e968e9b0d0))

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
