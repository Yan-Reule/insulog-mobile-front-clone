#!/usr/bin/env python3
"""Produz dados e Markdown da auditoria a partir das evidências locais."""
import json,pathlib,subprocess,collections
OUT=pathlib.Path(__file__).resolve().parent; FRONT=OUT.parent.parent; BACK=FRONT.parent/'insulog-back-clone'
findings=[]
def ev(repo,file,start,end=None,note=''):
 end=end or start
 lines=((BACK if repo=='backend' else FRONT)/file).read_text().splitlines()
 return {'repo':repo,'file':file,'start':start,'end':end,'code':'\n'.join(f'{i}: {lines[i-1]}' for i in range(start,end+1)),'note':note}
def b(f,s,e=None,note=''):return ev('backend',f,s,e,note)
def f(f,s,e=None,note=''):return ev('frontend',f,s,e,note)
def add(id,category,severity,title,problem,impact,condition,fix,accept,evidence,issue_evidence=None):
 findings.append(dict(id=id,category=category,severity=severity,title=title,problem=problem,impact=impact,condition=condition,fix=fix,accept=accept,evidence=evidence,issue_evidence=issue_evidence or [0]))
add('F01','1. Isolamento','alta','Leitura global de usuários, dados de saúde e relatórios sem identidade validada',
'O login apenas devolve os dados do usuário. Nenhum middleware estabelece identidade autenticada nas rotas. As listagens retornam todos os donos; GET /usuarios também devolve a coluna senha por SELECT *. Nas buscas por usuário, dashboard, histórico e exportação, o filtro id_usuario usa diretamente path/query do chamador. É possível consultar outro paciente, inclusive por nome/e-mail nas listagens de glicose/insulina. Não existe RLS ou middleware de tenant: há filtros manuais de dono, sem vínculo com autenticação.',
'Exposição de nomes, e-mails, hashes de senha, medições, doses, alarmes, preferências e relatórios de outros pacientes. Se existirem senhas legadas em texto puro, também saem na listagem; a existência desses registros não foi comprovada.',
'Acesso de rede à API e dados existentes. Não exige login, flag ou configuração adicional no código. Não foi inspecionado um eventual gateway externo. Teste local confirmou resposta 200 e campo senha com hash; banco simulado.',
'Criar sessão/token validado no servidor e negar acesso por padrão. Derivar o dono da identidade e, para médicos, validar o vínculo autorizado com o paciente. Aplicar o mesmo escopo a listagens, dashboard, histórico e exportação. Substituir SELECT * por projeção sem senha. Remover listagens globais desnecessárias.',
['Requisições anônimas às rotas privadas retornam 401.','Paciente A não lê dados, agregados nem relatórios de B por ID, nome ou e-mail.','Médico sem vínculo com B recebe 403/404; vínculo válido funciona.','Nenhuma resposta pública inclui senha ou hash; teste cobre GET /usuarios.'],
[b('src/app.js',96,104),b('src/services/authService.js',21,28),b('src/repositories/userRepository.js',4,9),b('src/controllers/userController.js',3,6),b('src/repositories/registroGlicoseRepository.js',6,9),b('src/repositories/registroInsulinaRepository.js',4,9),b('src/repositories/alarmeRepository.js',14,19),b('src/repositories/configuracaoRepository.js',4,9),b('src/repositories/exportacaoRepository.js',4,9),b('src/controllers/registroGlicoseController.js',14,27),b('src/controllers/registroGlicoseController.js',44,61),b('src/services/registroGlicoseService.js',38,51),b('src/services/registroInsulinaService.js',36,49),b('src/controllers/alarmeController.js',12,16),b('src/controllers/exportacaoController.js',54,60),b('src/repositories/exportacaoRepository.js',108,111),f('lib/services/api/api_service.dart',18,21),f('lib/services/api/report_export_service.dart',58,70)], [0,2,14,15])
add('F02','2. Permissões','alta','Catálogos globais aceitam criação, edição e exclusão anônimas',
'POST, PUT e DELETE de /periodos e /tipos-insulina chamam diretamente os controllers. Os services verificam campos/existência, mas nenhum privilégio. As tabelas são catálogos compartilhados, sem coluna de dono. Não há isAdmin/canEdit/role nem UI de manutenção desses catálogos no Flutter; portanto não se afirma um gate de papel escondido no navegador. A falha verificada é a ausência de autorização no servidor para escrita global.',
'Qualquer chamador altera nomes/tipos/períodos usados por todos os usuários, cria entradas arbitrárias e remove entradas não referenciadas.',
'API alcançável. Edição exige ID existente e campo nome/descricao; exclusão pode ser impedida por foreign keys se o catálogo estiver em uso. A edição anônima foi exercitada com banco simulado.',
'Exigir identidade e permissão explícita de manutenção dos catálogos em todas as três operações. Se não houver função administrativa no produto, remover/desabilitar as rotas de escrita e manter carga controlada de catálogos.',
['POST/PUT/DELETE dos dois catálogos rejeitam anônimos e usuários sem permissão.','Usuário autorizado mantém o catálogo; leitura segue a política definida.','Autorização ocorre antes da consulta/mutação no banco.'],
[b('src/routes/periodoRoutes.js',8,10),b('src/routes/typeInsuRoutes.js',8,10),b('src/services/periodoService.js',40,46),b('src/services/typeInsuService.js',40,46),b('src/repositories/periodoRepository.js',55,56),b('src/repositories/typeInsuRepository.js',37,38)], [0,1,4,5])
add('F03','3. IDOR','crítica','Atualização de conta por ID permite trocar a senha de outro usuário',
'PUT /usuarios/:id aceita nome, email, senha, tipo_login e tipo_usuario do body, calcula o hash e executa UPDATE usuario WHERE id_usuario = ?. Não verifica sessão, posse, senha atual nem permissão sobre o papel. GET e DELETE da conta também usam somente o ID. Conhecendo um ID e os campos retornados pelas listagens, o chamador pode substituir a senha da vítima.',
'Tomada de conta, alteração de identidade/papel e exclusão de contas. A alteração de papel é persistida, mas não foi demonstrado um privilégio adicional de médico, pois o projeto não implementa esse controle.',
'API alcançável, usuário existente e body com os campos obrigatórios. Restrições reais do banco podem impedir valores inválidos ou exclusão com referências. Teste com services/repository reais e banco simulado confirmou hash da nova senha e ID escolhido.',
'Autorizar leitura/edição/exclusão pela identidade autenticada; criar fluxo específico de troca de senha com reautenticação ou recuperação verificada. Excluir tipo_usuario/tipo_login da edição comum. Aplicar política explícita para alteração administrativa.',
['A não consegue ler/alterar/excluir B mudando :id.','Anônimo recebe 401 antes de hash/UPDATE.','Senha exige reautenticação/recuperação válida.','Campos de papel não podem ser modificados pela atualização comum.'],
[b('src/routes/userRoutes.js',8,14),b('src/controllers/userController.js',24,27),b('src/controllers/userController.js',35,37),b('src/controllers/userController.js',55,57),b('src/services/userService.js',78,92),b('src/repositories/userRepository.js',134,138),b('src/repositories/userRepository.js',18,30)], [0,4,5])
add('F04','3. IDOR','alta','Registros, alarmes e preferências usam IDs e donos fornecidos pelo cliente',
'GET/PUT/DELETE por ID verificam apenas existência. POST/PUT aceitam id_usuario ou id_registro sem confirmar posse/vínculo. As queries de objeto filtram apenas a chave primária; update de glicose também altera insulina e alarmes associados. As configurações são por usuário (idioma/tema/notificacoes), não um painel administrativo.',
'Leitura, criação em nome de terceiros, alteração, transferência e exclusão de registros de saúde, lembretes, preferências e metadados de exportação. Pode adulterar histórico e desativar lembretes de outro usuário.',
'API alcançável e IDs válidos; escrita exige os campos de cada service e relações aceitas pelo banco. Não exige login. Todos os handlers alcançáveis dessas famílias foram exercitados com banco simulado.',
'Passar identidade autenticada aos services/repositories. Combinar ID do objeto e dono em SELECT/UPDATE/DELETE. Em insulina, validar o dono via registroglicose; validar também id_registro dos alarmes. Derivar id_usuario no POST e impedir transferência pelo body. Validar relação médico-paciente quando aplicável, dentro da mesma transação.',
['A não acessa nem altera objetos de B por path/body/query.','POST com id_usuario/id_registro de B é rejeitado ou substituído por dono autenticado conforme contrato.','UPDATE não transfere dono nem associa registro de outro paciente.','Exclusão/edição completa de glicose protege também alarmes e insulina.'],
[b('src/repositories/registroGlicoseRepository.js',53,54),b('src/services/registroGlicoseService.js',125,130),b('src/repositories/registroGlicoseRepository.js',198,205),b('src/repositories/registroGlicoseRepository.js',278,289),b('src/repositories/registroInsulinaRepository.js',14,15),b('src/repositories/registroInsulinaRepository.js',52,53),b('src/repositories/registroInsulinaRepository.js',80,81),b('src/repositories/registroInsulinaRepository.js',102,103),b('src/repositories/alarmeRepository.js',32,33),b('src/repositories/alarmeRepository.js',47,48),b('src/repositories/alarmeRepository.js',80,81),b('src/repositories/alarmeRepository.js',107,108),b('src/repositories/configuracaoRepository.js',14,15),b('src/repositories/configuracaoRepository.js',29,30),b('src/repositories/configuracaoRepository.js',58,59),b('src/repositories/configuracaoRepository.js',81,82),b('src/repositories/exportacaoRepository.js',14,15),b('src/repositories/exportacaoRepository.js',29,30),b('src/repositories/exportacaoRepository.js',57,58),b('src/repositories/exportacaoRepository.js',79,80)], [1,2,6,10,14,18])
add('F05','4. Segredos em código','média','Senha do MySQL permanece recuperável no histórico Git',
'Duas versões do .env no histórico contêm DB_PASSWORD não vazio e DB_USER=root. O arquivo foi removido depois, mas os blobs continuam alcançáveis. O código carrega esse .env para configurar a conexão. O valor foi inspecionado localmente e mascarado em todos os artefatos da auditoria.',
'Quem obtém o histórico consegue recuperar a senha antiga. Se ainda for válida ou reutilizada, permite acesso ao banco alcançável com os privilégios dessa credencial. Não há evidência de validade atual, de reutilização ou de exposição pública do repositório.',
'Acesso ao histórico basta para extrair o segredo. Exploração do banco exige credencial ainda válida/reutilizada e acesso ao host. O .env histórico aponta localhost; não foi feita tentativa de autenticação. Severidade média pela exposição confirmada, sem pressupor compromisso atual.',
'Rotacionar a credencial e qualquer reutilização confirmada; usar usuário de banco com privilégios mínimos. Coordenar remoção dos blobs do histórico e clones, preservando evidências restritas. Manter apenas .env.example sem segredos e validar configuração de startup; usar scanner de segredos no CI.',
['Credencial antiga revogada ou sua revogação comprovada sem registrar o valor na issue.','Segredo não está em referências distribuídas após limpeza coordenada.','CI rejeita commit de .env/segredo real.','Aplicação recebe credenciais externamente e rejeita configuração inválida.'],
[{'repo':'backend','file':'.env @ 147015e e 9ec3cab','start':3,'end':4,'code':'3: DB_USER=root\n4: DB_PASSWORD=[VALOR REAL MASCARADO]','note':'Blobs d69f680ba9f1 e af0ed38a60e2; removido em fd64e41. Mesma família de exposição, uma issue.'},b('src/config/database.js',4,13)], [0,1])
add('F06','Extra: logs','alta','Logs da API registram senhas e respostas sensíveis sem mascaramento',
'O middleware registra req.body de toda chamada JSON, incluindo password no login e senha no cadastro/edição. Cadastro repete os dados no controller e no service antes do hash. Outro middleware registra corpos de resposta, incluindo dados de saúde e hashes da listagem. Não há condição de ambiente que desative esses logs.',
'Leitores/coletadores de stdout obtêm credenciais em texto puro e dados pessoais/de saúde. Mesmo após corrigir a autenticação, o vazamento por logs permanece.',
'Requer uma chamada com credenciais e acesso aos logs da aplicação/plataforma. Confirmado com senha fictícia; não foram acessados logs reais.',
'Remover logs integrais de body/resposta e duplicados de cadastro. Registrar somente metadados permitidos, status e identificador de correlação. Mascarar recursivamente campos sensíveis antes de qualquer logging e revisar retenção/acesso aos logs já existentes.',
['Login, cadastro e edição não registram senha/password/hash/token em sucesso ou erro.','Dados de saúde e corpos completos não são logados.','Teste captura console/logger e verifica ausência de credenciais sintéticas.'],
[b('src/app.js',39,48),b('src/app.js',78,85),b('src/controllers/userController.js',43,47),b('src/services/userService.js',37,40)], [1,2,3])
add('F07','Extra: armazenamento','média','App persiste a senha reutilizável em SharedPreferences',
'Após login, a senha original é gravada automaticamente em saved_password com prefs.setString e lida para login automático. Não há criptografia na camada do aplicativo nem armazenamento de sessão revogável nesse fluxo.',
'Leitura das preferências do aplicativo/perfil permite recuperar a senha original e reutilizá-la. Não é chave hardcoded nem XSS; é um achado adicional de armazenamento de credenciais.',
'Requer acesso às preferências/perfil ou extração de dados do app; não se assume que outro app sem privilégios possa ler o sandbox Android. O fluxo ocorre após login bem-sucedido.',
'Eliminar persistência de senha e apagar saved_password em migração. Após implementar sessão no servidor, usar credencial revogável protegida pelo mecanismo seguro da plataforma; no web, projetar sessão apropriada sem senha no armazenamento do navegador.',
['Senha não é gravada nas preferências após login nem auto-login.','Migração remove saved_password de instalações existentes.','Logout revoga/limpa sessão; auto-login usa sessão válida, não senha persistida.'],
[f('lib/states/login_form_state.dart',54,59),f('lib/services/local/saved_login_service.dart',25,28),f('lib/services/local/saved_login_service.dart',31,35),f('lib/states/login_form_state.dart',111,115)], [0,1,2])
add('F08','Extra: transporte','alta','Login e dados de saúde trafegam em HTTP sem TLS',
'ApiIpService monta sempre http://<ip>:3000. ApiService envia as credenciais no corpo JSON a essa URL; exportação usa a mesma base. O manifesto Android permite cleartext no aplicativo principal, sem limitar ao debug. O servidor inicia HTTP em 0.0.0.0.',
'Um observador no caminho de rede lê senhas e dados de saúde; um intermediário ativo pode adulterar respostas e capturar credenciais. Não foi executada interceptação de tráfego.',
'Cliente Android/ambiente que permita HTTP, conexão direta conforme configuração e atacante capaz de observar/interferir no caminho. Plataformas que bloqueiem cleartext podem falhar em conectar. Proteções externas como VPN/gateway não foram inspecionadas.',
'Configurar endpoint HTTPS validado e rejeitar esquema HTTP em release. Desabilitar usesCleartextTraffic na configuração de produção; eventual exceção local deve existir somente em debug. Manter validação normal de certificado e configurar TLS na terminação publicada.',
['Release rejeita base HTTP e usa HTTPS para login, CRUD e exportação.','Manifesto release desabilita cleartext; exceção debug não vaza para release.','Certificado inválido é rejeitado; teste confirma ausência de bypass.'],
[f('lib/services/local/api_ip_service.dart',18,26),f('lib/services/api/auth_service.dart',14,17),f('lib/services/api/api_service.dart',30,32),f('android/app/src/main/AndroidManifest.xml',13,15),b('src/server.js',13,16)], [0,2,3])
strengths=[
('Senhas novas recebem hash com salt aleatório e comparação resistente a timing.', [b('src/services/passwordService.js',6,9),b('src/services/passwordService.js',27,34),b('src/services/userService.js',70,74)], 'O fallback legado de comparação de texto puro em passwordService.js:46–47 existe; a migração de registros antigos não foi demonstrada. Isso não protege a listagem F01 nem o log anterior ao hash F06.'),
('Consultas usam parâmetros; trechos dinâmicos de LIMIT/ordenação são normalizados.', [b('src/repositories/userRepository.js',62,66),b('src/services/registroGlicoseService.js',27,35),b('src/services/registroInsulinaService.js',25,33),b('src/repositories/registroGlicoseRepository.js',301,310)], 'Verificados os oito repositories e seus services. Nenhuma SQL injection confirmada nos caminhos revisados. Parâmetros evitam injeção, mas não garantem posse.'),
('Exportação valida ID, datas e formato, com headers e conferência do arquivo no app.', [b('src/services/exportacaoService.js',92,99),b('src/services/exportacaoService.js',107,111),b('src/controllers/exportacaoController.js',51,52),b('src/controllers/exportacaoController.js',63,67),f('lib/services/api/report_export_service.dart',96,110)], 'O filtro de dono ainda depende do ID controlável pelo cliente (F01).'),
('Fluxos de texto revisados não interpretam HTML controlado pelo usuário.', [f('lib/widgets/home/home_header_widget.dart',24,26),b('src/reports/pdfReport.js',316,318),b('src/controllers/authController.js',5,6)], 'Flutter usa Text/TextField; API usa JSON e exporta PDF/XLSX. Não há templates HTML/e-mail, markdown, WebView ou sinks de HTML/JavaScript controlados pelo usuário. escape-html é transitivo do Express; _sanitizePayload mascara logs e não é sanitizador HTML.'),
('Logs do cliente mascaram campos senha/password/token recursivamente.', [f('lib/services/api/api_service.dart',274,288)], 'Proteção restrita ao cliente e a esses campos; não cobre os logs integrais do servidor.'),
('Segredos atuais do banco são recebidos do ambiente e CI backend usa leitura mínima.', [b('src/config/database.js',8,13),b('.github/workflows/api-tests.yml',11,12)], 'Não há fallback literal de senha no HEAD. Startup não valida/rejeita credenciais fracas: usa env e apenas registra falha de conexão em database.js:20–27. Não foi confirmado default secreto ativo.')]
category_status=[
['1. Banco sem tranca','Aplicável: MySQL/mysql2, isolamento manual por id_usuario. F01. Sem identidade autenticada, os filtros não constituem autorização.'],
['2. Permissão no navegador','Não há gates de papel no Flutter. Mapeamento para escrita privilegiada na API: F02. Atualização de conta/papel é F03. O cadastro fixa paciente no app, mas backend aceita medico com CRM não vazio; sem regra de negócio de aprovação ou privilégio implementado, isso não é contado como escalada verificada.'],
['3. IDOR','Todos os 48 handlers dos routers revisados estaticamente, mais GET / e middleware OPTIONS. 47 handlers exercitados; um sombreado. F03/F04 tratam objetos; consultas coletivas por ID de usuário estão agrupadas em F01 para evitar dupla contagem.'],
['4. Chaves expostas','F05: .env no histórico. Sem chave hardcoded ativa confirmada no HEAD, CI, scripts, documentação ou bundle web compilado. IP privado e ID de médico não são segredos. Logs, armazenamento e HTTP são extras, não hardcode.'],
['5. XSS','Aplicável ao alvo web e saídas; nenhum achado confirmado. Não foram encontrados sinks de HTML/JS alimentados por usuário. Templates HTML/e-mail não existem neste backend. PDFKit/ExcelJS não renderizam HTML como página web.']]
coverage=json.loads((OUT/'verificacao-api.json').read_text())
inv=json.loads((OUT/'inventario-evidencias.json').read_text())
# Controller/service/repository por rota: os arquivos foram lidos integralmente.
for route in coverage['routes']:
 stem=pathlib.Path(route['file']).stem.removesuffix('Routes')
 route['chain']=[f'src/controllers/{stem}Controller.js',f'src/services/{stem}Service.js']
 if stem!='auth':route['chain'].append(f'src/repositories/{stem}Repository.js')
 else:route['chain']+=['src/services/passwordService.js','src/repositories/userRepository.js']
 h=route['handler'].split('.')[-1]
 route['finding']='F01' if h in ['index','showByUserId','showByUsuarioId','getDashboard','getHistorico','gerarRelatorio'] else 'F03' if stem=='user' else 'F02' if stem in ['periodo','typeInsu'] else 'F04'
 if stem=='auth':route['finding']='Público: autentica senha; sem sessão'
 if stem in ['periodo','typeInsu'] and h in ['index','show']:route['finding']='Leitura de catálogo; não se presume privada'
 if h=='showByType':route['finding']='Sombreado; service não valida permissão'
