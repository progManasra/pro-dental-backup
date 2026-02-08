-- backend/test/seed.sql

INSERT INTO users(full_name,email,role,password_hash)
VALUES
('Admin','admin@prodental.local','ADMIN','$2b$10$B0k/czJSTdglPQ2nl4geS.3qIxezZ6RYRkpeHDAQSeNhoU2DR.Wfm'),
('Doctor 1','dr1@prodental.local','DOCTOR','$2b$10$B0k/czJSTdglPQ2nl4geS.3qIxezZ6RYRkpeHDAQSeNhoU2DR.Wfm'),
('Patient 1','p1@prodental.local','PATIENT','$2b$10$B0k/czJSTdglPQ2nl4geS.3qIxezZ6RYRkpeHDAQSeNhoU2DR.Wfm');

INSERT INTO doctors VALUES (2,'General');
INSERT INTO patients VALUES (3,'1990-01-01');

INSERT INTO doctor_weekly_shifts(doctor_id,weekday,start_time,end_time)
VALUES (2,4,'09:00','13:00');  -- weekday=4 (Thu) كمثال

INSERT INTO appointments(doctor_id,patient_id,start_at,status)
VALUES (2,3,'2026-01-29 09:30:00','BOOKED');
