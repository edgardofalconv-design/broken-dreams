from pathlib import Path
import collections, hashlib, json, subprocess, xml.etree.ElementTree as ET

P=Path('work/rounds')
base=P/'backups/Broken-Dreams-Antes-Partidas.rbxlx'
place=P/'Broken-Dreams-Partidas.rbxlx'
def read(path):
    root=ET.parse(path).getroot(); by_path={}; refs={}
    def walk(parent,path):
        counts=collections.Counter()
        for child in parent.findall('Item'):
            name=child.findtext('./Properties/string[@name="Name"]') or child.attrib['class']
            key=(name,child.attrib['class']); counts[key]+=1
            current=f'{path}/{name}<{key[1]}>[{counts[key]}]'
            by_path[current]=child; refs[child.attrib['referent']]=current; walk(child,current)
    walk(root,'')
    for ref in root.findall('.//Ref'):
        assert ref.text in refs or ref.text in (None,'null','nil'),('Dangling reference',ref.text)
    return root,by_path,refs
_,before,brefs=read(base)
root,after,refs=read(place)
parts={'Part','WedgePart','SpawnLocation','MeshPart','UnionOperation','TrussPart'}
def properties(item,refmap):
    result={}
    def value(e):
        if e.tag=='Ref': return refmap.get(e.text,e.text)
        if len(e): return [(c.tag,value(c)) for c in e]
        return e.text
    for e in item.find('Properties'):
        # Attributes are checked semantically by the Lune build, not by binary ordering.
        if e.attrib.get('name') not in ('AttributesSerialize',):result[e.attrib['name']]=(e.tag,value(e))
    return result
preserved=0;modified=[]
for path,item in before.items():
    assert path in after,('Missing original instance',path)
    a,b=properties(item,brefs),properties(after[path],refs)
    changes=[name for name in set(a)|set(b) if a.get(name)!=b.get(name)]
    if changes:
        assert path.endswith('/LobbyHUD<LocalScript>[1]') and changes==['Source'],(path,changes)
        modified.append(path)
    if item.attrib['class'] in parts:preserved+=1
assert preserved==5580 and len(modified)==1
counts=collections.Counter(i.attrib['class'] for i in after.values())
assert counts['ScreenGui']==1 and counts['SpawnLocation']==1
assert not any('TextButton'==i.attrib['class'] for i in after.values()) # Runtime spectator only; no PLAY

# Validate exact native arena layout without claiming a Roblox physics session.
arena_path=next(p for p in after if p.endswith('/BD_TestArena<Model>[1]'))
def vec(item,prop):
    e=item.find(f'./Properties/*[@name="{prop}"]');return [float(e.findtext(c)) for c in ('X','Y','Z')]
def xyz(item):return vec(item,'CFrame')
arena={p:i for p,i in after.items() if p.startswith(arena_path+'/')}
colliders=[]
for p,i in arena.items():
    if i.attrib['class']=='Part' and i.findtext('./Properties/bool[@name="CanCollide"]')=='true':colliders.append((p,xyz(i),vec(i,'size')))
ground=next(i for p,i in arena.items() if '/TestGround<Part>' in p)
floor=xyz(ground)[1]+vec(ground,'size')[1]/2
markers=[(p,i) for p,i in arena.items() if '/RoundSpawns<Folder>' in p and i.attrib['class']=='Part']
assert len(markers)==8
safe=[]
for p,m in markers:
    x,y,z=xyz(m); escape='/Escape<' in p; sx,sy,sz=(9,10,6) if escape else (4,6,4)
    assert 343<x-sx/2 and x+sx/2<457 and -52<z-sz/2 and z+sz/2<52
    assert abs(y-floor)<.5 and x>300
    center=[x,floor+sy/2+.15,z];size=[sx,sy,sz]
    for op,oc,os in colliders:
        overlap=all(abs(center[j]-oc[j])<(size[j]+os[j])/2-1e-4 for j in range(3))
        assert not overlap,('Blocked provisional spawn',p,op)
    safe.append((p,xyz(m)))
