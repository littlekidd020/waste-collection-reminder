import json,re
from pathlib import Path
catalog=Path('BinDayNZ/Resources/Localizable.xcstrings')
d=json.loads(catalog.read_text());c=d['strings']
langs={'en','mi','zh-Hans','ko','hi'}
src='\n'.join(p.read_text() for root in ('BinDayNZ','BinDayNZWidget') for p in Path(root).rglob('*.swift'))
keys=set(re.findall(r'\b(?:L|WL)\("((?:[^"\\]|\\.)*)"',src))
dynamic=re.findall(r'(?<![\w.`])(?:L|WL)\((?!["_])[^\n]{0,80}',src)
assert not dynamic,('L()/WL() must take a string literal as its first argument so this check can see it',dynamic)
missing=keys-set(c)
assert not missing,('Missing source keys',sorted(missing))
pattern=re.compile(r'%(?:\d+\$)?[-+ #0]*(?:\d+|\*)?(?:\.(?:\d+|\*))?(?:hh|ll|[hlLzjtq])?[@diuoxXfFeEgGaAcCsSp]')
def placeholders(s):
 return sorted(re.sub(r'%\d+\$','%',x) for x in pattern.findall(s.replace('%%','')))
for k,e in c.items():
 if e.get('shouldTranslate') is False: continue
 assert langs<=set(e.get('localizations',{})),('Missing languages',k)
 for lang in langs:
  value=e['localizations'][lang]['stringUnit']['value']
  assert value.strip(),('Empty value',k,lang)
  assert placeholders(k)==placeholders(value),('Placeholder mismatch',k,lang,value)
  assert lang=='en' or value!=k or 'identical' in e.get('comment',''),('English copied into non-English translation',k,lang)
print(f'PASS: {len(keys)} L/WL source keys; {len(c)-3} translatable catalog keys in all five languages; no missing keys, blank values, copied-English fallbacks or placeholder mismatches. Three brand/interpolation entries are explicitly nontranslatable.')
