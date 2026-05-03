# インフラ設計書

**プロジェクト名**: No, You Are Not  
**作成日**: 2026-05-02  
**バージョン**: 1.0

---

## 1. 概要

セルフマネジメントアプリ「No, You Are Not」のインフラ構成を定義する。  
フロントエンドはiOSアプリとしてApple App Storeで配布し、バックエンドAPIおよびデータベースはGoogle Cloud Platform（GCP）上で運用する。

### 1.1 設計方針

- **コスト最小化**: スケールtoゼロが可能なマネージドサービスを優先採用
- **スケーラビリティ**: 利用者増加に応じてサービス単位でスケールアップ可能な構成
- **セキュリティ**: データベースはプライベートネットワークに配置し、外部から直接アクセス不可
- **運用負荷の最小化**: フルマネージドサービスを採用し、インフラ管理コストを抑制

---

## 2. アーキテクチャ図

```
┌─────────────────────────────────────────────────────────────┐
│                        ユーザー                              │
│                    (iPhone / iOS App)                        │
└───────────────────────────┬─────────────────────────────────┘
                            │ ダウンロード
                ┌───────────▼────────────┐
                │   Apple App Store      │
                │   (iOS アプリ配布)     │
                └────────────────────────┘

                            │ HTTPS (REST API)
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    Google Cloud Platform                     │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │                   Cloud Run                          │  │
│  │              NestJS API (コンテナ)                   │  │
│  │         0.25 vCPU / 512MB RAM / min=0               │  │
│  └────────────┬──────────────────────┬─────────────────┘  │
│               │ TCP:5432 (内部通信)   │ シークレット取得     │
│               ▼                      ▼                      │
│  ┌────────────────────┐  ┌──────────────────────────────┐  │
│  │    Cloud SQL       │  │      Secret Manager          │  │
│  │  PostgreSQL 17     │  │  - DATABASE_URL              │  │
│  │  db-f1-micro       │  │  - OPENAI_API_KEY            │  │
│  │  10GB SSD          │  └──────────────────────────────┘  │
│  └────────────────────┘                                     │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │               Artifact Registry                      │  │
│  │         (NestJS Dockerイメージ保管)                  │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                            │ HTTPS
                            ▼
                ┌───────────────────────┐
                │     OpenAI API        │
                │   (外部サービス)      │
                └───────────────────────┘
```

---

## 3. 構成コンポーネント詳細

### 3.1 iOSアプリ（Apple App Store）

| 項目 | 内容 |
|---|---|
| フレームワーク | Flutter (Dart) |
| 配布方法 | Apple App Store |
| 対象OS | iOS 16以上 |
| バックエンド接続 | Cloud Run の HTTPS エンドポイント |
| 認証 | JWT（バックエンドで発行） |

**ビルド・リリースフロー**:
```
flutter build ios --release
  → Xcode でアーカイブ
  → App Store Connect へアップロード
  → TestFlight でテスト
  → App Store 審査・公開
```

### 3.2 Cloud Run（NestJS API）

| 項目 | 内容 |
|---|---|
| イメージ | Artifact Registry に保管されたDockerイメージ |
| リージョン | `asia-northeast1`（東京） |
| vCPU | 0.25（最小） |
| メモリ | 512MB |
| 最小インスタンス数 | 0（スケールtoゼロ） |
| 最大インスタンス数 | 10（オートスケール） |
| 同時接続数 | 80（デフォルト） |
| タイムアウト | 30秒 |
| 認証 | 未認証リクエストを許可（JWT でアプリレベル認証） |

**エンドポイント**: `https://[service-name]-[hash]-an.a.run.app`

> **コールドスタートについて**: min-instances=0 のため、一定時間リクエストがない場合に再起動が発生し、初回レスポンスに2〜5秒の遅延が生じる可能性がある。MVP フェーズでは許容する。

### 3.3 Cloud SQL（PostgreSQL）

