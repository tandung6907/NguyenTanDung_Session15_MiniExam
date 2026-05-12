create database miniexam_ss15;
use miniexam_ss15;

-- I. Cấu trúc Database
-- Tạo Bảng
create table students(
	student_id 		varchar(5) 			primary key,
    full_name 		varchar(50) 		not null,
    total_debt 		decimal(10,2)  		default 0
);

create table subjects(
	subject_id 		varchar(5) 			primary key,
    subject_name 	varchar(50) 		not null,
    credits 		int,
    
    constraint chk_tx_credit
    check (credits > 0)
);

create table grades(
	student_id 		varchar(5),
    subject_id 		varchar(5),
    score 			decimal(4,2),
    
    primary key (student_id, subject_id),
    
    constraint fk_tx_student
    foreign key (student_id) references students(student_id),
    
    constraint fk_tx_subject
    foreign key (subject_id) references subjects(subject_id),
    
    constraint chk_tx_score
    check (score between 0 and 10)
);

create table grade_log(
	log_id 			int 				auto_increment primary key,
    student_id 		varchar(5),
    old_score 		decimal(4,2),
    new_score 		decimal(4,2),
    change_date 	datetime 			default current_timestamp
);

insert into students 
values
	('SV01', 'Nguyen Tan Dung', 16000000),
	('SV02', 'Le Van Hung', 12000000),
	('SV03', 'Vi Anh Dung', 14000000),
	('SV04', 'Hoang Tuan Long', 17000000),
	('SV05', 'Nguyen Minh Duc', 20000000);
    
insert into subjects 
values
	('MH01', 'C/C++', 4),
	('MH02', 'HTML/CSS', 6),
	('MH03', 'JS', 5),
	('MH04', 'SQL', 3),
	('MH05', 'Python', 5);
    
insert into grades 
values
	('SV01', 'MH01', 9),
	('SV02', 'MH02', 6),
	('SV03', 'MH03', 5),
	('SV04', 'MH04', 8.5),
	('SV05', 'MH05', 6);

-- II. Nội dung yêu cầu
-- PHẦN A – CƠ BẢN (40 điểm)
-- PHẦN B – KHÁ (30 điểm)
-- PHẦN C – GIỎI (30 điểm)
delimiter //

-- Câu 1 (Trigger - 20đ): Nhà trường yêu cầu điểm số (score) nhập vào hệ thống phải luôn hợp lệ (từ 0 đến 10). 
-- Hãy viết một Trigger có tên tg_check_score chạy trước khi thêm (BEFORE INSERT) dữ liệu vào bảng grades.
-- Nếu người dùng nhập score < 0 thì tự động gán về 0.
-- Nếu người dùng nhập score > 10 thì tự động gán về 10.
create trigger tg_check_score
before insert on grades
for each row
begin
	if new.score < 0 then
		set new.score = 0;
	elseif new.score > 10 then
		set new.score = 10;
	end if;
end //

-- Câu 3 (Trigger - 15đ): Để chống tiêu cực trong thi cử, mọi hành động sửa đổi điểm số cần được ghi lại.
--  Hãy viết Trigger tên tg_log_grade_update chạy sau khi cập nhật (AFTER UPDATE) trên bảng grades.
-- Yêu cầu: Khi điểm số thay đổi, 
-- hãy tự động chèn một dòng vào bảng grade_log với các thông tin: student_id, old_score (lấy từ OLD), new_score (lấy từ NEW), 
-- và change_date là thời gian hiện tại (NOW()).
create trigger tg_log_grade_update
after update on grades
for each row
begin
	if old.score <> new.score then
		insert into grade_log(student_id, old_score, new_score, change_date)
		values(old.student_id, old.score, new.score, now());
	end if;
end //

-- Câu 5 (Trigger nâng cao - 30đ): Viết Trigger tên tg_prevent_pass_update.
-- Quy tắc nghiệp vụ: Sinh viên đã qua môn (Điểm cũ >= 4.0) thì không được phép sửa điểm nữa để đảm bảo tính minh bạch.
-- Yêu cầu: Viết trigger BEFORE UPDATE trên bảng grades. Nếu điểm cũ (OLD.score) >= 4.0,
--  hãy hủy thao tác cập nhật bằng cách phát sinh lỗi (Sử dụng SIGNAL SQLSTATE với thông báo lỗi tùy ý)
create trigger tg_prevent_pass_update
before update on grades
for each row
begin
	if old.score >= 4.0 then
		signal sqlstate '45000'
		set message_text = 'Không thể sửa điểm sinh viên đã qua môn (Điểm >= 4.0)';
	end if;
end //

delimiter ;

-- Câu 2 (Transaction - 20đ): Viết một đoạn script sử dụng Transaction để thêm một sinh viên mới.
-- Yêu cầu đảm bảo tính trọn vẹn "All or Nothing" của dữ liệu:
-- Bắt đầu Transaction.
-- Thêm sinh viên mới vào bảng students: student_id = 'SV02', full_name = 'Ha Bich Ngoc'.
-- Cập nhật nợ học phí (total_debt) cho sinh viên này là 5,000,000.
-- Xác nhận (COMMIT) Transaction.
start transaction;
insert into students(student_id, full_name) values ('SV06', 'Ha Bich Ngoc');
update students set total_debt = 5000000 where student_id = 'SV06';
commit;

-- Câu 4 (Transaction & Procedure cơ bản - 15đ): Viết một Stored Procedure đơn giản tên sp_pay_tuition thực hiện việc đóng học phí cho sinh viên 'SV01' với số tiền 2,000,000.
-- Bắt đầu Transaction.
-- Trừ 2,000,000 trong cột total_debt của bảng students (student_id = 'SV01').
-- Kiểm tra logic: Nếu sau khi trừ, total_debt < 0, hãy ROLLBACK để hủy bỏ. Ngược lại, hãy COMMIT.
delimiter //

create procedure sp_pay_tuition()
begin
	declare current_debt decimal(10,2);
    
	start transaction;
    
	update students 
	set total_debt = total_debt - 2000000 
	where student_id = 'SV01';
    
	select 
		total_debt into current_debt 
	from students 
	where student_id = 'SV01';
    
	if current_debt < 0 then
		rollback;
	else
		commit;
	end if;
end //

delimiter ;