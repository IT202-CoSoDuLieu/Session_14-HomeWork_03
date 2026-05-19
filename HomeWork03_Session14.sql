-- =========================================================================
-- PHÂN TÍCH YÊU CẦU BÀI TOÁN
-- =========================================================================

-- 1. XÁC ĐỊNH DỮ LIỆU ĐẦU VÀO VÀ ĐẦU RA
/*
Dữ liệu đầu vào:
- p_patient_id INT:
  Mã bệnh nhân cần cấp phát thuốc.

- p_medicine_id INT:
  Mã thuốc cần cấp phát.

- p_quantity INT:
  Số lượng thuốc yêu cầu cấp phát.

Dữ liệu đầu ra:
- p_status_message VARCHAR(255):
  Thông báo trạng thái trả về cho màn hình ứng dụng.

  Ví dụ:
  + "Đã cấp phát thành công"
  + "Lỗi: Số lượng tồn kho không đủ"
  + "Lỗi: Mã thuốc không tồn tại"
*/

-- 2. ĐỀ XUẤT LOẠI THAM SỐ PHÙ HỢP
/*
Sử dụng:
- IN parameter:
  Dùng để nhận dữ liệu đầu vào từ người dùng gửi vào Procedure.

- OUT parameter:
  Dùng để trả kết quả xử lý hoặc thông báo trạng thái về ứng dụng.

Cụ thể:
IN  p_patient_id INT
IN  p_medicine_id INT
IN  p_quantity INT
OUT p_status_message VARCHAR(255)

Lý do lựa chọn:
- IN giúp Procedure nhận dữ liệu từ hệ thống cấp phát thuốc.
- OUT giúp trả thông báo trực tiếp cho giao diện người dùng.
- VARCHAR(255) phù hợp để hiển thị các thông báo nghiệp vụ.
*/

-- =========================================================================
-- GIẢI PHÁP ÁP DỤNG KIỂM SOÁT GIAO DỊCH (TRANSACTION CONTROL)
-- =========================================================================

/*
Mục tiêu:
Đảm bảo dữ liệu luôn chính xác và đồng bộ giữa:
1. Kho thuốc (Medicines)
2. Công nợ bệnh nhân (Patient_Invoices)

Áp dụng Transaction để đảm bảo tính Atomicity:
- Hoặc tất cả thao tác cùng thành công.
- Hoặc toàn bộ bị hủy (ROLLBACK) nếu xảy ra lỗi.

Các bước thực hiện:

Bước 1:
Bắt đầu Transaction bằng START TRANSACTION.

Bước 2:
Kiểm tra:
- Bệnh nhân có tồn tại không.
- Thuốc có tồn tại không.
- Số lượng nhập có hợp lệ không.
- Tồn kho có đủ không.

Bước 3:
Khóa dòng dữ liệu thuốc bằng FOR UPDATE
để tránh nhiều nhân viên cùng cấp phát gây âm kho.

Bước 4:
Nếu hợp lệ:
- Trừ số lượng thuốc trong kho.
- Cộng tiền thuốc vào công nợ bệnh nhân.

Bước 5:
Nếu tất cả thành công:
- COMMIT để lưu dữ liệu vĩnh viễn.

Bước 6:
Nếu có lỗi:
- ROLLBACK để hoàn tác toàn bộ giao dịch.
- Trả thông báo lỗi cho người dùng.
*/

-- =========================================================================
-- GIẢI THÍCH ÁP DỤNG ACID TRONG BÀI TOÁN
-- =========================================================================

/*
A - Atomicity (Tính nguyên tử)
- Nếu một thao tác thất bại thì toàn bộ giao dịch rollback.
- Không xảy ra trường hợp đã trừ kho nhưng chưa cộng công nợ.

C - Consistency (Tính nhất quán)
- Không cho phép cấp phát vượt quá tồn kho.
- Dữ liệu sau giao dịch luôn hợp lệ.

I - Isolation (Tính cô lập)
- Sử dụng SELECT ... FOR UPDATE để khóa dữ liệu.
- Tránh race condition khi nhiều người cùng thao tác.

D - Durability (Tính bền vững)
- Sau COMMIT, dữ liệu được lưu vĩnh viễn trong hệ thống.
*/

