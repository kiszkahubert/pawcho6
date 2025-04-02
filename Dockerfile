# syntax=docker/dockerfile:1.4

FROM scratch AS s
ADD alpine.tar.gz /
WORKDIR /usr/app
ARG VERSION="1.0.0"
RUN echo '#!/bin/sh' > sk.sh && \
    echo 'hostname -i' >> sk.sh && \
    echo 'hostname' >> sk.sh && \
    echo "echo '$VERSION'" >> sk.sh && \
    chmod +x sk.sh

FROM nginx:alpine
WORKDIR /usr/share/nginx/html
RUN apk add nodejs npm curl openssh-client
COPY --from=s /usr/app/sk.sh .
RUN ./sk.sh > index.html
COPY <<"EOF" main.js
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
EOF
COPY <<"EOF" /etc/nginx/conf.d/default.conf
server{
  listen 80;
  server_name localhost;
  location / {
    proxy_pass http://localhost:3000;
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
  }
}
EOF
HEALTHCHECK --interval=10s --timeout=1s \
    CMD curl -f http://localhost:80/ || exit 1

COPY <<"EOF" /start.sh
#!/bin/sh
node /usr/share/nginx/html/main.js &
nginx -g "daemon off;"
EOF
RUN chmod +x /start.sh

EXPOSE 80
CMD ["/start.sh"]

