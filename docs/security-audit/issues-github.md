--- ISSUE 1 ---

# [Segurança] Leitura global de usuários, dados de saúde e relatórios sem identidade validada

Labels sugeridas: security, alta

Achado: F01

## Problema

O login apenas devolve os dados do usuário. Nenhum middleware estabelece identidade autenticada nas rotas. As listagens retornam todos os donos; GET /usuarios também devolve a coluna senha por SELECT *. Nas buscas por usuário, dashboard, histórico e exportação, o filtro id_usuario usa diretamente path/query do chamador. É possível consultar outro paciente, inclusive por nome/e-mail nas listagens de glicose/insulina. Não existe RLS ou middleware de tenant: há filtros manuais de dono, sem vínculo com autenticação.

## Condições de explorabilidade

Acesso de rede à API e dados existentes. Não exige login, flag ou configuração adicional no código. Não foi inspecionado um eventual gateway externo. Teste local confirmou resposta 200 e campo senha com hash; banco simulado.

## Evidência

backend/src/app.js:96–104

```

96: app.use('/', authRoutes)
97: app.use('/usuarios', userRoutes)
98: app.use('/tipos-insulina', typeInsuRoutes)
99: app.use('/periodos', periodoRoutes)
100: app.use('/registros-glicose', registroGlicoseRoutes)
101: app.use('/registros-insulina', registroInsulinaRoutes)
102: app.use('/exportacoes', exportacaoRoutes)
103: app.use('/configuracoes', configuracaoRoutes)
104: app.use('/alarmes', alarmeRoutes)

```

backend/src/repositories/userRepository.js:4–9

```

4: async function findAll() {
5:   const [rows] = await db.execute(
6:     'SELECT * FROM usuario ORDER BY id_usuario ASC'
7:   )
8: 
9:   return rows

```

backend/src/controllers/exportacaoController.js:54–60

```

54:     const { id_usuario, dataInicio, dataFim, formato } = req.query
55:     const arquivo = await exportacaoService.gerarRelatorio({
56:       idUsuario: id_usuario,
57:       dataInicio,
58:       dataFim,
59:       formato
60:     })

```

backend/src/repositories/exportacaoRepository.js:108–111

```

108:     WHERE rg.id_usuario = ? AND rg.data_hora >= ?
109:       AND rg.data_hora < DATE_ADD(?, INTERVAL 1 DAY)
110:     ORDER BY rg.data_hora ASC, ri.id_registro_insulina ASC`,
111:     [idUsuario, dataInicio, dataFim]

```

## Impacto

Exposição de nomes, e-mails, hashes de senha, medições, doses, alarmes, preferências e relatórios de outros pacientes. Se existirem senhas legadas em texto puro, também saem na listagem; a existência desses registros não foi comprovada.

## Sugestão de correção

Criar sessão/token validado no servidor e negar acesso por padrão. Derivar o dono da identidade e, para médicos, validar o vínculo autorizado com o paciente. Aplicar o mesmo escopo a listagens, dashboard, histórico e exportação. Substituir SELECT * por projeção sem senha. Remover listagens globais desnecessárias.

## Critérios de aceite

- [ ] Requisições anônimas às rotas privadas retornam 401.

- [ ] Paciente A não lê dados, agregados nem relatórios de B por ID, nome ou e-mail.

- [ ] Médico sem vínculo com B recebe 403/404; vínculo válido funciona.

- [ ] Nenhuma resposta pública inclui senha ou hash; teste cobre GET /usuarios.

--- FIM ISSUE 1 ---

--- ISSUE 2 ---

# [Segurança] Catálogos globais aceitam criação, edição e exclusão anônimas

Labels sugeridas: security, alta

Achado: F02

## Problema

POST, PUT e DELETE de /periodos e /tipos-insulina chamam diretamente os controllers. Os services verificam campos/existência, mas nenhum privilégio. As tabelas são catálogos compartilhados, sem coluna de dono. Não há isAdmin/canEdit/role nem UI de manutenção desses catálogos no Flutter; portanto não se afirma um gate de papel escondido no navegador. A falha verificada é a ausência de autorização no servidor para escrita global.

## Condições de explorabilidade

API alcançável. Edição exige ID existente e campo nome/descricao; exclusão pode ser impedida por foreign keys se o catálogo estiver em uso. A edição anônima foi exercitada com banco simulado.

## Evidência

backend/src/routes/periodoRoutes.js:8–10

```