| 項目 | 内容 |
|---|---|
| データベースエンジン | PostgreSQL 17 |
| インスタンスタイプ | `db-f1-micro`（共有vCPU / 0.6GB RAM） |
| リージョン | `asia-northeast1`（東京） |
| ゾーン構成 | シングルゾーン（HA なし） |
| ストレージ | 10GB SSD（自動拡張有効） |
| バックアップ | 自動バックアップ 1世代（7日間保持） |
| 接続方法 | Cloud SQL Auth Proxy 経由（Cloud Runとの内部接続） |
| パブリックIP | 無効（プライベートIPのみ） |

**スキーマ構成**（Prismaで管理）:

```
User → Goal (1:N)
User → Conversation (1:N)
Conversation → Message (1:N)
Goal → Conversation (1:N, optional)
```

### 3.4 Artifact Registry

| 項目 | 内容 |
|---|---|
| リージョン | `asia-northeast1`（東京） |
| リポジトリ名 | `no-you-are-not` |
| フォーマット | Docker |
| 保持ポリシー | 最新5世代のみ保持（古いイメージは自動削除） |

### 3.5 Secret Manager

| シークレット名 | 内容 |
|---|---|
| `openai-api-key` | OpenAI API キー |
| `database-url` | Cloud SQL 接続文字列 |
| `jwt-secret` | JWT 署名シークレット |

Cloud Run のサービスアカウントに `roles/secretmanager.secretAccessor` を付与してアクセス。

---

## 4. ネットワーク設計

```
Internet
  │
  │ HTTPS (443)
  ▼
Cloud Run（パブリックエンドポイント）
  │
  │ VPC 内部通信（Cloud SQL Auth Proxy）
  ▼
Cloud SQL（プライベートIP のみ）
```

- Cloud Run → Cloud SQL: **VPC コネクタ**または **Cloud SQL Auth Proxy** 経由で接続
- Cloud SQL はパブリックIPを持たず、外部から直接アクセス不可
- HTTPS は Cloud Run が自動で終端し、TLS証明書を管理

---

## 5. セキュリティ設計

### 5.1 認証・認可

| レイヤー | 方式 |
|---|---|
| iOSアプリ ↔ Cloud Run | JWT（Bearer Token） |
| Cloud Run ↔ Cloud SQL | Cloud SQL Auth Proxy（IAMベース） |
| Cloud Run ↔ Secret Manager | サービスアカウント + IAMロール |

### 5.2 IAM ロール設計

| サービスアカウント | 付与ロール |
|---|---|
| Cloud Run SA | `roles/cloudsql.client` |
| Cloud Run SA | `roles/secretmanager.secretAccessor` |
| CI/CD SA | `roles/run.developer` |
| CI/CD SA | `roles/artifactregistry.writer` |

### 5.3 データ保護

- **通信経路**: 全通信をHTTPS/TLSで暗号化
- **保存データ**: Cloud SQL のデータはGoogleマネージドキーで暗号化（デフォルト）
- **APIキー**: コードや環境変数に直書きせず、Secret Manager で管理

---

## 6. デプロイフロー

```
開発者
  │
  │ git push
  ▼
GitHub（ソースコード管理）
  │
  │ GitHub Actions（CI/CD）
  ▼
┌─────────────────────────────────────────┐
│ 1. テスト実行（jest）                   │
│ 2. Docker ビルド                        │
│ 3. Artifact Registry へ push            │
│ 4. Cloud Run へ新リビジョンをデプロイ   │
│ 5. prisma migrate deploy（マイグレーション）│
└─────────────────────────────────────────┘
```

**iOSアプリのリリースフロー**:
```
flutter build ios --release
  → Xcode Archive
  → App Store Connect アップロード
  → TestFlight テスト（内部/外部）
  → App Store 審査申請（通常1〜3営業日）
  → 公開
```

---

## 7. スケールアップ戦略

| フェーズ | 想定DAU | 主な変更点 |
|---|---|---|
| MVP | 〜100 | 現構成のまま |
| 成長期 | 〜1,000 | Cloud SQL → `db-g1-small` 昇格 / min-instances=1 |
| 本格運用 | 1,000〜 | Cloud SQL HA（マルチゾーン）/ カスタムドメイン + Cloud DNS |
