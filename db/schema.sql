CREATE DATABASE IF NOT EXISTS prodental;
USE prodental;

CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  full_name VARCHAR(100),
  email VARCHAR(100) UNIQUE,
  role ENUM('ADMIN','DOCTOR','PATIENT'),
  password_hash VARCHAR(255)
);

CREATE TABLE doctors (
  user_id INT PRIMARY KEY,
  specialization VARCHAR(100),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE patients (
  user_id INT PRIMARY KEY,
  dob DATE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE doctor_weekly_shifts (
  id INT AUTO_INCREMENT PRIMARY KEY,
  doctor_id INT,
  weekday INT,
  start_time TIME,
  end_time TIME,
  FOREIGN KEY (doctor_id) REFERENCES doctors(user_id)
);

CREATE TABLE doctor_day_overrides (
  id INT AUTO_INCREMENT PRIMARY KEY,
  doctor_id INT,
  day_date DATE,
  is_off BOOLEAN,
  start_time TIME,
  end_time TIME
);

CREATE TABLE appointments (
  id INT AUTO_INCREMENT PRIMARY KEY,
  doctor_id INT,
  patient_id INT,
  start_at DATETIME,
  status ENUM('BOOKED','DONE','CANCELLED'),
  FOREIGN KEY (doctor_id) REFERENCES doctors(user_id),
  FOREIGN KEY (patient_id) REFERENCES patients(user_id)
);
