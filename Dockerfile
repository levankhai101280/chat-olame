# Sử dụng image Flutter chính thức với stable channel
FROM cirrusci/flutter:stable

# Thư mục làm việc trong container
WORKDIR /app

# Copy toàn bộ source code vào container
COPY . .

# Build Flutter Web
RUN flutter build web

# Cài đặt Python để serve file tĩnh (nếu bạn không có server tĩnh riêng)
RUN apt-get update && apt-get install -y python3

# Lệnh chạy khi container start: serve thư mục build/web bằng Python server ở port 5000
CMD ["python3", "-m", "http.server", "5000", "--directory", "build/web"]