DROP DATABASE IF EXISTS RikkeiClinicDB;
CREATE DATABASE RikkeiClinicDB;
USE RikkeiClinicDB;

-- =========================================================================
-- PHẦN 1: KHỞI TẠO CẤU TRÚC BẢNG
-- =========================================================================

-- 1. Bảng Bệnh nhân
CREATE TABLE Patients (
    patient_id INT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    phone VARCHAR(15) UNIQUE NOT NULL,
    date_of_birth DATE
);

-- 2. Bảng Nhân sự / Bác sĩ
CREATE TABLE Employees (
    employee_id INT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    position VARCHAR(50) NOT NULL,
    salary DECIMAL(18,2) NOT NULL
);

-- 3. Bảng Khoa
CREATE TABLE Departments (
    dept_id INT PRIMARY KEY,
    dept_name VARCHAR(100) NOT NULL
);

-- 4. Bảng Giường bệnh
CREATE TABLE Beds (
    bed_id INT PRIMARY KEY,
    dept_id INT NOT NULL,
    patient_id INT DEFAULT NULL,
    FOREIGN KEY (dept_id) REFERENCES Departments(dept_id),
    FOREIGN KEY (patient_id) REFERENCES Patients(patient_id)
);

-- 5. Bảng Lịch khám
CREATE TABLE Appointments (
    appointment_id INT PRIMARY KEY,
    patient_id INT NOT NULL,
    doctor_id INT NOT NULL,
    appointment_date DATETIME NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'Pending',
    FOREIGN KEY (patient_id) REFERENCES Patients(patient_id),
    FOREIGN KEY (doctor_id) REFERENCES Employees(employee_id)
);

-- 6. Bảng Kho vật tư y tế
CREATE TABLE Inventory (
    item_id INT PRIMARY KEY,
    item_name VARCHAR(100) NOT NULL,
    stock_quantity INT NOT NULL DEFAULT 0
);

-- 7. Bảng Kho thuốc
CREATE TABLE Medicines (
    medicine_id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    price DECIMAL(18,2) NOT NULL,
    stock INT NOT NULL DEFAULT 0
);

-- 8. Bảng Công nợ bệnh nhân
CREATE TABLE Patient_Invoices (
    patient_id INT PRIMARY KEY,
    total_due DECIMAL(18,2) NOT NULL DEFAULT 0,
    last_updated DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (patient_id) REFERENCES Patients(patient_id)
);

-- 9. Bảng Sản phẩm
CREATE TABLE Products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    price DECIMAL(18,2) NOT NULL,
    stock INT NOT NULL DEFAULT 0
);

-- 10. Bảng Dịch vụ
CREATE TABLE Services (
    service_id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    price DECIMAL(18,2) NOT NULL
);

-- 11. Bảng Ví điện tử
CREATE TABLE Wallets (
    patient_id INT PRIMARY KEY,
    balance DECIMAL(18,2) NOT NULL DEFAULT 0,
    status VARCHAR(20) NOT NULL DEFAULT 'Active',
    FOREIGN KEY (patient_id) REFERENCES Patients(patient_id)
);

-- 12. Bảng Lịch sử sử dụng dịch vụ
CREATE TABLE Service_Usages (
    usage_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    service_id INT NOT NULL,
    actual_price DECIMAL(18,2) DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (patient_id) REFERENCES Patients(patient_id),
    FOREIGN KEY (service_id) REFERENCES Services(service_id)
);

-- =========================================================================
-- PHẦN 2: CHÈN DỮ LIỆU MẪU
-- =========================================================================

