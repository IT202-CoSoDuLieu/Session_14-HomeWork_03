DROP DATABASE IF EXISTS RikkeiClinicDB;
CREATE DATABASE RikkeiClinicDB;
USE RikkeiClinicDB;

-- PHẦN 1: KHỞI TẠO CẤU TRÚC BẢNG 

-- 1. Bảng Bệnh nhân (Patients)
CREATE TABLE Patients (
    patient_id INT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    phone VARCHAR(15) UNIQUE NOT NULL,
    date_of_birth DATE
);

-- 2. Bảng Nhân sự / Bác sĩ (Employees)
CREATE TABLE Employees (
    employee_id INT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    position VARCHAR(50) NOT NULL,
    salary DECIMAL(18,2) NOT NULL
);

-- 3. Bảng Khoa (Departments)
CREATE TABLE Departments (
    dept_id INT PRIMARY KEY,
    dept_name VARCHAR(100) NOT NULL
);

-- 4. Bảng Giường bệnh (Beds)
CREATE TABLE Beds (
    bed_id INT PRIMARY KEY,
    dept_id INT NOT NULL,
    patient_id INT DEFAULT NULL, -- NULL nghĩa là giường trống
    FOREIGN KEY (dept_id) REFERENCES Departments(dept_id),
    FOREIGN KEY (patient_id) REFERENCES Patients(patient_id)
);

-- 5. Bảng Lịch khám (Appointments)
CREATE TABLE Appointments (
    appointment_id INT PRIMARY KEY,
    patient_id INT NOT NULL,
    doctor_id INT NOT NULL,
    appointment_date DATETIME NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'Pending', -- 'Pending', 'Completed', 'Cancelled'
    FOREIGN KEY (patient_id) REFERENCES Patients(patient_id),
    FOREIGN KEY (doctor_id) REFERENCES Employees(employee_id)
);

-- 6. Bảng Kho Vật tư Y tế (Inventory)
CREATE TABLE Inventory (
    item_id INT PRIMARY KEY,
    item_name VARCHAR(100) NOT NULL,
    stock_quantity INT NOT NULL DEFAULT 0
);

-- 7. Bảng Kho Thuốc (Medicines)
CREATE TABLE Medicines (
    medicine_id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    price DECIMAL(18,2) NOT NULL,
    stock INT NOT NULL DEFAULT 0
);

-- 8. Bảng Công nợ Bệnh nhân (Patient_Invoices)
CREATE TABLE Patient_Invoices (
    patient_id INT PRIMARY KEY,
    total_due DECIMAL(18,2) NOT NULL DEFAULT 0,
    last_updated DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (patient_id) REFERENCES Patients(patient_id)
);

-- 9. Bảng Sản phẩm (Products)
CREATE TABLE Products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    price DECIMAL(18,2) NOT NULL,
    stock INT NOT NULL DEFAULT 0
);

-- 10. Bảng Dịch vụ khám (Services) 
CREATE TABLE Services (
    service_id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    price DECIMAL(18,2) NOT NULL
);

-- 11. Bảng Ví điện tử (Wallets) 
CREATE TABLE Wallets (
    patient_id INT PRIMARY KEY,
    balance DECIMAL(18,2) NOT NULL DEFAULT 0,
    status VARCHAR(20) NOT NULL DEFAULT 'Active', -- 'Active', 'Inactive'
    FOREIGN KEY (patient_id) REFERENCES Patients(patient_id)
);

-- 12. Bảng Lịch sử sử dụng dịch vụ (Service_Usages) 
CREATE TABLE Service_Usages (
    usage_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    service_id INT NOT NULL,
    actual_price DECIMAL(18,2) DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (patient_id) REFERENCES Patients(patient_id),
    FOREIGN KEY (service_id) REFERENCES Services(service_id)
);

-- PHẦN 2: CHÈN DỮ LIỆU MẪU (TEST CASES)
-- Chèn Bệnh nhân
INSERT INTO Patients (patient_id, full_name, phone, date_of_birth) VALUES
(1, 'Nguyen Van An', '0901111222', '1990-05-15'),
(2, 'Tran Thi Binh', '0912222333', '1985-08-20'),
(3, 'Le Hoang Cuong', '0923333444', '2000-12-01');

