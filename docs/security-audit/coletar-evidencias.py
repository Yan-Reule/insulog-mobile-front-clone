#!/usr/bin/env python3
"""Inventaria fontes, histórico alcançável e bundle local; não imprime segredos."""
import hashlib,json,pathlib,re,subprocess
OUT=pathlib.Path(__file__).resolve().parent
FRONT=OUT.parent.parent
BACK=FRONT.parent/'insulog-back-clone'
def git(repo,*args):return subprocess.check_output(['git','-C',str(repo),*args])
pattern=re.compile(r'(?i)(DB_PASSWORD|JWT_SECRET|API_KEY|PRIVATE KEY|(?:password|senha|secret)\s*[:=]\s*[\x27\x22]|gh[pousr]_[A-Za-z0-9]{20}|AKIA[A-Z0-9]{16}|\$\{[^}]+:-)')
xss=re.compile(r'innerHTML|outerHTML|dangerouslySetInnerHTML|v-html|HtmlElement|HtmlWidget|WebView|javascript:|\beval\s*\(|new Function|launchUrl|Image\.network')
result={'method':'Busca de padrões + revisão manual. Não é prova de ausência de segredos. Dependências de terceiros fora da auditoria de lógica; inventário cobre arquivos próprios. Histórico alcançável por --all; sem reflogs, remotos não baixados ou objetos perdidos.','repositories':{},'bundle':{}}
secrets=[]
for label,repo in [('frontend',FRONT),('backend',BACK)]:
 current=[]; hits=[]; blobs=0
 for name in git(repo,'ls-files','-z').decode().split('\0'):
  if not name or name.startswith('node_modules/'):continue
  f=repo/name
  if f.is_file():
   data=f.read_bytes()
   current.append({'file':name,'sha256':hashlib.sha256(data).hexdigest(),'lines':data.count(b'\n'),'xss_pattern_lines': [] if b'\0' in data else [i for i,l in enumerate(data.decode('utf8','replace').splitlines(),1) if xss.search(l)]})
 entries=git(repo,'rev-list','--objects','--all').decode().splitlines()
 for ent in entries:
  parts=ent.split(' ',1)
  if len(parts)<2 or parts[1].startswith('node_modules/'):continue
  oid,name=parts
  if subprocess.run(['git','-C',str(repo),'cat-file','-t',oid],capture_output=True,text=True).stdout.strip()!='blob':continue
  data=git(repo,'cat-file','blob',oid)
  if b'\0' in data:continue
  try:txt=data.decode('utf8')
  except UnicodeDecodeError:continue
  blobs+=1
  for i,l in enumerate(txt.splitlines(),1):
   if pattern.search(l):
    hits.append({'blob':oid,'file':name,'line':i,'classification':'revisão manual necessária; valor omitido'})
   if name=='.env' and l.startswith('DB_PASSWORD='):
    val=l.split('=',1)[1].strip().strip('\"\x27')
    if val and val not in secrets:secrets.append(val)
 result['repositories'][label]={'head':git(repo,'rev-parse','HEAD').decode().strip(),'commits':int(git(repo,'rev-list','--all','--count')),'text_blobs_scanned':blobs,'tracked_own_files':current,'history_candidates':hits,'shallow':git(repo,'rev-parse','--is-shallow-repository').decode().strip()}
files=[]
for f in sorted((FRONT/'build/web').rglob('*')):
 if not f.is_file():continue
 data=f.read_bytes()
 matches=[]
 if f.suffix in ['.js','.json','.html','.wasm']:
  for s in secrets:
   if s.encode() in data:matches.append('Sequência igual à senha histórica; requer revisão contextual')
 files.append({'file':str(f.relative_to(FRONT)),'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest(),'historical_secret_candidates':matches})
result['bundle']={'build':'flutter build web --release --no-pub','files':files}
(OUT/'inventario-evidencias.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
print(json.dumps({k:{'commits':v['commits'],'text_blobs':v['text_blobs_scanned'],'own_files':len(v['tracked_own_files']),'candidates':len(v['history_candidates'])} for k,v in result['repositories'].items()}))
print('Bundle files:',len(files),'historical credential candidate files:',sum(bool(f['historical_secret_candidates']) for f in files))
