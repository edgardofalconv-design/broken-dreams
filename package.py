from pathlib import Path
import hashlib,json,zipfile
P=Path('work/rounds')
name='Broken-Dreams-Partidas-Entrega.zip'
files=[P/'Broken-Dreams-Partidas.rbxlx',P/'Broken-Dreams-Sistema-Partidas.rbxmx',
       P/'GUIA_PARTIDAS.md',P/'PRUEBAS_STUDIO.md',P/'VALIDACION_PARTIDAS.json',P/'INSPECCION.json',
       P/'INSTALAR_EN_PROYECTO_EXISTENTE.luau',P/'README.md',P/'build.luau',P/'validate.py',P/'package.py']
for folder in ('src','tests','backups'):files+=sorted((P/folder).rglob('*'))
files=[f for f in files if f.is_file()]
checksums={str(f.relative_to(P)):hashlib.sha256(f.read_bytes()).hexdigest() for f in files}
(P/'SHA256_CONTENIDO.json').write_text(json.dumps(checksums,indent=2,ensure_ascii=False))
with zipfile.ZipFile(P/name,'w',zipfile.ZIP_DEFLATED,compresslevel=9) as z:
    for f in files+[P/'SHA256_CONTENIDO.json']:z.write(f,f.relative_to(P))
with zipfile.ZipFile(P/name) as z:
    assert z.testzip() is None
    for file,digest in checksums.items():assert hashlib.sha256(z.read(file)).hexdigest()==digest
    assert z.read('Broken-Dreams-Partidas.rbxlx')==(P/'Broken-Dreams-Partidas.rbxlx').read_bytes()
delivery={f.name:{'bytes':f.stat().st_size,'sha256':hashlib.sha256(f.read_bytes()).hexdigest()} for f in [P/'Broken-Dreams-Partidas.rbxlx',P/name,P/'Broken-Dreams-Sistema-Partidas.rbxmx']}
(P/'SHA256_PARTIDAS.json').write_text(json.dumps(delivery,indent=2))
print(json.dumps(delivery,indent=2))
# Text blobs are pushed as structured GitHub tree entries; large XML/ZIP separately.
entries=[]
for f in files:
    relative=str(f.relative_to(P))
    if f.suffix in ('.rbxlx','.rbxmx') or relative.startswith('backups/'):continue
    entries.append({'path':relative,'mode':'100644','type':'blob','content':f.read_text()})
for f in [P/'SHA256_PARTIDAS.json',P/'SHA256_CONTENIDO.json']:
    entries.append({'path':f.name,'mode':'100644','type':'blob','content':f.read_text()})
(P/'github_text_entries.json').write_text(json.dumps(entries,ensure_ascii=False))
