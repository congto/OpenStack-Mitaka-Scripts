# Hướng dẫn thực thi script cài đặt OpenStack Mitaka

## Tóm tắt về các ngữ cảnh sử dụng (use case) Neutron trong OpenStack 

- Neutron trong OpenStack cung cấp 02 use case chính là `Provider Network` và `Self Service Network.`
- Trong tài liệu này sẽ hướng dẫn dựng LAB và cấu hình đối với use case `Provider Network` sử dụng VLAN 

###  Đối với `Provider Network`

- Cung cấp một hoặc nhiều dải mạng external có sẵn cho máy ảo, dải mạng này được tạo bởi người quản trị.
- Trong use case này ko có cơ chế floating IP, không có router ảo.
- Provider Network có thể lựa chọn các kiểu chính như: FLAT, VLAN.
- Với Provider Network theo dạng FLAT: 
 - Các máy ảo ở các project, tenant khác nhau đều cùng một dải IP.
 - Muốn cấp nhiều dải IP khác nhau khi sử dụng FLAT thì cần có nhiều Interface cho các host vật lý của OpenStack.
- Với Provider Network theo dạng VLAN: 
 - Có thể tạo nhiều network thuộc các VLAN khác nhau, 
 - Các máy ảo sẽ được lựa chọn dải mạng ứng với VLAN được tạo ra. 
 - Các VLAN được tạo trong OpenStack dành cho máy ảo sẽ là các VLAN của hệ thống bên ngoài.


###  Đối với `Self Service Network`

- Ngoài dải mạng external tương tự như use case Provider network, mô hình mạng theo kiểu `Self-Service Network` cho phép người dùng tạo các dải mạng bên trong theo nhu cầu.
- Các máy ảo sẽ gắn trực tiếp vào dải IP private, dải mạng do người dùng tạo ra.
- Có cơ chế floating IP gắn vào máy ảo.
- Việc kết nối với máy ảo thông qua router ảo.
- Có thể tạo các dải IP private trùng nhau ở các project (tenant) khác nhau.


## Hướng dẫn thực thi script