INSERT INTO Patients VALUES
(1, 'Nguyen Van An', '0901111222', '1990-05-15'),
(2, 'Tran Thi Binh', '0912222333', '1985-08-20'),
(3, 'Le Hoang Cuong', '0923333444', '2000-12-01');

INSERT INTO Employees VALUES
(101, 'Dr. Hoang Minh', 'Doctor', 20000.00),
(102, 'Dr. Lan Anh', 'Doctor', 25000.00),
(103, 'Nurse Thu Ha', 'Nurse', 12000.00);

INSERT INTO Departments VALUES
(1, 'Khoa Ngoai'),
(2, 'Khoa Noi'),
(3, 'Khoa ICU');

INSERT INTO Beds VALUES
(101, 1, 1),
(201, 2, NULL),
(301, 3, 2);

INSERT INTO Appointments VALUES
(104, 1, 101, '2026-06-10 08:30:00', 'Pending'),
(105, 2, 102, '2026-05-01 09:00:00', 'Completed'),
(106, 3, 101, '2026-05-02 10:00:00', 'Cancelled');

INSERT INTO Inventory VALUES
(10, 'Khau trang y te N95', 1000),
(11, 'Gang tay vo trung', 500),
(12, 'Dung dich sat khuan', 200);

INSERT INTO Medicines VALUES
(1, 'Amoxicillin 500mg', 15000, 100),
(2, 'Panadol Extra', 5000, 5);

INSERT INTO Patient_Invoices VALUES
(1, 1500000.00, CURRENT_TIMESTAMP),
(2, 0, CURRENT_TIMESTAMP),
(3, 0, CURRENT_TIMESTAMP);

INSERT INTO Products(name, price, stock) VALUES
('May do huyet ap Omron', 850000.00, 20),
('May do duong huyet', 450000.00, 15);

INSERT INTO Services VALUES
(1, 'Sieu am o bung', 200000.00),
(2, 'Xet nghiem mau', 150000.00),
(3, 'Chup X-Quang', 250000.00);

INSERT INTO Wallets VALUES
(1, 500000.00, 'Active'),
(2, 50000.00, 'Active'),
(3, 1000000.00, 'Inactive');

-- =========================================================================
-- PHẦN 3: GIẢI THÍCH KIỂM SOÁT GIAO DỊCH (ACID)
-- =========================================================================

-- =========================================================================
-- PHẦN 4: STORED PROCEDURE KIỂM SOÁT GIAO DỊCH
-- =========================================================================

DELIMITER //

DROP PROCEDURE IF EXISTS Proc_DispenseMedicine //

