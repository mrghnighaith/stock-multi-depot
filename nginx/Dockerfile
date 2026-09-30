FROM nginx:1.27-alpine

LABEL version="1.0.0"
LABEL description="NODE - frontend image (Nginx + static assets baked in)"

# Build this from the repo ROOT, not from inside nginx/:
#   docker build -f nginx/Dockerfile -t node-stock-frontend:1.0.0 .
COPY app/public/index.html /usr/share/nginx/html/index.html
COPY app/public/style.css /usr/share/nginx/html/style.css
COPY app/public/app.js /usr/share/nginx/html/app.js

COPY nginx/default.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
