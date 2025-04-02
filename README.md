# Ứng dụng Quản lý Server JX1 Offline

## I. Giới thiệu

Ứng dụng Quản lý Server JX là công cụ hỗ trợ quản lý và điều khiển server game JX trên môi trường Linux. Đặc biệt dùng cho [Bộ cài đặt Võ Lâm Offline 1ClickVMFull](https://docs.google.com/document/d/1BUtlCyJdIg-Dc15EZLYU7dMAcGA4wzcZDMBrM3dRpcc/edit?usp=sharing)

Phần mềm cung cấp giao diện đồ họa trực quan giúp người dùng dễ dàng khởi động, dừng các dịch vụ cần thiết và quản lý server.

Tác giả: **Vinh-TTN**


## II. Các tính năng chính

1. Quản lý và giám sát trạng thái của các dịch vụ: PaySys, RelayServer, goddess_y, bishop_y, s3relay_y, jx_linux_y, MySQL, MSSQL
2. Khởi động và dừng dịch vụ với giao diện đồ họa
3. Lựa chọn IP server từ danh sách các card mạng
4. Sao lưu dữ liệu MySQL và MSSQL
5. Cập nhật phiên bản server từ GitHub
6. Quản lý tài khoản người chơi

## III. Cài đặt thủ công (nếu không sử dụng [Bộ cài đặt Võ Lâm Offline 1ClickVMFull](https://docs.google.com/document/d/1BUtlCyJdIg-Dc15EZLYU7dMAcGA4wzcZDMBrM3dRpcc/edit?usp=sharing))

1. Đảm bảo Python 3 và tkinter đã được cài đặt:
   ```
   apt-get install python3 python3-tk
   ```

2. Cấp quyền thực thi cho script:
   ```
   chmod +x app.py
   chmod +x jx.sh
   ```

## IV. Hướng dẫn sử dụng

### A. Khởi động ứng dụng (nếu không sử dụng [Bộ cài đặt Võ Lâm Offline 1ClickVMFull](https://docs.google.com/document/d/1BUtlCyJdIg-Dc15EZLYU7dMAcGA4wzcZDMBrM3dRpcc/edit?usp=sharing))

Dưới quyền **root**:
```
python3 app.py
```



### B. Chọn IP Server

1. Khi khởi động ứng dụng, hệ thống sẽ hiển thị danh sách các IP có sẵn trên server
2. Nếu chỉ có một IP, ứng dụng sẽ tự động chọn và lưu IP đó
3. Nếu có nhiều IP, bạn có thể chọn IP phù hợp từ dropdown menu, hệ thống sẽ tự động lưu lại

### C. Khởi động và dừng các dịch vụ

1. **Mở tất cả**: Khởi động tất cả các dịch vụ cần thiết cho server
2. **Tắt tất cả**: Dừng toàn bộ các dịch vụ đang chạy
3. **Các nút Mở/Tắt riêng lẻ**: Điều khiển từng dịch vụ một cách độc lập

### D. Quản lý tài khoản

1. Nhấn nút **Tài khoản** để mở giao diện quản lý người dùng
2. Tại đây bạn có thể:
   - a. Xem danh sách tài khoản
   - b. Thêm tài khoản mới
   - c. Xóa tài khoản người dùng
   - d. Xóa nhân vật

### E. Sao lưu dữ liệu

1. Sử dụng nút **Backup** để tạo bản sao lưu cho MySQL và MSSQL
2. Các file sao lưu được lưu tại thư mục `/home/database_backups`

### F. Cập nhật JX1 game server (Server Patch)

1. Nhấn nút **Up** để bắt đầu quá trình cập nhật
2. Xác nhận dừng server khi được hỏi bằng cách nhập `co`
3. Nhập địa chỉ GitHub repository theo định dạng: `username/repository[,branch]`
   - Ví dụ: 
     - a. `vinh-ttn/simcity` (sử dụng nhánh mặc định 'main')
     - b. `vinh-ttn/simcity,dev` (sử dụng nhánh 'dev')
     - c. `username/other-repo,custom-branch` (sử dụng repo khác với nhánh tùy chỉnh)

#### F.1. Cơ chế hoạt động của tính năng cập nhật server

- i. Hệ thống sẽ tải file .tar.gz từ GitHub theo đường dẫn: `https://github.com/username/repository/archive/refs/heads/branch.tar.gz`
- ii. File được giải nén vào thư mục tạm
- iii. Sau đó, hệ thống tìm và sao chép nội dung từ các thư mục `server1` và `gateway` (nếu có) vào thư mục server đã cấu hình

#### F.2. Xử lý đặc biệt cho repository `vinh-ttn/simcity`

Khi bạn chọn cập nhật từ repository `vinh-ttn/simcity`, hệ thống sẽ:

- i. **Sao lưu tự động**: 
  - Kiểm tra sự tồn tại của thư mục `server1/script/global/vinh/simcity`
  - Tạo file sao lưu dạng `simcity_backup_YYYY-MM-DD_HH-MM-SS.tar.gz` trong thư mục `server1/script/global/vinh/`
  - File sao lưu chứa toàn bộ nội dung của thư mục simcity hiện tại

- ii. **Xóa nội dung cũ**:
  - Sau khi sao lưu thành công, hệ thống sẽ xóa hoàn toàn thư mục `simcity` hiện tại
  - Đảm bảo không có file cũ can thiệp vào phiên bản mới

- iii. **Cài đặt phiên bản mới**:
  - Tải và giải nén repository từ GitHub
  - Cài đặt nội dung mới vào thư mục `server1/script/global/vinh/simcity`

Việc này đảm bảo bạn luôn có bản sao lưu của phiên bản hiện tại trước khi cập nhật, đồng thời đảm bảo cài đặt sạch sẽ không bị xung đột với các file cũ.

### G. Đổi thư mục server

1. Nhấn nút **Đổi server** để chọn thư mục server JX1 khác
2. Thư mục mặc định là `/home/jxser_8.1_vinh`

## V. Cấu trúc thư mục

1. `app.py`: File chính của ứng dụng
2. `jx.sh`: Script thực thi các lệnh quản lý server
3. `users.py`: Công cụ quản lý tài khoản người dùng
4. `serverconfig.php`: Script PHP hỗ trợ tạo cấu hình cho server
5. `gameconfigs/`: Thư mục chứa các file cấu hình mẫu

## VI. Xử lý sự cố

1. **Không hiển thị IP**: Kiểm tra quyền truy cập và cấu hình mạng
2. **Lỗi khởi động dịch vụ**: Kiểm tra logs trong thư mục tương ứng
3. **Lỗi khi cập nhật từ GitHub**: Kiểm tra kết nối mạng và địa chỉ repository

## VII. Thông tin thêm

1. Các cấu hình được lưu tại file `/root/.quanlyserver.json`
2. IP và MAC address được lựa chọn sẽ được lưu vào file cấu hình
3. Ứng dụng tự động giám sát trạng thái các dịch vụ mỗi 2 giây
