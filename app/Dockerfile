# Dùng Nginx Alpine cực nhẹ (~15MB) và bảo mật
FROM nginx:1.26-alpine

# Xóa cấu hình mặc định và thêm cấu hình riêng của chúng ta (chạy port 8080)
RUN rm -f /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy toàn bộ file HTML, CSS, JS của Dashboard vào Nginx
COPY index.html style.css script.js /usr/share/nginx/html/

# Cấu hình phân quyền để Nginx có thể chạy dưới quyền Non-Root user (UID 101)
RUN touch /var/run/nginx.pid && \
    chown -R nginx:nginx /var/run/nginx.pid /var/cache/nginx /var/log/nginx /usr/share/nginx/html

# Chuyển sang non-root user
USER nginx

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
