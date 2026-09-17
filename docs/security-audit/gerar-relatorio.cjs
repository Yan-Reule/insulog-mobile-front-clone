#!/usr/bin/env node
// Gera o PDF a partir do snapshot revisado; não reexecuta nem altera a aplicação.
const fs = require('node:fs');
const path = require('node:path');
const PDFDocument = require('pdfkit');
const SVGtoPDF = require('svg-to-pdfkit');
const root=__dirname;
const d=JSON.parse(fs.readFileSync(path.join(root,'dados-relatorio.json')));
const colors={'crítica':'#B91C1C','alta':'#EA580C','média':'#D97706','baixa':'#2563EB','informativa':'#64748B','forte':'#059669'};
const ink='#162D3D', muted='#526879', light='#F2F6F9', border='#DAE3EA';
const W=595.28,H=841.89,M=56.7,CW=W-2*M,BOTTOM=H-M;
const doc=new PDFDocument({size:'A4',margin:M,bufferPages:true,autoFirstPage:false,info:{Title:d.title,Author:'Auditoria de código — Insulog',Subject:'Cinco categorias de segurança e achados adicionais',CreationDate:new Date('2026-09-17T17:00:00Z')}});
const stream=fs.createWriteStream(path.join(root,'relatorio-auditoria-seguranca.pdf'));doc.pipe(stream);
const fonts=process.env.AUDIT_FONTS || '/usr/share/fonts/truetype/dejavu';
for(const [name,file] of [['body','DejaVuSans.ttf'],['bold','DejaVuSans-Bold.ttf'],['mono','DejaVuSansMono.ttf']])doc.registerFont(name,path.join(fonts,file));
let y=M;
const layout=[];
function page(title){doc.addPage();y=M; if(title)heading(title,18);}
function ensure(h){if(y+h>BOTTOM)page();}
function measure(text,size=9.4,width=CW,font='body'){doc.font(font).fontSize(size);return doc.heightOfString(String(text),{width,lineGap:2});}
function para(text,{size=9.4,color=ink,font='body',gap=8,width=CW,x=M}={}){
 const h=measure(text,size,width,font);ensure(h);doc.font(font).fontSize(size).fillColor(color).text(String(text),x,y,{width,lineGap:2});layout.push({page:doc.bufferedPageRange().count,y,h,type:'text'});y+=h+gap;
}
function heading(text,size=14){ensure(65);para(text,{size,font:'bold',gap:12});}
function label(text){para(text,{size:9,font:'bold',color:muted,gap:5});}
function code(text){
 const lines=[];doc.font('mono').fontSize(7.5);
 for(const raw of text.split('\n')){
  let line='';for(const ch of raw){if(doc.widthOfString(line+ch)>CW-22){lines.push(line);line='  '+ch;}else line+=ch;}lines.push(line);
 }
 if(lines.length<35)ensure(lines.length*11+8);
 for(const l of lines){ensure(11);doc.rect(M,y,CW,11).fill('#EDF2F6');doc.font('mono').fontSize(7.5).fillColor('#243B4B').text(l||' ',M+10,y+1,{width:CW-20,lineBreak:false});y+=11;}
 y+=8;
}
function chip(severity,x=M,yy=y){doc.roundedRect(x,yy,75,18,5).fill(colors[severity]||muted);doc.font('bold').fontSize(8).fillColor('#FFFFFF').text(severity.toUpperCase(),x+6,yy+4,{width:63,align:'center',lineBreak:false});}
function evidence(e){
 const pos=`${e.repo==='backend'?'B':'F'}/${e.file}:${e.start}${e.end!==e.start?'–'+e.end:''}`;
 ensure(Math.min(480,35+e.code.split('\n').reduce((n,l)=>n+Math.max(1,Math.ceil(l.length/96)),0)*11));label(pos);code(e.code);if(e.note)para(e.note,{size:8.5,color:muted});
}
function table(headers,rows,widths){
 function row(cells,header=false){
  const heights=cells.map((v,i)=>measure(v,header?8:8.2,widths[i]-14,header?'bold':'body'));
  const h=Math.max(...heights)+16;
  if(y+h>BOTTOM){page(); if(!header)row(headers,true);}
  let x=M;cells.forEach((v,i)=>{doc.rect(x,y,widths[i],h).fillAndStroke(header?ink:'#FFFFFF',border);doc.font(header?'bold':'body').fontSize(header?8:8.2).fillColor(header?'#FFFFFF':ink).text(v,x+7,y+8,{width:widths[i]-14,lineGap:2});x+=widths[i];});
  layout.push({page:doc.bufferedPageRange().count,y,h,type:'table'});y+=h;
 }
 row(headers,true);rows.forEach(r=>row(r));y+=14;
}
function findingTable(items){
 const widths=[85,190,CW-275];
 function header(){table(['Severidade','Arquivo:linha','Descrição'],[],widths);y-=14;}
 header();
 for(const a of items){
  for(const [i,e] of a.evidence.entries()){
   const pos=`${e.repo==='backend'?'B':'F'}/${e.file}:${e.start}${e.end!==e.start?'–'+e.end:''}`;
   const desc=i===0?`${a.id} — ${a.title}`:`${a.id} — evidência complementar${e.note?'; '+e.note:''}`;
   const h=Math.max(measure(pos,7.9,widths[1]-14),measure(desc,8.1,widths[2]-14),18)+16;
   if(y+h>BOTTOM){page();header();}
   let xx=M;for(const width of widths){doc.rect(xx,y,width,h).fillAndStroke('#FFFFFF',border);xx+=width;}
   chip(a.severity,M+5,y+8);
   doc.font('body').fontSize(7.9).fillColor(ink).text(pos,M+widths[0]+7,y+8,{width:widths[1]-14,lineGap:2});
   doc.font('body').fontSize(8.1).text(desc,M+275+7,y+8,{width:widths[2]-14,lineGap:2});
   layout.push({page:doc.bufferedPageRange().count,y,h,type:'finding-row'});y+=h;
  }
 }y+=14;
}
const sev=['crítica','alta','média','baixa','informativa'];const counts=sev.map(s=>d.findings.filter(f=>f.severity===s).length);
function donut(){let angle=-Math.PI/2;const cx=125,cy=116,r=77,ir=47;let pieces='';
 counts.forEach((v,i)=>{if(!v)return;const end=angle+2*Math.PI*v/d.findings.length;const p=(rr,a)=>`${cx+rr*Math.cos(a)} ${cy+rr*Math.sin(a)}`;
 pieces+=`<path d="M ${p(r,angle)} A ${r} ${r} 0 ${end-angle>Math.PI?1:0} 1 ${p(r,end)} L ${p(ir,end)} A ${ir} ${ir} 0 ${end-angle>Math.PI?1:0} 0 ${p(ir,angle)} Z" fill="${colors[sev[i]]}"/>`;angle=end;});
 return `<svg xmlns="http://www.w3.org/2000/svg" width="480" height="235"><rect width="480" height="235" fill="white"/>${pieces}<text x="125" y="119" font-family="DejaVu Sans" font-size="28" font-weight="bold" text-anchor="middle" fill="${ink}">8</text><text x="125" y="138" font-family="DejaVu Sans" font-size="11" text-anchor="middle" fill="${muted}">achados</text>${sev.map((s,i)=>`<rect x="250" y="${42+i*32}" width="14" height="14" rx="3" fill="${colors[s]}"/><text x="275" y="${54+i*32}" font-family="DejaVu Sans" font-size="14" fill="${ink}">${s}: ${counts[i]}</text>`).join('')}</svg>`;
}
function bars(){const cats=['1. Isolamento','2. Permissões','3. IDOR','4. Segredos em código','5. XSS','Extras'];const vals=[1,1,2,1,0,3];
 return `<svg xmlns="http://www.w3.org/2000/svg" width="480" height="235"><rect width="480" height="235" fill="white"/>${cats.map((c,i)=>`<text x="0" y="${27+i*34}" font-family="DejaVu Sans" font-size="12" fill="${ink}">${c}</text><rect x="165" y="${12+i*34}" width="${vals[i]*85}" height="22" rx="4" fill="${i===5?'#64748B':'#2563EB'}"/><text x="${175+vals[i]*85}" y="${28+i*34}" font-family="DejaVu Sans" font-size="12" fill="${ink}">${vals[i]}</text>`).join('')}</svg>`;
}
const donutSvg=donut(),barsSvg=bars();fs.writeFileSync(path.join(root,'grafico-severidades.svg'),donutSvg);fs.writeFileSync(path.join(root,'grafico-categorias.svg'),barsSvg);
page();doc.rect(0,0,W,18).fill('#059669');y=115;
para('INSULOG  /  SEGURANÇA DE APLICAÇÕES',{size:10,font:'bold',color:colors.forte,gap:23});
para('Relatório de Auditoria\nde Segurança — Insulog',{size:29,font:'bold',gap:22});
para('Revisão de código • Evidências rastreáveis • Plano de correção',{size:12,color:muted,gap:34});
para(d.date,{size:15,font:'bold',gap:28});
label('ESCOPO AUDITADO');para('Frontend Flutter/Dart e backend Node.js/Express/MySQL dos clones locais. Código próprio, configurações, CI, documentação, histórico Git alcançável e bundle web gerado nesta revisão.');
para(`Frontend: ${d.inventory.repositories.frontend.head}\nBackend: ${d.inventory.repositories.backend.head}`,{size:8.5,font:'mono',gap:22});
label('NOTA METODOLÓGICA');para('As cinco categorias foram adaptadas a filtros manuais de dono no MySQL, autorização das rotas Express, IDs em path/query/body, segredos em arquivos/histórico/bundle e sinks de HTML/JavaScript no Flutter web e backend. Achados adicionais de logs, armazenamento e transporte são contados separadamente.');
para('Revisão estática com reprodução local usando banco simulado. Não houve acesso a dados reais, uso de credenciais históricas, alteração da aplicação ou publicação de issues.',{size:9,color:muted});
page('Resumo executivo');
para('A fronteira de autenticação termina no login. A API permite consultar dados de outros pacientes e alterar contas e registros sem identidade validada. A prioridade é impedir acesso anônimo e vincular toda operação ao dono autorizado.');
para('8 achados: 1 crítico • 5 altos • 2 médios • 0 baixos • 0 informativos',{size:11,font:'bold'});
heading('Distribuição por severidade',12);SVGtoPDF(doc,donutSvg,M,y,{width:CW,height:235});y+=239;
heading('Distribuição por categoria',12);SVGtoPDF(doc,barsSvg,M,y,{width:CW,height:235});y+=240;
para('Contagem por causa/escopo acionável, sem duplicar listagens por ID entre isolamento e IDOR. Cinco achados nas categorias solicitadas e três extras. Nenhum XSS confirmado.',{size:8.5,color:muted});
page('Stack, escopo e limites');
table(['Camada','Detecção / evidência'],[
['Frontend','Dart (SDK declarado ^3.11.4), Flutter, package:http, shared_preferences, share_plus, flutter_svg. pubspec.yaml:1–26; suporte web e runners nativos.'],
['Backend','JavaScript CommonJS, Express ^5.2.1, mysql2 ^3.20.0; SQL manual, sem ORM/query builder. package.json:9–23.'],
['Autenticação','Login com scrypt e fallback legado; resposta somente com usuário. Sem sessão, JWT, cookie de autenticação ou middleware de autorização no código.'],
['Isolamento','Filtros manuais id_usuario e join de registroinsulina → registroglicose. Sem identidade autenticada nem mecanismo de tenant. Relação paciente/médico é persistida, mas não autoriza consultas.'],
['Relatórios','PDFKit ^0.20.2 e ExcelJS ^4.4.0; sem templates de HTML/e-mail.'],
['Deploy/CI','GitHub Actions (Flutter Tests, API Tests), Gradle e projetos de plataforma. Não encontrados Dockerfile, compose, Helm, Terraform ou configuração de gateway nos arquivos próprios atuais/históricos inspecionados.']
],[100,CW-100]);
para('F/ identifica a raiz insulog-mobile-front-clone; B/ identifica ../insulog-back-clone. Números de linha referem-se aos HEADs da capa, exceto evidências históricas explicitamente marcadas.');
para('Cobertura: 217 arquivos próprios versionados no frontend e 54 no backend inventariados; 17 + 19 commits e 302 + 124 blobs textuais próprios examinados por padrões. Arquivos de dependências, binários e runners gerados não receberam auditoria integral de implementação. Todos os controllers, services, repositories e routers próprios do backend foram lidos.');
para('Limites: sem validação do banco/deploy real, constraints completas, credenciais atuais, gateway, ACL de rede, reflogs/objetos perdidos ou remotos não baixados. Busca de segredos por padrões e revisão manual não garante ausência absoluta. Este relatório não é auditoria de CVEs de dependências.');
page('Mapeamento das cinco categorias');
for(const [title,text] of d.category_status){heading(title,11);para(text);}
page('Pontos fortes e riscos centrais');
for(const [title,evs,note] of d.strengths){ensure(80);para('✓ '+title,{font:'bold',color:colors.forte});para(note,{size:9});para(evs.map(e=>`${e.repo==='backend'?'B':'F'}/${e.file}:${e.start}–${e.end}`).join('\n'),{size:8.1,color:muted});}
heading('Pontos fracos',13);para('Identidade local não autentica chamadas HTTP; queries globais e IDs controláveis quebram confidencialidade e integridade. Senhas também escapam por logs, persistência local e rede sem TLS. A senha de banco retirada do HEAD ainda pode ser recuperada pelo histórico.');
page('Tabela de achados por categoria');
para('Cada linha aponta um trecho exato; as páginas seguintes trazem código, impacto, condições e correção. Os chips indicam a severidade do achado ao qual a evidência pertence.',{size:9,color:muted});
for(const cat of [...new Set(d.findings.map(f=>f.category))]){heading(cat,12);findingTable(d.findings.filter(f=>f.category===cat));}
heading('5. XSS',12);para('Nenhum achado confirmado; resultado e evidências positivas registrados no escopo e nos pontos fortes.');
for(const a of d.findings){
 page(`${a.id} — ${a.title}`);chip(a.severity);y+=29;
 label('PROBLEMA E EXPLORABILIDADE');para(a.problem);label('IMPACTO');para(a.impact);label('CONDIÇÕES E VALIDAÇÃO');para(a.condition);
 heading('Evidências por arquivo e linha',12);a.evidence.forEach(evidence);
 label('CORREÇÃO PROPOSTA');para(a.fix);
}
page('Cobertura de todos os handlers');
para('48 registros em 9 routers, mais GET / no app. 47 handlers dos routers exercitados por HTTP local, com app/controllers/services/repositories reais e apenas pool/conexão de banco simulados. Todos aceitaram payloads válidos sem cookie/token. O login recebeu senha fictícia válida; sua exposição pública é esperada. Catálogos de leitura não são tratados como dados privados.');
para('Um handler registrado não é alcançável: GET /usuarios/:tipo_usuario é capturado primeiro por GET /usuarios/:id (userRoutes.js:9–10). Seu código foi revisado, mas não é reportado como caminho adicional explorável. GET / e OPTIONS foram revisados estaticamente.',{size:9,color:muted});
for(const file of [...new Set(d.coverage.routes.map(r=>r.file))]){
 const rows=d.coverage.routes.filter(r=>r.file===file);heading('B/'+file,11);
 para('Cadeia revisada: '+rows[0].chain.join(' → '),{size:8.2,color:muted});
 table(['Rota / linha','Handler / HTTP','Resultado'],rows.map(r=>[`${r.method} ${r.route}\nLinha ${r.line}`,`${r.handler}\n${r.status||'Sombreado'}`,r.finding]),[190,150,CW-340]);
}
para('GET /: B/src/app.js:90–94 retorna mensagem fixa. OPTIONS: B/src/app.js:64–74 responde 204; CORS limita leitura no navegador, mas não autentica clientes HTTP. B/src/middlewares/errorHandler.js:1–27 também foi revisado.');
page('Cruzamento frontend ↔ API');
para('Não foram encontrados gates isAdmin/canEdit/role nem branches de UI por tipo_usuario. A única atribuição de tipo_usuario no app é paciente no cadastro. A navegação após login e IDs em Globals são estado local; não substituem autorização.');
for(const [title,file,endpoints,result] of d.frontend_cross){heading(title,12);para(file,{size:8.5,color:muted});para(endpoints,{font:'bold',size:9});para(result);}
page('Histórico, bundle e verificações');
para('Segredos: o histórico contém duas versões de .env com senha de banco não vazia (F05). Três candidatos em database.js eram referências process.env, não segredos literais. O HEAD lê ambiente e não traz defaults de senha; .gitignore do backend ignora .env, mas isso não remove commits antigos.');
para('Bundle: flutter build web --release --no-pub concluiu. Foram inventariados 40 arquivos em build/web; main.dart.js tem 3.271.579 bytes. Busca por tokens conhecidos e atribuições de segredos não encontrou candidatos; busca exata pelas credenciais históricas também não encontrou correspondência. Isso cobre o bundle local gerado, não um artefato publicado em loja/servidor.');
para('XSS: busca por innerHTML/outerHTML, equivalentes, WebView/HtmlWidget, eval/new Function, javascript:, URLs de usuário e renderização markdown/HTML; revisão dos pontos de texto e saída. Nenhum fluxo confirmado. web/index.html usa recursos estáticos. O SVG do relatório vem de asset local fixo. Não há sanitizador HTML aplicado pela aplicação; no fluxo atual não existe sink que demande essa sanitização.');
para('Validação: 21 testes existentes da API passaram. O script verificar-api.cjs confirmou 47 handlers alcançáveis, atualização anônima de senha, hash em GET /usuarios e senha fictícia nos logs. Não foram executadas queries reais. Testes não provam comportamento das constraints ou segurança de um deploy externo.');
para('A compilação web emitiu aviso de referência a CupertinoIcons sem fonte correspondente, mas concluiu. Isso não é achado de segurança. Compilação e testes locais precisaram de execução fora do sandbox para cache Flutter e socket loopback.');
para('Reprodução e rastreabilidade: README.md explica os comandos; inventario-evidencias.json registra hashes, contagens e candidatos sem valores secretos; verificacao-api.json lista resultado por rota. Os scripts de relatório usam o snapshot revisado, não substituem nova auditoria após alterações no código.');
page('Recomendações priorizadas');
table(['Prioridade','Ação / aceite principal'],[
['P1 — F03, F01, F04','Implementar identidade validada e autorização por dono em toda rota privada; bloquear troca de senha alheia, listagens globais e associação de registros entre pacientes. Testar anônimo, A→A, A→B e vínculo médico-paciente.'],
['P1 — F02','Restringir manutenção de catálogos a permissão explícita ou remover endpoints de escrita não usados.'],
['P1 — F06, F08','Eliminar corpos sensíveis dos logs e usar HTTPS no cliente release. Confirmar que senha sintética não aparece em stdout ou tráfego legível.'],
['P2 — F05','Rotacionar credencial histórica, verificar reutilização e coordenar limpeza do Git; não basta apagar o arquivo no HEAD.'],
['P2 — F07','Migrar senha persistida para sessão revogável e apagar saved_password; depende do mecanismo de sessão de P1.'],
['P3 — sustentação','Adicionar testes de autorização por endpoint, scanner de segredos no CI e revisão de configuração de startup. Manter projeção de resposta sem senha, validações de exportação e consultas parametrizadas.']
],[93,CW-93]);
para('Validar permissões a cada requisição e negar acesso por padrão orienta P1. Rotação e gestão do ciclo de vida dos segredos orientam F05. Referências de remediação da OWASP; os achados se baseiam exclusivamente no código local.',{size:9});
for(const [name,url] of d.references){para(name,{size:9,font:'bold'});para(url,{size:8,color:'#2563EB'});}
// Esta seção deve ser a última do PDF.
page('ISSUES PARA O GITHUB');
para('Textos completos em Markdown, prontos para copiar. Também disponíveis em issues-github.md. Nenhuma issue foi publicada. Evidências relacionadas foram agrupadas por causa e correção para evitar duplicação.');
for(let i=0;i<d.issues.length;i++){
 if(i)page(`ISSUES PARA O GITHUB — ${i+1}/8`);
 // Mantém todo o conteúdo Markdown, com espaçamento compacto para leitura no PDF.
 code(d.issues[i].replace(/\n\n/g,'\n'));
}
const range=doc.bufferedPageRange();
for(let i=range.start;i<range.start+range.count;i++){
 doc.switchToPage(i);
 doc.page.margins.bottom=0;
 doc.save();doc.moveTo(M,35).lineTo(W-M,35).lineWidth(.5).stroke(border);
 doc.font('body').fontSize(7.5).fillColor(muted).text('Insulog • Relatório de Auditoria de Segurança',M,22,{width:CW,lineBreak:false});
 doc.moveTo(M,H-40).lineTo(W-M,H-40).stroke(border);
 doc.font('body').fontSize(7.5).fillColor(muted).text(`17/09/2026  •  Revisão dos clones locais`,M,H-29,{width:CW-80,lineBreak:false});
 doc.text(`${i+1} / ${range.count}`,W-M-60,H-29,{width:60,align:'right',lineBreak:false});doc.restore();
}
fs.writeFileSync(path.join(root,'verificacao-layout.json'),JSON.stringify({pages:range.count,pageSize:'A4',marginPoints:M,contentBottom:BOTTOM,overflow:layout.filter(x=>x.y+x.h>BOTTOM+.1),blocks:layout.length},null,2)+'\n');
doc.end();stream.on('finish',()=>console.log(`PDF gerado: ${range.count} páginas; ${layout.length} blocos.`));