8: router.post('/', periodoController.create)
9: router.put('/:id', periodoController.update)
10: router.delete('/:id', periodoController.deleteById)

```

backend/src/routes/typeInsuRoutes.js:8–10

```

8: router.post('/', typeInsuController.create)
9: router.put('/:id', typeInsuController.update)
10: router.delete('/:id', typeInsuController.deleteById)

```

backend/src/repositories/periodoRepository.js:55–56

```

55:       'UPDATE periodo SET descricao = ? WHERE id_periodo = ?',
56:       [descricao, id]

```

backend/src/repositories/typeInsuRepository.js:37–38

```

37:       'UPDATE tipoinsulina SET nome = ? WHERE id_tipo_insulina = ?',
38:       [nome, id]

```

## Impacto

Qualquer chamador altera nomes/tipos/períodos usados por todos os usuários, cria entradas arbitrárias e remove entradas não referenciadas.

## Sugestão de correção

Exigir identidade e permissão explícita de manutenção dos catálogos em todas as três operações. Se não houver função administrativa no produto, remover/desabilitar as rotas de escrita e manter carga controlada de catálogos.

## Critérios de aceite

- [ ] POST/PUT/DELETE dos dois catálogos rejeitam anônimos e usuários sem permissão.

- [ ] Usuário autorizado mantém o catálogo; leitura segue a política definida.

- [ ] Autorização ocorre antes da consulta/mutação no banco.

--- FIM ISSUE 2 ---

--- ISSUE 3 ---

# [Segurança] Atualização de conta por ID permite trocar a senha de outro usuário

Labels sugeridas: security, crítica

Achado: F03

## Problema

PUT /usuarios/:id aceita nome, email, senha, tipo_login e tipo_usuario do body, calcula o hash e executa UPDATE usuario WHERE id_usuario = ?. Não verifica sessão, posse, senha atual nem permissão sobre o papel. GET e DELETE da conta também usam somente o ID. Conhecendo um ID e os campos retornados pelas listagens, o chamador pode substituir a senha da vítima.

## Condições de explorabilidade

API alcançável, usuário existente e body com os campos obrigatórios. Restrições reais do banco podem impedir valores inválidos ou exclusão com referências. Teste com services/repository reais e banco simulado confirmou hash da nova senha e ID escolhido.

## Evidência

backend/src/routes/userRoutes.js:8–14

```

8: router.get('/', userController.index);
9: router.get('/:id', userController.show);
10: router.get('/:tipo_usuario', userController.showByType);
11: 
12: router.post('/', userController.create);
13: router.delete('/:id', userController.deleteById);
14: router.put('/:id', userController.update);

```

backend/src/services/userService.js:78–92

```