# Each frontend call, including UI guard relation.
frontend_cross=[
['Login/cadastro','lib/services/api/auth_service.dart:14–17,89–96','POST /login; POST /usuarios','Sem gate de papel; paciente é valor fixo. Senha conferida no login, cadastro público. F06/F08; não prova escalada de papel.'],
['Histórico e resumo','lib/services/api/data_service.dart:26–31,58–66,170–173','GET /registros-glicose/usuario/:id; /historico; GET /registros-insulina/usuario/:id','ID do estado local; servidor não confirma identidade/posse. F01.'],
['Alarmes','lib/services/api/data_service.dart:87,107,120–123,147,157','GET /alarmes/usuario/:id; POST /alarmes; PUT/DELETE /alarmes/:id','Sem gate de papel; servidor confere campos/existência. F01/F04.'],
['Glicose','lib/services/api/data_service.dart:196,212,223,242','POST /registros-glicose; GET/PUT/DELETE /registros-glicose/:id','Sem gate de papel; objeto selecionado na UI não autentica o dono. F04.'],
['Exportação','lib/services/api/report_export_service.dart:51–70','GET /exportacoes/relatorio','Valida ID/período no cliente e servidor; nenhuma autorização. F01.'],
['Demais rotas','src/routes/{user,periodo,typeInsu,configuracao,exportacao}Routes.js','Gestão de usuários, catálogos, preferências e metadados','Sem UI correspondente de gestão de papel; todas as rotas foram revisadas mesmo sem chamada do app. F01–F04.']]
issues=[]
for idx,x in enumerate(findings,1):
 parts=[f'--- ISSUE {idx} ---',f'# [Segurança] {x["title"]}',f'Labels sugeridas: security, {x["severity"]}',f'Achado: {x["id"]}', '## Problema',x['problem'],'## Condições de explorabilidade',x['condition'],'## Evidência']
 for i in x['issue_evidence']:
  e=x['evidence'][i];parts += [f'{e["repo"]}/{e["file"]}:{e["start"]}–{e["end"]}', '```',e['code'],'```']
 parts+=['## Impacto',x['impact'],'## Sugestão de correção',x['fix'],'## Critérios de aceite',*[f'- [ ] {a}' for a in x['accept']],f'--- FIM ISSUE {idx} ---']
 issues.append('\n\n'.join(parts))
