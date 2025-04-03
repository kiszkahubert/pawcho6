const http = require('http');
const fs = require('fs');
http.createServer((req,res)=>{
    try{
      res.writeHead(200, {'Content-Type':'text/html'});
      res.end(fs.readFileSync('index.html'));
      } catch(err){
        res.writeHead(500);
        res.end(err);
      }
}).listen(3000,'0.0.0.0');
