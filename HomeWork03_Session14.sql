DROP DATABASE IF EXISTS RikkeiClinicDB;
CREATE DATABASE RikkeiClinicDB;
USE RikkeiClinicDB;

-- Bảng Bệnh nhân
CREATE TABLE Patients (
    patient_id INT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    phone VARCHAR(15) UNIQUE NOT NULL,
    date_of_birth DATE
);

-- Bảng Nhân viên / Bác sĩ
CREATE TABLE Employees (
    employee_id INT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    position VARCHAR(50) NOT NULL,
    salary DECIMAL(18,2) NOT NULL
);

-- Bảng Khoa
CREATE TABLE Departments (
    dept_id INT PRIMARY KEY,
    dept_name VARCHAR(100) NOT NULL
);

-- Bảng Giường bệnh
CREATE TABLE Beds (
    bed_id INT PRIMARY KEY,
    dept_id INT NOT NULL,
    patient_id INT DEFAULT NULL,

    FOREIGN KEY (dept_id)
        REFERENCES Departments(dept_id),

    FOREIGN KEY (patient_id)
        REFERENCES Patients(patient_id)
);

-- Bảng Lịch khám
CREATE TABLE Appointments (
    appointment_id INT PRIMARY KEY,
    patient_id INT NOT NULL,
    doctor_id INT NOT NULL,
    appointment_date DATETIME NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'Pending',

    FOREIGN KEY (patient_id)
        REFERENCES Patients(patient_id),

    FOREIGN KEY (doctor_id)
        REFERENCES Employees(employee_id)
);

-- Bảng Kho vật tư
CREATE TABLE Inventory (
    item_id INT PRIMARY KEY,
    item_name VARCHAR(100) NOT NULL,
    stock_quantity INT NOT NULL DEFAULT 0
);

-- Bảng Thuốc
CREATE TABLE Medicines (
    medicine_id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    price DECIMAL(18,2) NOT NULL,
    stock INT NOT NULL DEFAULT 0
);

-- Bảng Công nợ bệnh nhân
CREATE TABLE Patient_Invoices (
    patient_id INT PRIMARY KEY,
    total_due DECIMAL(18,2) NOT NULL DEFAULT 0,
    last_updated DATETIME DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (patient_id)
        REFERENCES Patients(patient_id)
);

-- Bảng Sản phẩm
CREATE TABLE Products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    price DECIMAL(18,2) NOT NULL,
    stock INT NOT NULL DEFAULT 0
);

-- Bảng Dịch vụ
CREATE TABLE Services (
    service_id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    price DECIMAL(18,2) NOT NULL
);

-- Bảng Ví điện tử
CREATE TABLE Wallets (
    patient_id INT PRIMARY KEY,
    balance DECIMAL(18,2) NOT NULL DEFAULT 0,
    status VARCHAR(20) NOT NULL DEFAULT 'Active',

    FOREIGN KEY (patient_id)
        REFERENCES Patients(patient_id)
);

-- Bảng Lịch sử sử dụng dịch vụ
CREATE TABLE Service_Usages (
    usage_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    service_id INT NOT NULL,
    actual_price DECIMAL(18,2) DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (patient_id)
        REFERENCES Patients(patient_id),

    FOREIGN KEY (service_id)
        REFERENCES Services(service_id)
);

INSERT INTO Patients VALUES
(1, 'Nguyen Van An', '0901111222', '1990-05-15'),
(2, 'Tran Thi Binh', '0912222333', '1985-08-20'),
(3, 'Le Hoang Cuong', '0923333444', '2000-12-01');

INSERT INTO Employees VALUES
(101, 'Dr. Hoang Minh', 'Doctor', 20000),
(102, 'Dr. Lan Anh', 'Doctor', 25000),
(103, 'Nurse Thu Ha', 'Nurse', 12000);

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
(1, 1500000, CURRENT_TIMESTAMP),
(2, 0, CURRENT_TIMESTAMP),
(3, 0, CURRENT_TIMESTAMP);

INSERT INTO Products(name, price, stock) VALUES
('May do huyet ap Omron', 850000, 20),
('May do duong huyet', 450000, 15);

INSERT INTO Services VALUES
(1, 'Sieu am o bung', 200000),
(2, 'Xet nghiem mau', 150000),
(3, 'Chup X-Quang', 250000);