(OUT/'issues-github.md').write_text('\n\n'.join(issues)+'\n')
data={'title':'Relatório de Auditoria de Segurança — Insulog','date':'17/09/2026','findings':findings,'strengths':strengths,'category_status':category_status,'coverage':coverage,'frontend_cross':frontend_cross,'inventory':inv,'issues':issues,
'references':[['OWASP Authorization Cheat Sheet','https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Cheat_Sheet.html'],['OWASP Secrets Management Cheat Sheet','https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html']]}
(OUT/'dados-relatorio.json').write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n')
md=[f'# {data["title"]}',data['date'],'Escopo: frontend insulog-mobile-front-clone e backend ../insulog-back-clone. Revisão de código e reprodução local com banco simulado; não é pentest do ambiente publicado.', '## Resumo',str(dict(collections.Counter(x['severity'] for x in findings))),'## Categorias']
for title,text in category_status:md += [f'### {title}',text]
for x in findings:
 md += [f'## {x["id"]} — {x["title"]}',f'Severidade: **{x["severity"]}** | Categoria: {x["category"]}',x['problem'],'Impacto: '+x['impact'],'Condições: '+x['condition']]
 for e in x['evidence']:md += [f'### {e["repo"]}/{e["file"]}:{e["start"]}–{e["end"]}','```',e['code'],'```',e['note']]
 md += ['Correção: '+x['fix']]
md+=['## Pontos fortes']
for title,es,note in strengths:
 md += [f'### {title}',note]
 for e in es:md += [f'{e["repo"]}/{e["file"]}:{e["start"]}–{e["end"]}','```',e['code'],'```']
md+=['## Cobertura completa de handlers','| Método e rota | Arquivo:linha | Handler | Resultado / achado |','|---|---|---|---|']
for r in coverage['routes']:md.append(f'| {r["method"]} {r["route"]} | {r["file"]}:{r["line"]} | {r["handler"]} | {r["status"] or "Não alcançável"}; {r["finding"]} |')
md+=['GET /: src/app.js:90–94, público, mensagem fixa. OPTIONS: src/app.js:64–74, 204 para preflight. Middleware errorHandler e todos os controllers/services/repositories revisados.','## Referências de remediação']
md += [f'[{n}]({u})' for n,u in data['references']]
md+=['## ISSUES PARA O GITHUB',*issues]
(OUT/'relatorio-auditoria-seguranca.md').write_text('\n\n'.join(md)+'\n')
print('Achados:',len(findings),'Contagens:',dict(collections.Counter(x['severity'] for x in findings)))
