const fs=require('fs');
const lines=fs.readFileSync('bookstore_app/lib/screens/review_list_page.dart','utf8').split(/\r?\n/);
const out=[];
let i=0;
while(i<lines.length){
  const line=lines[i];
  if(line.includes('final List<Tab> _tabs = const [')){
    out.push('  final List<Tab> _tabs = const [');
    out.push("    Tab(text: 'Chưa đánh giá'),");
    out.push("    Tab(text: 'Đã đánh giá'),");
    out.push("    Tab(text: 'Đánh giá người bán'),");
    while(i<lines.length && !lines[i].trim().endsWith('];')){
      i++;
    }
    if(i<lines.length){
      out.push('  ];');
    }
    i++;
    continue;
  }
  out.push(line);
  i++;
}
const start=out.findIndex(l=>l.includes('final List<Tab> _tabs = const ['));
console.log(out.slice(start, start+6).join('\n'));