-- Chèn Nhân sự 
INSERT INTO Employees (employee_id, full_name, position, salary) VALUES
(101, 'Dr. Hoang Minh', 'Doctor', 20000.00),
(102, 'Dr. Lan Anh', 'Doctor', 25000.00),
(103, 'Nurse Thu Ha', 'Nurse', 12000.00);

-- Chèn Khoa
INSERT INTO Departments (dept_id, dept_name) VALUES
(1, 'Khoa Ngoai'),
(2, 'Khoa Noi'),
(3, 'Khoa ICU');

-- Chèn Giường bệnh
INSERT INTO Beds (bed_id, dept_id, patient_id) VALUES
(101, 1, 1),    -- Bệnh nhân 1 đang nằm giường 101 Khoa Ngoại
(201, 2, NULL), -- Giường 201 Khoa Nội đang trống
(301, 3, 2);    -- Bệnh nhân 2 đang nằm ICU

-- Chèn Lịch khám 
INSERT INTO Appointments (appointment_id, patient_id, doctor_id, appointment_date, status) VALUES
(104, 1, 101, '2026-06-10 08:30:00', 'Pending'),
(105, 2, 102, '2026-05-01 09:00:00', 'Completed'),
(106, 3, 101, '2026-05-02 10:00:00', 'Cancelled');

-- Chèn Vật tư 
INSERT INTO Inventory (item_id, item_name, stock_quantity) VALUES
(10, 'Khau trang y te N95', 1000),
(11, 'Gang tay vo trung', 500),
(12, 'Dung dich sat khuan', 200);

-- Chèn Thuốc
INSERT INTO Medicines (medicine_id, name, price, stock) VALUES
(1, 'Amoxicillin 500mg', 15000, 100),  -- Tồn kho nhiều
(2, 'Panadol Extra', 5000, 5);         -- Tồn kho ít

-- Chèn Công nợ Bệnh nhân
INSERT INTO Patient_Invoices (patient_id, total_due) VALUES
(1, 1500000.00), -- Đã sửa: Nợ 1.5tr để test bài Giải phóng giường bệnh
(2, 0),
(3, 0);

-- Chèn Sản phẩm E-commerce 
INSERT INTO Products (name, price, stock) VALUES
('May do huyet ap Omron', 850000.00, 20),
('May do duong huyet', 450000.00, 15);

-- Chèn Dịch vụ
INSERT INTO Services (service_id, name, price) VALUES
(1, 'Sieu am o bung', 200000.00),
(2, 'Xet nghiem mau', 150000.00),
(3, 'Chup X-Quang', 250000.00);

-- Chèn Ví điện tử
INSERT INTO Wallets (patient_id, balance, status) VALUES
(1, 500000.00, 'Active'),    -- Test Case 1: Đủ tiền thanh toán
(2, 50000.00, 'Active'),     -- Test Case 3: Cháy ví (Chỉ có 50k, không đủ khám 200k)
(3, 1000000.00, 'Inactive'); -- Test Case 2: Nhiều tiền nhưng thẻ bị khóa

-- Xác định dữ liệu đầu vào 
-- IN : p_patient_id(INT) - mã bệnh nhân, p_medicine_id(INT) - mã thuốc cần cấp, p_quantity (INT)- Số lượng thuốc yêu cầu cấp phát
-- OUT: p_status_message (VARCHAR(255)): Trả về thông báo trạng thái kết quả hiển thị lên màn hình ứng dụng 
-- Đã cấp phát thành công" hoặc "Lỗi: Số lượng tồn kho không đủ").

