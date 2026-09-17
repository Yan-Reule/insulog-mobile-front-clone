// Auditoria local: aplicativo, controllers, services e repositories reais;
// apenas o banco é substituído. Nenhuma conexão ao MySQL é permitida.
const path = require('node:path');
const fs = require('node:fs');
const assert = require('node:assert/strict');
const { once } = require('node:events');
const util = require('node:util');
const backend = path.resolve(process.env.AUDIT_BACKEND || path.join(__dirname, '../../../insulog-back-clone'));
const out = __dirname;
const logs = [];
const originalLog = console.log;
console.log = (...args) => logs.push(util.format(...args));
console.error = (...args) => logs.push(util.format(...args));
const { pool } = require(path.join(backend, 'src/config/database'));
const passwordService = require(path.join(backend, 'src/services/passwordService'));
const fakePassword = 'AUDIT_ONLY_fake_password_2026';
const row = {
  id_usuario: 19, nome: 'Paciente Fictício', email: 'audit@example.invalid',
  senha: passwordService.hashPassword(fakePassword), tipo_usuario: 'paciente', tipo_login: 'email',
  id_registro: 1004, nivel_glicose: 120, data_hora: '2026-08-15 12:00:00',
  id_periodo: 1, periodo: 'Teste', periodo_descricao: 'Teste', observacao: '<script>audit</script>',
  id_registro_insulina: 1, id_tipo_insulina: 1, unidade_insulina: 2,
  tipo_insulina: 'Teste', tipo_insulina_nome: 'Teste',
  id_alarme: 1, dias_semana: 'SEG', ativo: 1, tem_som: 1, tem_vibracao: 1,
  id_configuracao: 1, idioma: 'pt-BR', tema: 'claro', notificacoes: 1,
  id_exportacao: 1, descricao: 'Teste', data: '2026-08-15'
};
const sqlCalls = [];
async function execute(sql, params = []) {
  sqlCalls.push({ sql, params });
  if (/^\s*(INSERT|UPDATE|DELETE)/i.test(sql)) return [{ insertId: 99, affectedRows: 1 }];
  if (sql.includes('WHERE email = ?') && !sql.includes('OR nome')) return [[]];
  return [[{ ...row }]];
}
pool.execute = execute;
pool.getConnection = async () => ({execute, beginTransaction: async () => {}, commit: async () => {}, rollback: async () => {}, release() {}});
const app = require(path.join(backend, 'src/app'));
const mounts = {
  auth: '', user: '/usuarios', typeInsu: '/tipos-insulina', periodo: '/periodos',
  registroGlicose: '/registros-glicose', registroInsulina: '/registros-insulina',
  exportacao: '/exportacoes', configuracao: '/configuracoes', alarme: '/alarmes'
};
const body = { ...row, senha: fakePassword, username: row.email, password: fakePassword, crm: 'AUDIT',
  insulina: null, lembrete: null };
const results = [];
(async () => {
  const server = app.listen(0, '127.0.0.1');
  await once(server, 'listening');
  try {
    for (const [name, mount] of Object.entries(mounts)) {
      const file = `src/routes/${name}Routes.js`;
      const lines = fs.readFileSync(path.join(backend, file), 'utf8').split('\n');
      for (let i = 0; i < lines.length; i++) {
        const m = lines[i].match(/router\.(get|post|put|delete)\('([^']+)',\s*(\w+)\.(\w+)/);
        if (!m) continue;
        const [, method, route, controller, handler] = m;
        if (handler === 'showByType') {
          results.push({file, line:i+1, method:method.toUpperCase(), route:mount+route, handler,
            status:null, conclusion:'Inalcançável: GET /:id registrado antes de GET /:tipo_usuario.'});
          continue;
        }
        const endpoint = (mount + route).replace(/:id_usuario|:usuarioId/g, '19').replace(/:id\b/g, '1');
        const query = handler === 'getDashboard' || handler === 'getHistorico' || handler === 'gerarRelatorio'
          ? '?id_usuario=19&dataInicio=2026-08-01&dataFim=2026-08-31' : '';
        const before = sqlCalls.length;
        const response = await fetch(`http://127.0.0.1:${server.address().port}${endpoint}${query}`, {
          method:method.toUpperCase(), headers:{'Content-Type':'application/json'},
          ...(method==='post'||method==='put' ? {body:JSON.stringify(body)} : {})
        });
        const bytes = Buffer.from(await response.arrayBuffer());
        assert.ok(response.status >= 200 && response.status < 300, `${method} ${endpoint}: ${response.status} ${bytes}`);
        if (name === 'user' && handler === 'index') assert.ok(JSON.parse(bytes)[0].senha.startsWith('scrypt:'));
        if (name === 'user' && handler === 'update') {
          const update = sqlCalls.slice(before).find(x=>x.sql.startsWith('UPDATE usuario'));
          assert.ok(passwordService.verifyPassword(fakePassword, update.params[2]));
          assert.equal(update.params.at(-1), '1');
        }
        results.push({file, line:i+1, method:method.toUpperCase(), route:mount+route,
          handler:`${controller}.${handler}`, status:response.status, sqlCalls:sqlCalls.length-before,
          conclusion: name==='auth' ? 'Login válido, sem emissão de sessão/token.' : 'Aceita requisição sem cookie/token; banco simulado.'});
      }
    }
    assert.ok(logs.some(x=>x.includes(fakePassword)), 'Senha sintética deve aparecer nos logs vulneráveis');
    fs.writeFileSync(path.join(out,'verificacao-api.json'), JSON.stringify({
      mode:'App Express real; banco simulado; HTTP restrito a 127.0.0.1; não valida deploy ou constraints reais.',
      registeredRouterHandlers:results.length, exercised:results.filter(x=>x.status!==null).length,
      passwordLeakedToLogs:true, usersListExposesPasswordHash:true, anonymousPasswordUpdate:true,
      routes:results
    },null,2)+'\n');
    originalLog(JSON.stringify({registered:results.length,exercised:results.filter(x=>x.status!==null).length,
      failures:0, passwordLeakedToLogs:true, usersListExposesPasswordHash:true, anonymousPasswordUpdate:true}));
  } finally { await new Promise(resolve=>server.close(resolve)); await pool.end(); }
})().catch(error=>{originalLog(error);process.exitCode=1;});
