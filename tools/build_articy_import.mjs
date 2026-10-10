import fs from 'node:fs/promises';
import { FileBlob, SpreadsheetFile } from '@oai/artifact-tool';

// Preserve articy's exported type headers; empty IDs request new objects.
const template = process.argv[2] ?? '/private/tmp/articy-template.xlsx';
const model = JSON.parse(await fs.readFile(new URL('../stories/fishing/design/story-model.json', import.meta.url), 'utf8'));
const wb = await SpreadsheetFile.importXlsx(await FileBlob.load(template));
console.log((await wb.inspect({kind:'sheet',include:'id,name',maxChars:1000})).ndjson);
const before = await wb.render({sheetName:'Entities',range:'A1:F6',scale:1,format:'png'});
await fs.writeFile('/private/tmp/articy-import-before.png', new Uint8Array(await before.arrayBuffer()));
for (const [sheetName, records, parentDefault] of [['Entities',model.characters,'Entities'],['Flow Fragments',model.nodes,'Flow']]) {
  const sheet = wb.worksheets.getItem(sheetName);
  // The artifact importer can turn articy's empty shared-string cell into "1".
  // These objects intentionally have no template. Explicitly clear the header.
  sheet.getRange('B2').clear({applyTo:'contents'});
  sheet.getRange('A5:J100').clear({applyTo:'contents'});
  const rows = records.map(n => ['',n.title,'Fishing_'+n.id,n.parent === 'Flow' || !n.parent ? parentDefault : 'Fishing_'+n.parent,n.kind === 'review' ? '#F2C580' : '#C8E2E7',n.text,'','','fishing:'+n.id,'']);
  sheet.getRange(`A5:J${4+rows.length}`).values=rows;
  sheet.getRange(`A5:J${4+rows.length}`).format.wrapText=true;
  sheet.getRange(`A5:J${4+rows.length}`).format.rowHeight=110;
}
wb.recalculate();
console.log((await wb.inspect({kind:'table',range:"'Flow Fragments'!B5:F8",tableMaxRows:4,tableMaxCols:5,maxChars:1800})).ndjson);
const preview = await wb.render({sheetName:'Flow Fragments',range:'B5:F8',scale:1,format:'png'});
await fs.writeFile('/private/tmp/articy-import-after.png',new Uint8Array(await preview.arrayBuffer()));
const output = await SpreadsheetFile.exportXlsx(wb);
await output.save(new URL('../stories/fishing/articy/fishing-import.xlsx',import.meta.url).pathname);
