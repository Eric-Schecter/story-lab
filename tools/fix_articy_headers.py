"""Preserve articy's explicit empty shared-string template header.

This is an OpenXML compatibility repair after artifact-tool authoring. Some
readers distinguish an absent/empty cell from an explicitly empty shared string.
"""
import sys
import zipfile
import xml.etree.ElementTree as ET
from pathlib import Path

path = Path(sys.argv[1])
output = path.with_name('fishing-import-fixed.xlsx')
namespace = 'http://schemas.openxmlformats.org/spreadsheetml/2006/main'
ns = {'x': namespace}
ET.register_namespace('x', namespace)
with zipfile.ZipFile(path) as archive:
    contents = {name: archive.read(name) for name in archive.namelist()}
strings = ET.fromstring(contents['xl/sharedStrings.xml'])
empty_index = len(strings)
empty = ET.SubElement(strings, f'{{{namespace}}}si')
ET.SubElement(empty, f'{{{namespace}}}t')
for sheet in ['sheet1', 'sheet2']:
    name = f'xl/worksheets/{sheet}.xml'
    root = ET.fromstring(contents[name])
    cell = root.find('.//x:c[@r="B2"]', ns)
    assert cell is not None
    cell.clear()
    cell.attrib.update(r='B2', s='1', t='s')
    ET.SubElement(cell, f'{{{namespace}}}v').text = str(empty_index)
    if len(sys.argv) > 2:
        project = ET.parse(sys.argv[2]).find('Content/Project')
        for address, value in [('D1', project.find('DisplayName').get('Value')), ('D2', project.get('Guid'))]:
            index = len(strings)
            ET.SubElement(ET.SubElement(strings, f'{{{namespace}}}si'), f'{{{namespace}}}t').text = value
            header = root.find(f'.//x:c[@r="{address}"]', ns)
            header.clear()
            header.attrib.update(r=address, s='1', t='s')
            ET.SubElement(header, f'{{{namespace}}}v').text = str(index)
    contents[name] = ET.tostring(root, encoding='utf-8', xml_declaration=True)
    print(f'{sheet}: Template Name = explicit empty string')
strings.set('uniqueCount', str(len(strings)))
contents['xl/sharedStrings.xml'] = ET.tostring(strings, encoding='utf-8', xml_declaration=True)
with zipfile.ZipFile(output, 'w', zipfile.ZIP_DEFLATED) as archive:
    for name, value in contents.items():
        archive.writestr(name, value)
print(output)
