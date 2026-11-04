const {chromium}=require('playwright');
const fs=require('node:fs/promises');
const path=require('node:path');
const crypto=require('node:crypto');
const OUT=process.env.TC16_SCREENSHOTS_DIR ? path.resolve(process.env.TC16_SCREENSHOTS_DIR) : path.resolve(process.cwd(),'sdlc/6-eval/manual/2026-11-04/TC-16/screenshots');
const ORIGIN='http://127.0.0.1:8080', SLUG='e24-longest-run', MISSING='tc-missing-2026-11-04';
const sha=b=>crypto.createHash('sha256').update(b).digest('hex');
async function enableA11y(p,mobile){
  await p.waitForFunction(()=>!!document.querySelector('flt-semantics-placeholder')||!!document.querySelector('flt-semantics'),null,{timeout:20000});
  if(await p.locator('flt-semantics').count()) return true;
  const ph=p.locator('flt-semantics-placeholder'); await ph.waitFor({state:'visible',timeout:10000}); const b=await ph.boundingBox(); if(!b) throw Error('placeholder_bounds_missing');
  if(mobile) await p.touchscreen.tap(b.x+b.width/2,b.y+b.height/2); else {await ph.focus(); await p.keyboard.press('Enter');}
  await p.locator('flt-semantics').first().waitFor({state:'attached',timeout:10000}); return true;
}
const contentField=r=>['content','file_content','contents','body'].find(k=>typeof r?.[k]==='string');
const nameField=r=>['filename','file_name','name'].find(k=>typeof r?.[k]==='string');
async function runViewport(browser,width,mobile){
 const ctx=await browser.newContext({viewport:{width,height:mobile?800:900},isMobile:mobile,hasTouch:mobile,userAgent:mobile?'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36':undefined,acceptDownloads:true});
 const result={width}; const page=await ctx.newPage(); await ctx.grantPermissions(['clipboard-read','clipboard-write'],{origin:ORIGIN});
 if(mobile) await ctx.addInitScript(()=>Object.defineProperty(navigator,'platform',{get:()=> 'Linux armv8l'}));
 let taskBody=null,fileBody=null,taskId=null,clipboardOriginal,clipboardReadable=false,clipboardRestored=false,tempDownload=null;
 let taskResponseReceived=false,fileResponseReceived=false,fileTaskIdMatches=false,missingCount=0,diag={};
 page.on('response',async r=>{try{const u=new URL(r.url()); if(u.pathname.endsWith('/tasks_public')&&u.searchParams.get('slug')==='eq.'+SLUG){taskResponseReceived=true;taskBody=await r.json();const row=Array.isArray(taskBody)?taskBody[0]:null;taskId=row?.id||null;} if(u.pathname.endsWith('/task_files')&&taskId&&u.searchParams.get('task_id')==='eq.'+taskId){fileResponseReceived=true;fileTaskIdMatches=true;fileBody=await r.json();} if(u.pathname.endsWith('/tasks_public')&&u.searchParams.get('slug')==='eq.'+MISSING)missingCount++;}catch{}});
 const bounds=async loc=>{const b=await loc.boundingBox();return b?{x:Math.round(b.x*10)/10,y:Math.round(b.y*10)/10,width:Math.round(b.width*10)/10,height:Math.round(b.height*10)/10}:null;};
 try{
  await page.goto(ORIGIN); await enableA11y(page,mobile); if(mobile)result.platform=await page.evaluate(()=>navigator.platform);
  await page.getByRole('button',{name:'Тестовый вход',exact:true}).click(); await page.waitForTimeout(3500);
  const search=page.getByRole('textbox').first(); await search.fill('Наибольший фрагмент без запретного сочетания'); await page.waitForTimeout(1200);
  const card=page.getByRole('button',{name:/Наибольший фрагмент без запретного сочетания/}); if(await card.count()!==1) throw Error('catalog_card_count');
  await card.click(); await page.waitForFunction(()=>location.hash.includes('/task/'+ 'e24-longest-run'),null,{timeout:10000});
  await page.waitForFunction(()=>!!document.querySelector('flt-semantics'),null,{timeout:10000}); await page.screenshot({path:path.join(OUT,`followup-02-rerun-${width}-task.png`)});
  await page.getByRole('tab',{name:'Файлы',exact:true}).click(); await page.waitForTimeout(700);
  const tabDiag=await page.evaluate(()=>[...document.querySelectorAll('[role="tab"]')].map(e=>({name:e.getAttribute('aria-label')||e.innerText,selected:e.getAttribute('aria-selected')})));
  await page.screenshot({path:path.join(OUT,`followup-02-rerun-${width}-files-tab.png`)});
  if(!taskResponseReceived||!fileResponseReceived) await page.waitForTimeout(300); // allow response listeners to finish parsing in memory
  await page.waitForTimeout(500);
  const f=Array.isArray(fileBody)?fileBody[0]:null; const fContentKey=contentField(f), fNameKey=nameField(f); const fileContent=f&&fContentKey?f[fContentKey]:null; const fileName=f&&fNameKey?f[fNameKey]:'24.txt'; if(typeof fileContent!=='string'||!fNameKey) throw Error('file_content_or_name_missing');
  const responseFacts={taskResponseReceived,fileResponseReceived,fileCount:Array.isArray(fileBody)?fileBody.length:0,task_idMatches:fileTaskIdMatches,fileKeys:f?Object.keys(f):[]};
  const fileCard=page.getByRole('button',{name:/24\.txt/}); if(await fileCard.count()!==1) throw Error('file_button_count'); await fileCard.click(); await page.waitForTimeout(400);
  const copy=page.getByRole('button',{name:'Копировать',exact:true}), down=page.getByRole('button',{name:'Скачать',exact:true});
  const copyBox=await bounds(copy), downBox=await bounds(down); const previewVisible=await page.getByText('Первые строки',{exact:false}).count()>0;
  await page.screenshot({path:path.join(OUT,`followup-02-rerun-${width}-files-preview.png`)});
  try{clipboardOriginal=await page.evaluate(()=>navigator.clipboard.readText());clipboardReadable=true;}catch{}
  let clipboardMatch=false;
  try {if(clipboardReadable&&typeof fileContent==='string'){await copy.click(); await page.waitForTimeout(350); clipboardMatch=(await page.evaluate(()=>navigator.clipboard.readText()))===fileContent;}} finally {if(clipboardReadable){try{await page.evaluate(v=>navigator.clipboard.writeText(v),clipboardOriginal);clipboardRestored=(await page.evaluate(()=>navigator.clipboard.readText()))===clipboardOriginal;}catch{clipboardRestored=false;}}}
  let downloadNameMatch=false,downloadMatch=false,downloadBytes=null,downloadHash=null;
  if(typeof fileContent==='string') {const dlWait=page.waitForEvent('download'); await down.click(); const dl=await dlWait; downloadNameMatch=dl.suggestedFilename()===fileName; tempDownload=path.join('/tmp',`yege-tc16-${width}-${Date.now()}`); await dl.saveAs(tempDownload); const bytes=await fs.readFile(tempDownload); downloadBytes=bytes.length;downloadHash=sha(bytes);downloadMatch=bytes.equals(Buffer.from(fileContent,'utf8'));await fs.unlink(tempDownload);tempDownload=null;}
  result.file={responseFacts,tabDiag,filename:fileName,contentBytes:Buffer.byteLength(fileContent,'utf8'),copyBox,downloadBox:downBox,previewVisible,clipboardReadable,clipboardMatch,clipboardRestored,downloadNameExpected:fileName,downloadNameActual:downloadNameMatch?fileName:'mismatch',downloadNameMatch,expectedBytes:Buffer.byteLength(fileContent,'utf8'),downloadBytes,expectedSha256:sha(Buffer.from(fileContent,'utf8')),downloadSha256:downloadHash,downloadMatch};
  await page.goto(ORIGIN+'/#/task/'+MISSING); await enableA11y(page,mobile); await page.waitForFunction(()=>document.body.innerText.includes('Повторить'),null,{timeout:15000}); await page.waitForTimeout(500);
  const before=missingCount; const retry=page.getByRole('button',{name:'Повторить',exact:true}); const retryBox=await bounds(retry); const missingText=await page.getByText('Задача не найдена или ещё не открыта.',{exact:true}).count()>0;
  await page.screenshot({path:path.join(OUT,`followup-02-rerun-${width}-missing-before.png`)}); const retryResp=page.waitForResponse(r=>{const u=new URL(r.url());return u.pathname.endsWith('/tasks_public')&&u.searchParams.get('slug')==='eq.'+MISSING;},{timeout:10000}); await retry.click(); await retryResp; await page.waitForTimeout(200); const after=missingCount; const remains=await page.getByText('Задача не найдена или ещё не открыта.',{exact:true}).count()>0; await page.screenshot({path:path.join(OUT,`followup-02-rerun-${width}-missing-after.png`)});
  result.missing={missingText,retryBox,requestsBefore:before,requestsAfter:after,retryDelta:after-before,remains};
  const boundsOk=[copyBox,downBox,retryBox].every(b=>b&&b.width>=44&&b.height>=44);
  result.pass=taskResponseReceived&&fileResponseReceived&&fileTaskIdMatches&&Array.isArray(fileBody)&&fileBody.length===1&&clipboardReadable&&clipboardMatch&&clipboardRestored&&downloadNameMatch&&downloadMatch&&missingText&&after-before>=1&&remains&&boundsOk;
 }catch(e){result.error={phase:'viewport',name:e.name,code:e.message.slice(0,140)}; try{diag={url:page.url(),tabs:await page.evaluate(()=>[...document.querySelectorAll('[role="tab"]')].map(e=>({name:e.getAttribute('aria-label')||e.innerText,selected:e.getAttribute('aria-selected')}))),buttons:(await page.getByRole('button').allTextContents()).map(s=>s.trim().split(/\s+/).slice(0,3).join(' ')).filter(s=>/24\.txt|Файлы|Повторить|Копировать|Скачать/.test(s)).slice(0,10),taskResponseReceived,fileResponseReceived,fileCount:Array.isArray(fileBody)?fileBody.length:0,task_idMatches:fileTaskIdMatches}; await page.screenshot({path:path.join(OUT,`followup-02-rerun-${width}-error.png`)});}catch{} result.diagnostics=diag;
 }finally{
  if(clipboardReadable){try{await page.evaluate(v=>navigator.clipboard.writeText(v),clipboardOriginal);clipboardRestored=(await page.evaluate(()=>navigator.clipboard.readText()))===clipboardOriginal;}catch{clipboardRestored=false;}}
  result.clipboardRestored=clipboardRestored; if(result.file)result.file.clipboardRestored=clipboardRestored; result.pass=Boolean(result.pass)&&clipboardRestored;
  if(tempDownload)await fs.unlink(tempDownload).catch(()=>{}); await ctx.close().catch(()=>{});
 }
 return result;
}
(async()=>{const browser=await chromium.launch({headless:true});const browserVersion=browser.version();const results=[];try{for(const [w,m] of [[1440,false],[360,true]])results.push(await runViewport(browser,w,m));}finally{await browser.close();}console.log(JSON.stringify({playwright:require('playwright/package.json').version,chromium:browserVersion,results})); if(results.length!==2||results.some(x=>!x.pass))process.exitCode=1;})().catch(e=>{console.log(JSON.stringify({phase:'runner',error:e.name,code:e.message.slice(0,120)}));process.exitCode=1});
