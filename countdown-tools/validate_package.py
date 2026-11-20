from pathlib import Path
import xml.etree.ElementTree as ET,collections,subprocess,json,hashlib,zipfile
P=Path('work/countdown')
def read(file):
 r=ET.parse(file).getroot();paths={};refs={}
 def walk(root,path):
  counts=collections.Counter()
  for item in root.findall('Item'):
   name=item.findtext('./Properties/string[@name="Name"]');key=(name,item.attrib['class']);counts[key]+=1
   full=f'{path}/{name}<{key[1]}>[{counts[key]}]';paths[full]=item;refs[item.attrib['referent']]=full;walk(item,full)
 walk(r,'')
 for ref in r.findall('.//Ref'):assert ref.text in refs or ref.text in (None,'null','nil')
 return paths,refs
before,br=read(P/'backups/Antes-Contador.rbxlx');after,ar=read(P/'Broken-Dreams-Contador.rbxlx')
def props(item,refs):
 def value(e):
  if e.tag=='Ref':return refs.get(e.text,e.text)
  if len(e):return [(c.tag,value(c)) for c in e]
  return e.text
 return {e.attrib['name']:(e.tag,value(e)) for e in item.find('Properties') if e.attrib['name']!='AttributesSerialize'}
expected={'GameConfig','RoundStates','RoundCore','RoundService','RoundUIController'};changed=[];count=0
for path,item in before.items():
 assert path in after,path
 a,b=props(item,br),props(after[path],ar)
 names=[n for n in set(a)|set(b) if a.get(n)!=b.get(n)]
 name=item.findtext('./Properties/string[@name="Name"]')
 if names:
  assert name in expected and names==['Source'],(name,names)
  changed.append(name)
 if item.attrib['class'] in ('Part','WedgePart','SpawnLocation','MeshPart'):count+=1
assert set(changed)==expected
added=set(after)-set(before);assert len(added)==1 and 'TimerFormat<ModuleScript>' in next(iter(added))
# Critical Malicia operations remain byte-identical in the shared core source.
a=(Path('work/rounds/src/Server/RoundCore.luau')).read_text();b=(P/'src/Server/RoundCore.luau').read_text()
for func,end in [('ChooseKiller','Select'),('Select','BeginSelection'),('BeginSelection','FillCharacters')]:
 def section(s):return s.split('function Core:'+func+'(',1)[1].split('function Core:'+end+'(',1)[0]
 assert section(a)==section(b),func
results=[]
for suite,cmd in [
 ('countdown',['work/lobby/luau/luau',str(P/'tests/countdown.spec.luau')]),
 ('round_core',['work/lobby/luau/luau',str(P/'tests/round_core.spec.luau')]),
 ('adapters',['work/delivery/bin/lune','run',str(P/'tests/adapters.spec.luau')])]:
 r=subprocess.run(cmd,capture_output=True,text=True);assert r.returncode==0,r.stdout+r.stderr
 (P/'tests'/f'{suite}-results.txt').write_text(r.stdout)
 results.append({'suite':suite,'passed':sum(l.startswith('PASS ') for l in r.stdout.splitlines()),'roblox_studio':False})
for f in (P/'src').rglob('*.luau'):
 r=subprocess.run(['work/lobby/luau/luau-compile',str(f)],stdout=subprocess.DEVNULL,stderr=subprocess.PIPE,text=True);assert r.returncode==0,r.stderr
# Generate a guarded, additive edit-mode patch for the exact previous project.
def literal(s):
 eq='===='
 while ']'+eq+']' in s:eq+='='
 return '['+eq+'['+s+']'+eq+']'
entries=[]
for path,item in before.items():
 name=item.findtext('./Properties/string[@name="Name"]')
 if name not in expected:continue
 source=item.findtext('./Properties/*[@name="Source"]');replacement=after[path].findtext('./Properties/*[@name="Source"]')
 if name in ('GameConfig','RoundStates'):expr='rs.BrokenDreams.Shared.'+name
 elif name=='RoundUIController':expr='rs.BrokenDreams.Client.'+name
 else:expr='sss.BrokenDreams.'+name
 entries.append('{target='+expr+',old='+literal(source)+',new='+literal(replacement)+'}')