78: async function updateUser(id, data) {
79:   const { nome, email, senha, tipo_login, tipo_usuario, id_medico, crm } = data
80: 
81:   if (!nome || !email || !senha || !tipo_login || !tipo_usuario) {
82:     const error = new Error('Todos os campos sao obrigatorios')
83:     error.statusCode = 400
84:     throw error
85:   }
86: 
87:   const senhaCriptografada = passwordService.hashPassword(senha)
88: 
89:   return await userRepository.update(
90:     id,
91:     { nome, email, senha: senhaCriptografada, tipo_login, tipo_usuario, id_medico, crm }
92:   )

```

backend/src/repositories/userRepository.js:134–138

```

134:     await conn.execute(
135:       'UPDATE usuario SET nome = ?, email = ?, senha = ?, tipo_login = ?, tipo_usuario = ? WHERE id_usuario = ?',
136:       [nome, email, senha, tipo_login, tipo_usuario, id]
137:     )
138:     await conn.commit()

```

## Impacto

Tomada de conta, alteração de identidade/papel e exclusão de contas. A alteração de papel é persistida, mas não foi demonstrado um privilégio adicional de médico, pois o projeto não implementa esse controle.

## Sugestão de correção

Autorizar leitura/edição/exclusão pela identidade autenticada; criar fluxo específico de troca de senha com reautenticação ou recuperação verificada. Excluir tipo_usuario/tipo_login da edição comum. Aplicar política explícita para alteração administrativa.

## Critérios de aceite

- [ ] A não consegue ler/alterar/excluir B mudando :id.

- [ ] Anônimo recebe 401 antes de hash/UPDATE.

- [ ] Senha exige reautenticação/recuperação válida.

- [ ] Campos de papel não podem ser modificados pela atualização comum.

--- FIM ISSUE 3 ---

--- ISSUE 4 ---

# [Segurança] Registros, alarmes e preferências usam IDs e donos fornecidos pelo cliente

Labels sugeridas: security, alta

Achado: F04

## Problema

GET/PUT/DELETE por ID verificam apenas existência. POST/PUT aceitam id_usuario ou id_registro sem confirmar posse/vínculo. As queries de objeto filtram apenas a chave primária; update de glicose também altera insulina e alarmes associados. As configurações são por usuário (idioma/tema/notificacoes), não um painel administrativo.

## Condições de explorabilidade

API alcançável e IDs válidos; escrita exige os campos de cada service e relações aceitas pelo banco. Não exige login. Todos os handlers alcançáveis dessas famílias foram exercitados com banco simulado.

## Evidência

backend/src/services/registroGlicoseService.js:125–130

```

125: function montarRegistroCompleto(data, registroAtual = {}) {
126:   const id_usuario = data.id_usuario ?? registroAtual.id_usuario
127:   const nivel_glicose = data.nivel_glicose ?? registroAtual.nivel_glicose
128:   const id_periodo = data.id_periodo ?? registroAtual.id_periodo
129:   const data_hora = data.data_hora ?? registroAtual.data_hora ?? formatarDataHoraAtual()
130:   const observacao = data.observacao ?? registroAtual.observacao ?? null

```

backend/src/repositories/registroGlicoseRepository.js:198–205

```

198:       'UPDATE registroglicose SET id_usuario = ?, nivel_glicose = ?, data_hora = ?, id_periodo = ?, observacao = ? WHERE id_registro = ?',
199:       [
200:         glicose.id_usuario,
201:         glicose.nivel_glicose,
202:         glicose.data_hora,
203:         glicose.id_periodo,
204:         glicose.observacao ?? null,
205:         id

```

backend/src/repositories/registroInsulinaRepository.js:80–81

```

80:       'UPDATE registroinsulina SET id_registro = ?, id_tipo_insulina = ?, unidade_insulina = ? WHERE id_registro_insulina = ?',
81:       [id_registro, id_tipo_insulina, unidade_insulina, id]

```

backend/src/repositories/alarmeRepository.js:80–81

```

80:       'UPDATE alarme SET id_usuario = ?, data_hora = ?, id_periodo = ?, id_registro = ?, dias_semana = ?, ativo = ?, tem_som = ?, tem_vibracao = ? WHERE id_alarme = ?',
81:       [id_usuario, data_hora, id_periodo || null, id_registro || null, dias_semana.join(','), ativo, tem_som, tem_vibracao, id]

```

backend/src/repositories/configuracaoRepository.js:58–59

```

58:       'UPDATE configuracao SET id_usuario = ?, idioma = ?, tema = ?, notificacoes = ? WHERE id_configuracao = ?',
59:       [id_usuario, idioma, tema, notificacoes, id]

```

backend/src/repositories/exportacaoRepository.js:57–58

```

57:       'UPDATE exportacao SET id_usuario = ?, data = ?, descricao = ? WHERE id_exportacao = ?',
58:       [id_usuario, data, descricao, id]

```

## Impacto

Leitura, criação em nome de terceiros, alteração, transferência e exclusão de registros de saúde, lembretes, preferências e metadados de exportação. Pode adulterar histórico e desativar lembretes de outro usuário.

## Sugestão de correção

Passar identidade autenticada aos services/repositories. Combinar ID do objeto e dono em SELECT/UPDATE/DELETE. Em insulina, validar o dono via registroglicose; validar também id_registro dos alarmes. Derivar id_usuario no POST e impedir transferência pelo body. Validar relação médico-paciente quando aplicável, dentro da mesma transação.

## Critérios de aceite

- [ ] A não acessa nem altera objetos de B por path/body/query.

- [ ] POST com id_usuario/id_registro de B é rejeitado ou substituído por dono autenticado conforme contrato.

- [ ] UPDATE não transfere dono nem associa registro de outro paciente.

- [ ] Exclusão/edição completa de glicose protege também alarmes e insulina.

--- FIM ISSUE 4 ---

--- ISSUE 5 ---

# [Segurança] Senha do MySQL permanece recuperável no histórico Git

Labels sugeridas: security, média

Achado: F05

## Problema

Duas versões do .env no histórico contêm DB_PASSWORD não vazio e DB_USER=root. O arquivo foi removido depois, mas os blobs continuam alcançáveis. O código carrega esse .env para configurar a conexão. O valor foi inspecionado localmente e mascarado em todos os artefatos da auditoria.

## Condições de explorabilidade

Acesso ao histórico basta para extrair o segredo. Exploração do banco exige credencial ainda válida/reutilizada e acesso ao host. O .env histórico aponta localhost; não foi feita tentativa de autenticação. Severidade média pela exposição confirmada, sem pressupor compromisso atual.

## Evidência

backend/.env @ 147015e e 9ec3cab:3–4

```

3: DB_USER=root
4: DB_PASSWORD=[VALOR REAL MASCARADO]

```

backend/src/config/database.js:4–13

```

4: require('dotenv').config({
5:   path: path.resolve(__dirname, '../../.env')
6: })
7: 
8: const pool = mysql.createPool({
9:   host: process.env.DB_HOST,
10:   port: Number(process.env.DB_PORT),
11:   user: process.env.DB_USER,
12:   password: process.env.DB_PASSWORD,
13:   database: process.env.DB_NAME,

```

## Impacto

Quem obtém o histórico consegue recuperar a senha antiga. Se ainda for válida ou reutilizada, permite acesso ao banco alcançável com os privilégios dessa credencial. Não há evidência de validade atual, de reutilização ou de exposição pública do repositório.

## Sugestão de correção

Rotacionar a credencial e qualquer reutilização confirmada; usar usuário de banco com privilégios mínimos. Coordenar remoção dos blobs do histórico e clones, preservando evidências restritas. Manter apenas .env.example sem segredos e validar configuração de startup; usar scanner de segredos no CI.

## Critérios de aceite

- [ ] Credencial antiga revogada ou sua revogação comprovada sem registrar o valor na issue.

- [ ] Segredo não está em referências distribuídas após limpeza coordenada.

- [ ] CI rejeita commit de .env/segredo real.

- [ ] Aplicação recebe credenciais externamente e rejeita configuração inválida.

--- FIM ISSUE 5 ---

--- ISSUE 6 ---

# [Segurança] Logs da API registram senhas e respostas sensíveis sem mascaramento

Labels sugeridas: security, alta

Achado: F06

## Problema

O middleware registra req.body de toda chamada JSON, incluindo password no login e senha no cadastro/edição. Cadastro repete os dados no controller e no service antes do hash. Outro middleware registra corpos de resposta, incluindo dados de saúde e hashes da listagem. Não há condição de ambiente que desative esses logs.

## Condições de explorabilidade

Requer uma chamada com credenciais e acesso aos logs da aplicação/plataforma. Confirmado com senha fictícia; não foram acessados logs reais.

## Evidência

backend/src/app.js:78–85

```

78: app.use((req, res, next) => {
79:   if (Object.keys(req.query).length > 0) {
80:     console.log('Query:', req.query)
81:   }
82: 
83:   if (req.body && Object.keys(req.body).length > 0) {
84:     console.log('Body:', req.body)
85:   }

```

backend/src/controllers/userController.js:43–47

```

43: async function create(req, res, next) {
44:   try {
45:     console.log('Request body:', req.body)
46:     const user = await userService.createUser(req.body)
47:     return res.status(201).json(user)

```

backend/src/services/userService.js:37–40

```

37: async function createUser(data) {
38:   const { nome, email, senha, tipo_login, tipo_usuario, id_medico, crm } = data
39: 
40:   console.log('createUser:', data)

```

## Impacto

Leitores/coletadores de stdout obtêm credenciais em texto puro e dados pessoais/de saúde. Mesmo após corrigir a autenticação, o vazamento por logs permanece.

## Sugestão de correção

Remover logs integrais de body/resposta e duplicados de cadastro. Registrar somente metadados permitidos, status e identificador de correlação. Mascarar recursivamente campos sensíveis antes de qualquer logging e revisar retenção/acesso aos logs já existentes.

## Critérios de aceite

- [ ] Login, cadastro e edição não registram senha/password/hash/token em sucesso ou erro.

- [ ] Dados de saúde e corpos completos não são logados.

- [ ] Teste captura console/logger e verifica ausência de credenciais sintéticas.

--- FIM ISSUE 6 ---

--- ISSUE 7 ---

# [Segurança] App persiste a senha reutilizável em SharedPreferences

Labels sugeridas: security, média

Achado: F07

## Problema

Após login, a senha original é gravada automaticamente em saved_password com prefs.setString e lida para login automático. Não há criptografia na camada do aplicativo nem armazenamento de sessão revogável nesse fluxo.

## Condições de explorabilidade

Requer acesso às preferências/perfil ou extração de dados do app; não se assume que outro app sem privilégios possa ler o sandbox Android. O fluxo ocorre após login bem-sucedido.

## Evidência

frontend/lib/states/login_form_state.dart:54–59

```

54:       final loginData = await AuthService().login(username, password);
55:       await _savedLoginService.saveCredentials(
56:         userId: loginData.userId,
57:         username: username,
58:         password: password,
59:       );

```

frontend/lib/services/local/saved_login_service.dart:25–28

```

25:     final prefs = await SharedPreferences.getInstance();
26:     await prefs.setInt(_userIdKey, userId);
27:     await prefs.setString(_usernameKey, username);
28:     await prefs.setString(_passwordKey, password);

```

frontend/lib/services/local/saved_login_service.dart:31–35

```

31:   Future<SavedLoginData?> getCredentials() async {
32:     final prefs = await SharedPreferences.getInstance();
33:     final userId = prefs.getInt(_userIdKey);
34:     final username = prefs.getString(_usernameKey);
35:     final password = prefs.getString(_passwordKey);

```

## Impacto

Leitura das preferências do aplicativo/perfil permite recuperar a senha original e reutilizá-la. Não é chave hardcoded nem XSS; é um achado adicional de armazenamento de credenciais.

## Sugestão de correção

Eliminar persistência de senha e apagar saved_password em migração. Após implementar sessão no servidor, usar credencial revogável protegida pelo mecanismo seguro da plataforma; no web, projetar sessão apropriada sem senha no armazenamento do navegador.

## Critérios de aceite

- [ ] Senha não é gravada nas preferências após login nem auto-login.

- [ ] Migração remove saved_password de instalações existentes.

- [ ] Logout revoga/limpa sessão; auto-login usa sessão válida, não senha persistida.

--- FIM ISSUE 7 ---

--- ISSUE 8 ---

# [Segurança] Login e dados de saúde trafegam em HTTP sem TLS

Labels sugeridas: security, alta

Achado: F08

## Problema

ApiIpService monta sempre http://<ip>:3000. ApiService envia as credenciais no corpo JSON a essa URL; exportação usa a mesma base. O manifesto Android permite cleartext no aplicativo principal, sem limitar ao debug. O servidor inicia HTTP em 0.0.0.0.

## Condições de explorabilidade

Cliente Android/ambiente que permita HTTP, conexão direta conforme configuração e atacante capaz de observar/interferir no caminho. Plataformas que bloqueiem cleartext podem falhar em conectar. Proteções externas como VPN/gateway não foram inspecionadas.

## Evidência

frontend/lib/services/local/api_ip_service.dart:18–26

```

18:   Future<String> getBaseUrl() async {
19:     final savedIp = await getApiIpDigits();
20:     final ip =
21:         (isValidIp(savedIp) ? savedIp : null) ??
22:         formatDigitsAsIp(savedIp) ??
23:         formatDigitsAsIp(_defaultApiIpDigits) ??
24:         '10.173.57.47';
25: 
26:     return 'http://$ip:$_apiPort';

```

frontend/lib/services/api/api_service.dart:30–32

```

30:       final response = await http
31:           .post(uri, headers: headers, body: jsonEncode(body))
32:           .timeout(const Duration(seconds: 10));

```

frontend/android/app/src/main/AndroidManifest.xml:13–15

```

13:         android:icon="@mipmap/ic_launcher"
14:         android:enableOnBackInvokedCallback="true"
15:         android:usesCleartextTraffic="true">

```

## Impacto

Um observador no caminho de rede lê senhas e dados de saúde; um intermediário ativo pode adulterar respostas e capturar credenciais. Não foi executada interceptação de tráfego.

## Sugestão de correção

Configurar endpoint HTTPS validado e rejeitar esquema HTTP em release. Desabilitar usesCleartextTraffic na configuração de produção; eventual exceção local deve existir somente em debug. Manter validação normal de certificado e configurar TLS na terminação publicada.

## Critérios de aceite

- [ ] Release rejeita base HTTP e usa HTTPS para login, CRUD e exportação.

- [ ] Manifesto release desabilita cleartext; exceção debug não vaza para release.

- [ ] Certificado inválido é rejeitado; teste confirma ausência de bypass.

--- FIM ISSUE 8 ---