k=next(v for p,v in safe if '/Killer<' in p)
survivors=[v for p,v in safe if '/Survivors<Folder>' in p]
for i,v in enumerate(survivors):
    assert sum((a-b)**2 for a,b in zip(v,k))**.5>=24
    for u in survivors[i+1:]:assert sum((a-b)**2 for a,b in zip(v,u))**.5>=5

compiled=[]
for path in sorted((P/'src').rglob('*.luau')):
    run=subprocess.run(['work/lobby/luau/luau-compile',str(path)],stdout=subprocess.DEVNULL,stderr=subprocess.PIPE,text=True)
    assert run.returncode==0,(str(path),run.stderr)
    compiled.append(str(path.relative_to(P)))
for tool in ('build.luau','INSTALAR_EN_PROYECTO_EXISTENTE.luau'):
    run=subprocess.run(['work/lobby/luau/luau-compile',str(P/tool)],stdout=subprocess.DEVNULL,stderr=subprocess.PIPE,text=True)
    assert run.returncode==0,(tool,run.stderr)
test_results=[]
for name,cmd in [
    ('Pure round logic',['work/lobby/luau/luau',str(P/'tests/round_core.spec.luau')]),
    ('Adapters with explicit test doubles',['work/delivery/bin/lune','run',str(P/'tests/adapters.spec.luau')]),
]:
    run=subprocess.run(cmd,capture_output=True,text=True);assert run.returncode==0,run.stdout+run.stderr
    (P/'tests'/('core-results.txt' if 'Pure' in name else 'adapter-results.txt')).write_text(run.stdout)
    test_results.append({'suite':name,'passed':sum(line.startswith('PASS ') for line in run.stdout.splitlines()),'roblox_engine':False})

# Every source embedded in the place must match the delivered source exactly.
embedded=[]
for path,item in after.items():
    if item.attrib['class'] not in ('Script','LocalScript','ModuleScript'):continue
    name=item.findtext('./Properties/string[@name="Name"]')
    source=item.findtext('./Properties/*[@name="Source"]')
    if name in ('BrokenDreamsLobbyAPI','BrokenDreamsLobbyServer'):continue
    candidates=[p for p in (P/'src').rglob('*.luau') if p.name.split('.')[0]==name]
    assert len(candidates)==1,(name,candidates)
    assert source==candidates[0].read_text(),name
    embedded.append(name)
report={
    'status':'LOCAL_VALIDATION_PASSED_STUDIO_PENDING',
    'baseline_commit':'0bac0d0079bb7dd3c896c6313e470c42d3ac7bdb',
    'baseline_sha256':hashlib.sha256(base.read_bytes()).hexdigest(),
    'preserved_original_instances':len(before),'preserved_original_parts':preserved,
    'modified_existing_scripts':modified,'lighting_and_other_original_properties':'unchanged',
    'new_map':'BD_TestArena; provisional; Studio only; never The Forgotten Glade',
    'official_forgotten_glade_exists':False,'provisional_spawn_markers_checked':len(safe),
    'geometry_check':'Static axis-aligned bounds and clearance on serialized provisional arena; not Roblox physics',
    'classes':dict(counts),'compiled_source_files':compiled,'embedded_sources_match':embedded,
    'local_tests':test_results,'xml_references':'All resolved','native_roundtrip':'Lune 0.11.1 / rbx-dom',
    'roblox_studio_executed':False,'multiclient_executed':False,
    'pending':'All cases in PRUEBAS_STUDIO.md, including Humanoid death/reset recovery, prompts under latency, camera and mobile UI',
}
(P/'VALIDACION_PARTIDAS.json').write_text(json.dumps(report,indent=2,ensure_ascii=False))
print(json.dumps({k:report[k] for k in ('preserved_original_instances','preserved_original_parts','provisional_spawn_markers_checked','local_tests','roblox_studio_executed')},ensure_ascii=False))
