---
name: nestjs-patterns
description: モジュール、コントローラ、プロバイダ、DTO バリデーション、ガード、インターセプター、設定、本番グレード TypeScript バックエンドのための NestJS アーキテクチャパターン (NestJS architecture patterns for modules, controllers, providers, DTO validation, guards, interceptors, config, production-grade TypeScript backends)。
origin: ECC
---

# NestJS 開発パターン

モジュラー TypeScript バックエンドのための本番グレード NestJS パターン。

## 起動するタイミング

- NestJS API またはサービスの構築
- モジュール、コントローラ、プロバイダの構造化
- DTO バリデーション、ガード、インターセプター、または例外フィルタの追加
- 環境対応設定とデータベース統合の設定
- NestJS ユニットまたは HTTP エンドポイントのテスト

## プロジェクト構成

```text
src/
├── app.module.ts
├── main.ts
├── common/
│   ├── filters/
│   ├── guards/
│   ├── interceptors/
│   └── pipes/
├── config/
│   ├── configuration.ts
│   └── validation.ts
├── modules/
│   ├── auth/
│   │   ├── auth.controller.ts
│   │   ├── auth.module.ts
│   │   ├── auth.service.ts
│   │   ├── dto/
│   │   ├── guards/
│   │   └── strategies/
│   └── users/
│       ├── dto/
│       ├── entities/
│       ├── users.controller.ts
│       ├── users.module.ts
│       └── users.service.ts
└── prisma/ or database/
```

- ドメインコードをフィーチャーモジュール内に保つ
- 横断的なフィルタ、デコレータ、ガード、インターセプターを `common/` に置く
- DTO はそれを所有するモジュールの近くに保つ

## ブートストラップとグローバルバリデーション

```ts
async function bootstrap() {
  const app = await NestFactory.create(AppModule, { bufferLogs: true });

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      transformOptions: { enableImplicitConversion: true },
    }),
  );

  app.useGlobalInterceptors(new ClassSerializerInterceptor(app.get(Reflector)));
  app.useGlobalFilters(new HttpExceptionFilter());

  await app.listen(process.env.PORT ?? 3000);
}
bootstrap();
```

- 公開 API では常に `whitelist` と `forbidNonWhitelisted` を有効化する
- ルートごとにバリデーション設定を繰り返すのではなく、1 つのグローバルバリデーションパイプを優先する

## モジュール、コントローラ、プロバイダ

```ts
@Module({
  controllers: [UsersController],
  providers: [UsersService],
  exports: [UsersService],
})
export class UsersModule {}

@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get(':id')
  getById(@Param('id', ParseUUIDPipe) id: string) {
    return this.usersService.getById(id);
  }

  @Post()
  create(@Body() dto: CreateUserDto) {
    return this.usersService.create(dto);
  }
}

@Injectable()
export class UsersService {
  constructor(private readonly usersRepo: UsersRepository) {}

  async create(dto: CreateUserDto) {
    return this.usersRepo.create(dto);
  }
}
```

- コントローラは薄く保つ: HTTP 入力を解析し、プロバイダを呼び出し、レスポンス DTO を返す
- ビジネスロジックはコントローラではなく注入可能サービスに置く
- 他のモジュールが本当に必要とするプロバイダのみエクスポートする

## DTO とバリデーション

```ts
export class CreateUserDto {
  @IsEmail()
  email!: string;

  @IsString()
  @Length(2, 80)
  name!: string;

  @IsOptional()
  @IsEnum(UserRole)
  role?: UserRole;
}
```

- すべてのリクエスト DTO を `class-validator` で検証する
- ORM エンティティを直接返すのではなく、専用レスポンス DTO またはシリアライザを使う
- パスワードハッシュ、トークン、監査カラムなどの内部フィールドをリークさせない

## 認証、ガード、リクエストコンテキスト

```ts
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('admin')
@Get('admin/report')
getAdminReport(@Req() req: AuthenticatedRequest) {
  return this.reportService.getForUser(req.user.id);
}
```

- 本当に共有される場合を除き、認証ストラテジーとガードはモジュールローカルに保つ
- 粗いアクセスルールをガードにエンコードし、リソース固有の認可はサービスで行う
- 認証済みリクエストオブジェクトには明示的なリクエスト型を優先する

## 例外フィルタとエラー形状

```ts
@Catch()
export class HttpExceptionFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost) {
    const response = host.switchToHttp().getResponse<Response>();
    const request = host.switchToHttp().getRequest<Request>();

    if (exception instanceof HttpException) {
      return response.status(exception.getStatus()).json({
        path: request.url,
        error: exception.getResponse(),
      });
    }

    return response.status(500).json({
      path: request.url,
      error: 'Internal server error',
    });
  }
}
```

- API 全体で 1 つの一貫したエラーエンベロープを保つ
- 期待されるクライアントエラーにはフレームワーク例外をスローし、予期しない失敗はログに記録し集中的にラップする

## 設定と環境バリデーション

```ts
ConfigModule.forRoot({
  isGlobal: true,
  load: [configuration],
  validate: validateEnv,
});
```

- 最初のリクエスト時に遅延ではなく、ブート時に env を検証する
- 設定アクセスを型付きヘルパーまたは設定サービスの背後に保つ
- フィーチャーコード全体で分岐するのではなく、設定ファクトリで dev/staging/prod の懸念を分割する

## 永続化とトランザクション

- リポジトリ / ORM コードをドメイン言語を話すプロバイダの背後に保つ
- Prisma または TypeORM の場合、トランザクションワークフローを作業単位を所有するサービスに分離する
- コントローラがマルチステップ書き込みを直接調整させない

## テスト

```ts
describe('UsersController', () => {
  let app: INestApplication;

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      imports: [UsersModule],
    }).compile();

    app = moduleRef.createNestApplication();
    app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true }));
    await app.init();
  });
});
```

- モック依存関係でプロバイダを分離してユニットテストする
- ガード、バリデーションパイプ、例外フィルタにリクエストレベルテストを追加する
- 本番で使うのと同じグローバルパイプ/フィルタをテストでも再利用する

## 本番デフォルト

- 構造化ログとリクエスト相関 ID を有効化する
- 部分的にブートする代わりに、無効な env/設定で終了する
- 明示的ヘルスチェックを備えた DB/キャッシュクライアントには非同期プロバイダ初期化を優先する
- バックグラウンドジョブとイベントコンシューマーを HTTP コントローラ内部ではなく独自モジュールに保つ
- 公開エンドポイントにはレート制限、認証、監査ログを明示的にする
