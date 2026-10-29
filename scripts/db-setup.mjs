// Cria todas as tabelas do Tríade no Supabase executando supabase/setup_complete_triade_db.sql.
// Uso: npm run db:setup   (requer DIRECT_URL com a senha real do banco no arquivo .env)
import { spawnSync } from 'node:child_process';

const url = process.env.DIRECT_URL || process.env.SUPABASE_DB_URL;

if (!url || url.includes('[YOUR-PASSWORD]')) {
  console.error(
    '\n[db:setup] DIRECT_URL não configurada.\n' +
    'Edite o arquivo .env e substitua [YOUR-PASSWORD] pela senha do banco\n' +
    '(Supabase > Project Settings > Database > Database password).\n'
  );
  process.exit(1);
}

console.log('[db:setup] Executando supabase/setup_complete_triade_db.sql ...');
const result = spawnSync(
  'npx',
  ['prisma', 'db', 'execute', '--file', 'supabase/setup_complete_triade_db.sql', '--url', url],
  { stdio: 'inherit', shell: true }
);

if (result.status !== 0) {
  console.error('[db:setup] Falha ao executar o script SQL.');
  process.exit(result.status ?? 1);
}
console.log('[db:setup] Tabelas criadas com sucesso! Recarregue o sistema (Ctrl + Shift + R).');