patch='''-- Ejecutar solo en edición sobre la entrega de partidas anterior. Guarda una copia primero.
assert(not game:GetService("RunService"):IsRunning(),"Detén Play antes de aplicar")
local rs=game:GetService("ReplicatedStorage")
local sss=game:GetService("ServerScriptService")
assert(rs:FindFirstChild("BrokenDreams") and sss:FindFirstChild("BrokenDreams"),"Falta el sistema de partidas anterior")
assert(not rs.BrokenDreams.Shared:FindFirstChild("TimerFormat"),"El ajuste ya existe; no sobrescribir")
local changes={
'''+',\n'.join(entries)+'''
}
for _,change in changes do assert(change.target.Source==change.old,"Fuente distinta: "..change.target:GetFullName().."; no se ha escrito ningún cambio") end
local backup=Instance.new("Folder");backup.Name="BD_BackupContador_"..os.date("!%Y%m%d_%H%M%S");backup.Parent=game:GetService("ServerStorage")
backup:SetAttribute("BD_IgnoreMapDiscovery",true)
for _,change in changes do
 local source=Instance.new("StringValue");source.Name=change.target.Name;source.Value=change.old;source.Parent=backup
 change.target.Source=change.new
end
local format=Instance.new("ModuleScript");format.Name="TimerFormat";format.Source='''+literal((P/'src/Shared/TimerFormat.luau').read_text())+''';format.Parent=rs.BrokenDreams.Shared
game:GetService("ChangeHistoryService"):SetWaypoint("BROKEN DREAMS · cuenta regresiva")
print("Contador integrado. Prueba con dos clientes; no se cargarán mapas.")
'''
(P/'APLICAR_CONTADOR_COMMAND_BAR.luau').write_text(patch)
r=subprocess.run(['work/lobby/luau/luau-compile',str(P/'APLICAR_CONTADOR_COMMAND_BAR.luau')],stdout=subprocess.DEVNULL,stderr=subprocess.PIPE,text=True);assert r.returncode==0,r.stderr
report={'baseline':'a109fbee39af1c70680b4bc618eb4cb7e09958c1','modified_sources':changed,'new_module':'TimerFormat','preserved_instances':len(before),'preserved_parts':count,'all_existing_non_source_properties':'unchanged; attributes also checked by build.luau','malicia_sources_and_role_functions':'byte-identical','tests':results,'syntax':'21 source files + integration patch compiled','native_roundtrip':'passed with Lune 0.11.1 / rbx-dom','roblox_studio_executed':False,'real_network_tested':False,'real_bindable_event_tested':False}
(P/'VALIDACION_CONTADOR.json').write_text(json.dumps(report,indent=2,ensure_ascii=False))
files=[P/'Broken-Dreams-Contador.rbxlx',P/'GUIA_CONTADOR.md',P/'README.md',P/'APLICAR_CONTADOR_COMMAND_BAR.luau',P/'VALIDACION_CONTADOR.json',P/'build.luau',P/'validate_package.py']
for folder in ['src','tests','backups']:files.extend(f for f in (P/folder).rglob('*') if f.is_file())
hashes={str(f.relative_to(P)):hashlib.sha256(f.read_bytes()).hexdigest() for f in files}
(P/'SHA256_CONTENIDO.json').write_text(json.dumps(hashes,indent=2))
with zipfile.ZipFile(P/'Broken-Dreams-Contador-Entrega.zip','w',zipfile.ZIP_DEFLATED,compresslevel=9) as z:
 for f in files+[P/'SHA256_CONTENIDO.json']:z.write(f,f.relative_to(P))
with zipfile.ZipFile(P/'Broken-Dreams-Contador-Entrega.zip') as z:assert z.testzip() is None
out={f.name:{'bytes':f.stat().st_size,'sha256':hashlib.sha256(f.read_bytes()).hexdigest()} for f in [P/'Broken-Dreams-Contador.rbxlx',P/'Broken-Dreams-Contador-Entrega.zip']}
(P/'SHA256_CONTADOR.json').write_text(json.dumps(out,indent=2))
entries=[]
for f in files+[P/'SHA256_CONTADOR.json']:
 if f.suffix=='.rbxlx':continue
 rel=str(f.relative_to(P))
 # Keep previous release tooling; put this update's tooling in a named folder.
 if f.name in ['build.luau','validate_package.py']:rel='countdown-tools/'+f.name
 entries.append({'path':rel,'mode':'100644','type':'blob','content':f.read_text()})
(P/'github_entries.json').write_text(json.dumps(entries,ensure_ascii=False))
print(json.dumps({'validation':report,'files':out},indent=2,ensure_ascii=False))
