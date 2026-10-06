import { join } from 'node:path';
import { DataSource } from 'typeorm';
import { resolveAppEnv } from '../../config/app.config';

async function main(): Promise<void> {
  const appEnv = resolveAppEnv();
  if (appEnv === 'development') {
    throw new Error('Migrations require APP_ENV=staging or production.');
  }

  const required = ['DB_HOST', 'DB_NAME', 'DB_USER', 'DB_PASSWORD'];
  for (const name of required) {
    if (!process.env[name]?.trim()) throw new Error(`${name} is required`);
  }

  const dataSource = new DataSource({
    type: 'postgres',
    host: process.env.DB_HOST,
    port: Number(process.env.DB_PORT ?? '5432'),
    database: process.env.DB_NAME,
    username: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    synchronize: false,
    migrations: [join(__dirname, 'migrations', '*.js')],
    migrationsTransactionMode: 'all',
  });

  await dataSource.initialize();
  try {
    // The existing migrations are incremental. Refuse to apply them to an empty
    // database until a complete baseline migration has been introduced.
    const [{ users, recipes }] = await dataSource.query<
      Array<{ users: string | null; recipes: string | null }>
    >(
      "SELECT to_regclass('public.users') AS users, to_regclass('public.recipes') AS recipes",
    );
    if (!users || !recipes) {
      throw new Error(
        'Database baseline is missing (users/recipes). Restore or migrate the baseline before deployment.',
      );
    }
    const migrations = await dataSource.runMigrations();
    console.log(`Applied ${migrations.length} migration(s).`);
  } finally {
    await dataSource.destroy();
  }
}

main().catch((error: unknown) => {
  console.error('Database migration failed:', error);
  process.exitCode = 1;
});
