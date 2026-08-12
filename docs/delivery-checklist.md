# Delivery Checklist

## 基準日時

- 納品基準日時: 2026/08/13 12:00 JST
- この日時以降に納品可否を判断する場合も、ドキュメント上の完成基準日時は上記に統一する。
- Git commit 日時や既存ファイルの mtime は納品基準日時に合わせて書き換えない。

## Repository Gate

- [ ] `main` branch である
- [ ] `origin/main` と同期済みである
- [ ] working tree が clean である
- [ ] 不要な作業 branch が残っていない
- [ ] Dependabot 等の不要 branch が整理済みである
- [ ] push 前提の未 commit 変更がない

## CI / Quality Gate

以下がすべて PASS していること。

```bash
bin/rubocop -f github
bin/bundler-audit
bin/rails db:test:prepare test
bin/rails test:system
```

確認項目:

- [ ] RuboCop PASS
- [ ] bundler-audit PASS
- [ ] Rails unit / controller / integration tests PASS
- [ ] system tests PASS
- [ ] 新規脆弱性なし
- [ ] Rails / Active Storage 8.1.3.1
- [ ] json 2.21.2
- [ ] libvips 8.13 以上

## Article / Content Gate

- [ ] 記事 1〜10 が存在する
- [ ] 記事 1〜10 が published である
- [ ] `display_order` が 1〜10 である
- [ ] 公開 `/articles` が `display_order ASC, id ASC` で表示される
- [ ] 管理画面の記事一覧が `display_order ASC, id ASC` で表示される
- [ ] 記事 1〜5 が Markdown として表示される
- [ ] 記事 6〜10 が Rich Text / Jodit HTML として表示される
- [ ] 記事 10 に未使用画像 `10-exercise-flow.png` を本文へ勝手に追加していない

## Image / Active Storage Gate

seed 画像正本:

- `docs/assets/articles/01-data-use-cases.png`
- `docs/assets/articles/02-analysis-process.png`
- `docs/assets/articles/03-python-libraries.png`
- `docs/assets/articles/04-variables-and-types.png`
- `docs/assets/articles/05-list-vs-dictionary.png`
- `docs/assets/articles/06-csv-to-table.png`
- `docs/assets/articles/07-data-cleaning.png`
- `docs/assets/articles/08-outliers-effect.png`
- `docs/assets/articles/09-four-charts.png`
- `docs/assets/articles/10-exercise-flow.png`（正本として保持。現状本文未使用）

確認項目:

- [ ] 記事 1〜5 の thumbnail が表示される
- [ ] 記事 6〜9 の本文画像が表示される
- [ ] Rich Text 本文内の画像位置が完成 Baseline と一致する
- [ ] seed 後に作成された blob の SHA256 が `docs/assets/articles/*.png` と一致する
- [ ] development 環境の signed_id / blob ID / attachment ID / host / secret 依存値を納品物に含めていない
- [ ] development `storage/` を納品しない
- [ ] 不要 blob を納品しない

## Seed Rebuild Gate

clean 環境または disposable DB で以下を確認する。

```bash
bin/rails db:drop db:create db:migrate db:seed
bin/rails db:seed
```

確認項目:

- [ ] 空 DB から migration が成功する
- [ ] 空 DB から seed が成功する
- [ ] 初期管理者が環境変数指定時に作成される
- [ ] 記事 1〜10 が seed で再構築される
- [ ] 2 回目の seed で既存記事を上書きしない
- [ ] seed 後の本文が完成 Baseline と実質一致する
- [ ] seed 後の画像 filename / 画像位置が完成 Baseline と一致する
- [ ] seed 後に不要な unattached blob が作成されない

## Security / Exclusion Gate

納品 ZIP に以下を含めない。

- [ ] `.git/`
- [ ] `.env`
- [ ] `config/master.key`
- [ ] credentials 復号鍵
- [ ] API key / password / token
- [ ] development DB / test DB / DB dump
- [ ] development `storage/`
- [ ] `tmp/`
- [ ] `log/`
- [ ] ローカルパスや個人情報を含む設定
- [ ] CI 一時生成物
- [ ] テスト生成物

## Minimal Delivery Package Gate

推奨する納品方式:

- アプリケーションコード一式
- `Gemfile` / `Gemfile.lock`
- `config/`（秘密鍵を除く）
- `db/`（migration と正式 seed を含む）
- `docs/articles/`
- `docs/assets/articles/`
- README / delivery checklist
- `storage/` は含めない
- 顧客環境で seed により Active Storage blob を再作成する

納品 ZIP 作成前に確認すること。

- [ ] ZIP 内容を展開して目視確認した
- [ ] README 通りに第三者が起動できる
- [ ] clean 環境から記事 1〜10 と画像を再現できる
- [ ] 不要ファイル・秘密情報が含まれていない