-- Giải pháp và các bước thực hiệnSử dụng tính chất Atomicity của Transaction phối hợp kiểm tra logic nghiệp vụ trước khi cập nhật dữ liệu. 
-- Các bước thiết lập trong Procedure bao gồm:
-- Khai báo biến cục bộ: Để lưu trữ số lượng tồn kho thực tế (v_stock) và đơn giá thuốc (v_price).
-- Lấy thông tin thuốc: Truy vấn bảng Medicines lấy đơn giá và số lượng hàng tồn kho hiện tại của mã thuốc được yêu cầu.
-- Kiểm tra điều kiện tồn kho:
-- Nếu số lượng yêu cầu p_quantity > số lượng tồn kho thực tế v_stock, kích hoạt lệnh SIGNAL SQLSTATE hoặc chủ động hủy để rollback block, 
-- gán thông báo lỗi cho tham số OUT.
-- Thực thi Transaction:
-- START TRANSACTION: Bắt đầu phiên làm việc an toàn.
-- Thao tác 1 (Kho): Trừ số lượng tồn kho trong bảng Medicines.
-- Thao tác 2 (Công nợ): Tính toán số tiền tăng thêm (= Số lượng $\times$ Đơn giá) rồi cập nhật cộng dồn vào total_due của bệnh nhân trong bảng 
-- Patient_Invoices.
-- COMMIT: Xác nhận ghi dữ liệu thành công nếu không xảy ra lỗi phát sinh nào khác và trả ra thông báo thành công.

-- Code hoàn chỉnh
DELIMITER //

CREATE PROCEDURE Proc_DispenseMedicine(
    IN p_patient_id INT,
    IN p_medicine_id INT,
    IN p_quantity INT,
    OUT p_status_message VARCHAR(255)
)
BEGIN
    -- Khai báo các biến lưu trữ thông tin nội bộ
    DECLARE v_stock INT;
    DECLARE v_price DECIMAL(18,2);
    
    -- Xử lý lỗi hệ thống bất ngờ (nếu có lỗi SQL ngoài ý muốn phát sinh, tự động Rollback)
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_status_message = 'Lỗi: Giao dịch thất bại do sự cố hệ thống ngoài ý muốn.';
    END;

    -- Lấy số lượng tồn kho và đơn giá hiện tại của thuốc
    SELECT stock, price INTO v_stock, v_price 
    FROM Medicines 
    WHERE medicine_id = p_medicine_id;

    -- Kiểm tra logic nghiệp vụ: Tồn kho có đủ đáp ứng?
    IF v_stock IS NULL THEN
        SET p_status_message = 'Lỗi: Mã thuốc không tồn tại trong hệ thống.';
    ELSEIF p_quantity > v_stock THEN
        SET p_status_message = 'Lỗi: Số lượng tồn kho không đủ';
    ELSE
        -- Bắt đầu chuỗi giao dịch đồng bộ dữ liệu
        START TRANSACTION;

        -- 1. Thao tác tại Kho: Trừ số lượng cấp phát tương ứng
        UPDATE Medicines 
        SET stock = stock - p_quantity 
        WHERE medicine_id = p_medicine_id;

        -- 2. Thao tác tại Công nợ: Cộng dồn chi phí thuốc vào tổng nợ của bệnh nhân
        UPDATE Patient_Invoices 
        SET total_due = total_due + (p_quantity * v_price),
            last_updated = CURRENT_TIMESTAMP
        WHERE patient_id = p_patient_id;

        -- Xác nhận thành công và hoàn tất giao dịch
        COMMIT;
        SET p_status_message = 'Đã cấp phát thành công';
    END IF;

END //

DELIMITER ;

-- Kiểm thử
-- Gọi thủ tục
CALL Proc_DispenseMedicine(1, 2, 3, @msg);

-- Xem thông báo hiển thị trên màn hình ứng dụng
SELECT @msg AS 'Thông báo từ hệ thống';

-- 1. Kiểm kho thuốc: Tồn kho Panadol phải giảm từ 5 xuống còn 2
SELECT medicine_id, name, stock FROM Medicines WHERE medicine_id = 2;

-- 2. Kiểm công nợ: Nợ cũ 1,500,000 + (3 viên * 5,000) = 1,515,000.00
SELECT patient_id, total_due FROM Patient_Invoices WHERE patient_id = 1;

-- Gọi thủ tục với số lượng vượt mức
CALL Proc_DispenseMedicine(1, 2, 10, @msg);

-- Xem thông báo hiển thị trên màn hình ứng dụng
SELECT @msg AS 'Thông báo từ hệ thống';

-- Kiểm kho thuốc: Tồn kho phải giữ nguyên là 2, không bị âm kho thành -8
SELECT medicine_id, name, stock FROM Medicines WHERE medicine_id = 2;

-- Kiểm công nợ: Công nợ vẫn giữ nguyên mức 1,515,000.00 từ phiên trước
SELECT patient_id, total_due FROM Patient_Invoices WHERE patient_id = 1;