INSERT INTO Wallets VALUES
(1, 500000, 'Active'),
(2, 50000, 'Active'),
(3, 1000000, 'Inactive');

/*

Dữ liệu đầu vào:
- p_patient_id INT
- p_medicine_id INT
- p_quantity INT

Dữ liệu đầu ra:
- p_status_message VARCHAR(255)

Procedure sử dụng:
- IN parameter để nhận dữ liệu đầu vào.
- OUT parameter để trả trạng thái xử lý.

Giải pháp áp dụng:
- Kiểm tra dữ liệu trước khi cập nhật.
- Sử dụng TRANSACTION để đảm bảo dữ liệu đồng bộ.
- Dùng COMMIT khi thành công.
- Dùng ROLLBACK nếu có lỗi.
- Dùng FOR UPDATE để khóa dữ liệu tránh race condition.

Áp dụng ACID:
- Atomicity:
  Không xảy ra trường hợp đã trừ kho nhưng chưa cộng công nợ.

- Consistency:
  Không cho phép cấp phát vượt quá tồn kho.

- Isolation:
  FOR UPDATE giúp tránh nhiều người cùng sửa dữ liệu.

- Durability:
  Sau COMMIT dữ liệu được lưu vĩnh viễn.

*/

DROP PROCEDURE IF EXISTS Proc_DispenseMedicine;

DELIMITER //

CREATE PROCEDURE Proc_DispenseMedicine(
    IN p_patient_id INT,
    IN p_medicine_id INT,
    IN p_quantity INT,
    OUT p_status_message VARCHAR(255)
)

proc_main: BEGIN

    DECLARE v_stock INT;
    DECLARE v_price DECIMAL(18,2);

    DECLARE v_patient_exists INT;
    DECLARE v_medicine_exists INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN

        ROLLBACK;

        SET p_status_message =
        'Lỗi hệ thống: Giao dịch đã được hoàn tác.';

    END;

    IF p_quantity <= 0 THEN

        SET p_status_message =
        'Lỗi: Số lượng cấp phát phải lớn hơn 0.';

        LEAVE proc_main;

    END IF;

    START TRANSACTION;

    SELECT COUNT(*)
    INTO v_patient_exists
    FROM Patients
    WHERE patient_id = p_patient_id;

    IF v_patient_exists = 0 THEN

        ROLLBACK;

        SET p_status_message =
        'Lỗi: Không tìm thấy bệnh nhân.';

        LEAVE proc_main;

    END IF;

    SELECT COUNT(*)
    INTO v_medicine_exists
    FROM Medicines
    WHERE medicine_id = p_medicine_id;

    IF v_medicine_exists = 0 THEN

        ROLLBACK;

        SET p_status_message =
        'Lỗi: Không tìm thấy thuốc.';

        LEAVE proc_main;

    END IF;

    SELECT stock, price
    INTO v_stock, v_price
    FROM Medicines
    WHERE medicine_id = p_medicine_id
    FOR UPDATE;

    IF p_quantity > v_stock THEN

        ROLLBACK;

        SET p_status_message =
        'Lỗi: Số lượng tồn kho không đủ.';

        LEAVE proc_main;

    END IF;

    UPDATE Medicines
    SET stock = stock - p_quantity
    WHERE medicine_id = p_medicine_id;

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

    COMMIT;

    SET p_status_message =
    'Đã cấp phát thuốc thành công.';

END //

DELIMITER ;

CALL Proc_DispenseMedicine(1, 2, 3, @msg);

SELECT @msg AS 'Ket qua';

SELECT * FROM Medicines
WHERE medicine_id = 2;

SELECT * FROM Patient_Invoices
WHERE patient_id = 1;

CALL Proc_DispenseMedicine(1, 2, 10, @msg);

SELECT @msg AS 'Ket qua';

SELECT * FROM Medicines
WHERE medicine_id = 2;

CALL Proc_DispenseMedicine(1, 999, 1, @msg);

SELECT @msg AS 'Ket qua';

CALL Proc_DispenseMedicine(999, 1, 1, @msg);

SELECT @msg AS 'Ket qua';

CALL Proc_DispenseMedicine(1, 1, -5, @msg);

SELECT @msg AS 'Ket qua';