FROM nginx:1.27-alpine

LABEL version="1.0.0"
LABEL description="Frontend image: Nginx serving static assets baked in at build time"

# Static frontend assets
COPY app/public/index.html /usr/share/nginx/html/index.html
COPY app/public/style.css  /usr/share/nginx/html/style.css
COPY app/public/app.js     /usr/share/nginx/html/app.js

# Nginx site config
COPY nginx/default.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