CREATE PROCEDURE Proc_DispenseMedicine(
    IN p_patient_id INT,
    IN p_medicine_id INT,
    IN p_quantity INT,
    OUT p_status_message VARCHAR(255)
)
BEGIN

    -- =========================================================
    -- KHAI BÁO BIẾN
    -- =========================================================

    DECLARE v_stock INT;
    DECLARE v_price DECIMAL(18,2);

    DECLARE v_patient_exists INT DEFAULT 0;
    DECLARE v_medicine_exists INT DEFAULT 0;

    -- =========================================================
    -- XỬ LÝ NGOẠI LỆ HỆ THỐNG
    -- =========================================================

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_status_message =
        'Lỗi: Giao dịch thất bại do sự cố hệ thống.';
    END;

    -- =========================================================
    -- BẮT ĐẦU TRANSACTION
    -- =========================================================

    START TRANSACTION;

    -- =========================================================
    -- KIỂM TRA BỆNH NHÂN
    -- =========================================================

    SELECT COUNT(*)
    INTO v_patient_exists
    FROM Patients
    WHERE patient_id = p_patient_id;

    IF v_patient_exists = 0 THEN

        ROLLBACK;

        SET p_status_message =
        'Lỗi: Mã bệnh nhân không tồn tại.';

    ELSE

        -- =====================================================
        -- KIỂM TRA THUỐC
        -- =====================================================

        SELECT COUNT(*)
        INTO v_medicine_exists
        FROM Medicines
        WHERE medicine_id = p_medicine_id;

        IF v_medicine_exists = 0 THEN

            ROLLBACK;

            SET p_status_message =
            'Lỗi: Mã thuốc không tồn tại.';

        ELSEIF p_quantity <= 0 THEN

            ROLLBACK;

            SET p_status_message =
            'Lỗi: Số lượng cấp phát phải lớn hơn 0.';

        ELSE

            -- =================================================
            -- KHÓA DỮ LIỆU THUỐC TRÁNH RACE CONDITION
            -- =================================================

            SELECT stock, price
            INTO v_stock, v_price
            FROM Medicines
            WHERE medicine_id = p_medicine_id
            FOR UPDATE;

            -- =============================================
            -- KIỂM TRA TỒN KHO
            -- =============================================

            IF p_quantity > v_stock THEN

                ROLLBACK;

                SET p_status_message =
                'Lỗi: Số lượng tồn kho không đủ';

            ELSE

                -- =========================================
                -- THAO TÁC 1: TRỪ KHO
                -- =========================================

                UPDATE Medicines
                SET stock = stock - p_quantity
                WHERE medicine_id = p_medicine_id;

                -- =========================================
                -- THAO TÁC 2: CỘNG CÔNG NỢ
                -- =========================================

                INSERT INTO Patient_Invoices(
                    patient_id,
                    total_due,
                    last_updated
                )
                VALUES(
                    p_patient_id,
                    (p_quantity * v_price),
                    CURRENT_TIMESTAMP
                )

                ON DUPLICATE KEY UPDATE
                    total_due = total_due + (p_quantity * v_price),
                    last_updated = CURRENT_TIMESTAMP;

                -- =========================================
                -- XÁC NHẬN THÀNH CÔNG
                -- =========================================

                COMMIT;

                SET p_status_message =
                'Đã cấp phát thành công';

            END IF;

        END IF;

    END IF;

END //

DELIMITER ;

-- =========================================================================
-- PHẦN 5: KIỂM THỬ HỆ THỐNG
-- =========================================================================

-- Reset dữ liệu test
UPDATE Medicines
SET stock = 5
WHERE medicine_id = 2;

UPDATE Patient_Invoices
SET total_due = 1500000.00
WHERE patient_id = 1;

-- -------------------------------------------------------------------------
-- TEST CASE 1: CẤP PHÁT HỢP LỆ
-- -------------------------------------------------------------------------

SET @msg1 = '';

CALL Proc_DispenseMedicine(1, 2, 3, @msg1);

SELECT @msg1 AS 'Thông báo hệ thống';

-- Kiểm tra tồn kho
SELECT
    medicine_id,
    name,
    stock AS 'Tồn kho sau giao dịch'
FROM Medicines
WHERE medicine_id = 2;

-- Kiểm tra công nợ
SELECT
    patient_id,
    total_due AS 'Tổng công nợ sau giao dịch'
FROM Patient_Invoices
WHERE patient_id = 1;

-- -------------------------------------------------------------------------
-- TEST CASE 2: CẤP PHÁT VƯỢT QUÁ TỒN KHO
-- -------------------------------------------------------------------------

SET @msg2 = '';

CALL Proc_DispenseMedicine(1, 2, 10, @msg2);

SELECT @msg2 AS 'Thông báo hệ thống';

-- Kiểm tra tồn kho
SELECT
    medicine_id,
    name,
    stock AS 'Tồn kho sau rollback'
FROM Medicines
WHERE medicine_id = 2;

-- Kiểm tra công nợ
SELECT
    patient_id,
    total_due AS 'Tổng công nợ sau rollback'
FROM Patient_Invoices
WHERE patient_id = 1;