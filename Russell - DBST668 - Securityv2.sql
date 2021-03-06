SET ECHO ON;
SET SERVEROUTPUT ON;
set sqlformat ansiconsole;

/*Connect to Instructor DBA*/
connect InstructorDBA/brr1wik7;
show user;

/* Drop users, roles, policies, and other objects you create*/
DROP ROLE student_role;
DROP ROLE instructor_role;
DROP ROLE admin_role;

BEGIN
DBMS_RLS.DROP_POLICY(
    object_schema => 'InstructorDBA',
    object_name   => 'Admin_List',
    policy_name   => 'Hide_Admin_Info'
);
END;
/

CONNECT lbacsys/brr1wik7 
show user;

BEGIN
    SA_SYSDBA.DROP_POLICY(
    policy_name => 'Sched_OLS_POL'
    );
END;
/
connect InstructorDBA/brr1wik7;
show user;

/*Instructor account drop*/
BEGIN
  FOR x IN (SELECT User_Name FROM Instr_List)
  LOOP
    EXECUTE IMMEDIATE 'DROP USER '||x.User_Name;
  END LOOP;
/*Admin account drop*/
  FOR x IN (SELECT User_Name FROM Admin_List)
  LOOP
    EXECUTE IMMEDIATE 'DROP USER '||x.User_Name;
  END LOOP;
/*Student account drop*/
  FOR x IN (SELECT User_Name FROM Student_List)
  LOOP
    EXECUTE IMMEDIATE 'DROP USER '||x.User_Name;
  END LOOP;
END;
/

ALTER TABLE Admin_List DROP COLUMN User_Name;
ALTER TABLE Instr_List DROP COLUMN User_Name;
ALTER TABLE Student_List DROP COLUMN User_Name;


/*Username Procedure - Create usernames for every user*/
ALTER TABLE Admin_List ADD User_Name VARCHAR2(45);
ALTER TABLE Instr_List ADD User_Name VARCHAR2(45);
ALTER TABLE Student_List ADD User_Name VARCHAR2(45);

UPDATE Admin_List a SET User_Name =
    (SELECT CONCAT(UPPER(CONCAT(SUBSTR(Admin_FName,1,1),Admin_LName)), Admin_Num) 
        FROM Admin_List b WHERE a.Admin_Num = b.Admin_Num); 

UPDATE Instr_List a SET User_Name =
    (SELECT CONCAT(UPPER(CONCAT(SUBSTR(Instr_FName,1,1),Instr_LName)), Instr_Num) 
        FROM Instr_List b WHERE a.Instr_Num = b.Instr_Num); 

UPDATE Student_List a SET User_Name =
    (SELECT CONCAT(UPPER(CONCAT(SUBSTR(Student_FName,1,1),Student_LName)), Student_Num) 
        FROM Student_List b WHERE a.Student_Num = b.Student_Num);         


/*Password Procedure - Create Instructor user accounts*/
DECLARE
s_num INTEGER;
begin
s_num :=0;
  for x in (SELECT User_Name FROM Instr_List)
  loop
    execute immediate 'CREATE USER '||x.User_Name||' IDENTIFIED BY TheSecPass'||s_num;
    s_num := s_num +1;
  end loop;
/*Create Admin user accounts*/
s_num :=0;
  for x in (SELECT User_Name FROM Admin_List)
  loop
    execute immediate 'CREATE USER '||x.User_Name||' IDENTIFIED BY TheSecPass'||s_num;
    s_num := s_num +1;
  end loop;
/*Create Student user accounts*/
s_num :=0;
  for x in (SELECT User_Name FROM Student_List)
  loop
    execute immediate 'CREATE USER '||x.User_Name||' IDENTIFIED BY TheSecPass'||s_num;
    s_num := s_num +1;
  end loop;
/*Connection Prodcedure - grant create session*/
/*Instructor account*/
for x in (SELECT User_Name FROM Instr_List)
  loop
    execute immediate 'GRANT CREATE SESSION TO '||x.User_Name;
  end loop;
/*Admin account*/
  for x in (SELECT User_Name FROM Admin_List)
  loop
    execute immediate 'GRANT CREATE SESSION TO '||x.User_Name;
  end loop;
/*Student account*/
  for x in (SELECT User_Name FROM Student_List)
  loop
    execute immediate 'GRANT CREATE SESSION TO '||x.User_Name;
  end loop;
end;
/
/*Role Assignment Procedure*/
/*Create roles*/
CREATE ROLE admin_role;
CREATE ROLE instructor_role;
CREATE ROLE student_role;
/*Assign roles*/
begin
  for x in (SELECT User_Name FROM Admin_List)
  loop
    execute immediate 'GRANT admin_role TO '||x.User_Name;
  end loop;
  for x in (SELECT User_Name FROM Instr_List)
  loop
    execute immediate 'GRANT instructor_role TO '||x.User_Name;
  end loop;
  for x in (SELECT User_Name FROM Student_List)
  loop
    execute immediate 'GRANT student_role TO '||x.User_Name;
  end loop;
end;
/
/*Account Modify Procedure - Admins have full rights to the instructor and student tables.*/
GRANT SELECT, INSERT, DELETE, UPDATE ON Instr_List TO admin_role;
GRANT SELECT, INSERT, DELETE, UPDATE ON Student_List TO admin_role;

/*Test Account Modify Procedure*/
/*Test admin access*/
CONNECT bevans1/TheSecPass0;
show user;
SAVEPOINT Admin_Account_Modify_Procedure;
SELECT * FROM InstructorDBA.Instr_List;
SELECT * FROM InstructorDBA.Student_List;
UPDATE InstructorDBA.Instr_List SET Instr_LName = 'test';
UPDATE InstructorDBA.Student_List SET Student_LName = 'test';
INSERT INTO InstructorDBA.Student_List  (Student_Num,           Student_Address,     Student_PhoneNum, Student_LName, Student_FName, Student_ZipCode)
    VALUES              (999,'Dorm 11','222-333-3444',         'Pines',    'Matt',      '31005');
INSERT INTO InstructorDBA.Instr_List  (Instr_Num,           Instr_Address,     Instr_PhoneNum, Section_Num, Instr_LName, Instr_FName, Instr_ZipCode)
    VALUES              (888,'101 Apple Street','111-222-3434', '1',         'Roberts',   'John',      '31003');             
SELECT * FROM InstructorDBA.Instr_List;
SELECT * FROM InstructorDBA.Student_List;
DELETE FROM InstructorDBA.Instr_List;
DELETE FROM InstructorDBA.Student_List;
ROLLBACK TO Admin_Account_Modify_Procedure;
/*Test student access*/
CONNECT sgilbert1/TheSecPass0;
show user;
SELECT * FROM InstructorDBA.Instr_List;
SELECT * FROM InstructorDBA.Student_List;
/*Test instructor access*/
CONNECT mlopez3/TheSecPass2;
show user;
SELECT * FROM InstructorDBA.Instr_List;
SELECT * FROM InstructorDBA.Student_List;

CONNECT InstructorDBA/brr1wik7;
show user;    

/*Course Management Procedure - Admin have full rights to course information*/
GRANT SELECT, INSERT, DELETE, UPDATE ON Course_List TO admin_role;

/*Test Course Management Procedure*/
/*Test admin access*/
CONNECT bevans1/TheSecPass0;
show user;
SAVEPOINT Course_Account_Modify_Procedure;
SELECT * FROM InstructorDBA.Course_List;
UPDATE InstructorDBA.Course_List SET Course_Name = 'test';
INSERT INTO InstructorDBA.Course_List (Course_Num,            Course_Name,                Admin_Num , Course_Desc,                       Course_Hours, Section_Num)
    VALUES              (8888, 'Intro to Computer Science',1,             'Intro to Computer Science','3',          '1');          
SELECT * FROM InstructorDBA.Course_List;
DELETE FROM InstructorDBA.Course_List;
ROLLBACK TO Course_Account_Modify_Procedure;

/*Test instructor access*/
CONNECT mlopez3/TheSecPass2;
show user;
SELECT * FROM InstructorDBA.Course_List;

/*Test student access*/
CONNECT sgilbert1/TheSecPass0;
show user;
SELECT * FROM InstructorDBA.Course_List;

CONNECT InstructorDBA/brr1wik7;
show user;  


/*Section Management Procedure - Admins have full rights to section information*/
GRANT SELECT, INSERT, DELETE, UPDATE ON Section_Info TO admin_role;

/*Test Section Management Procedure*/
/*Test admin access*/
CONNECT bevans1/TheSecPass0;
show user;
SAVEPOINT Section_Account_Modify_Procedure;
SELECT * FROM InstructorDBA.Section_Info;
UPDATE InstructorDBA.Section_Info SET Section_Name = 'test';
INSERT INTO InstructorDBA.Section_Info (Section_Num,            Section_Name,           Section_Address,     Section_FoS,   Section_ZipCode)
    VALUES               (9999, 'Space Travel Section', '120 Finegand Place','Space Travel','31088');
SELECT * FROM InstructorDBA.Section_Info;
DELETE FROM InstructorDBA.Section_Info WHERE Section_Num = 9999;
ROLLBACK TO Section_Account_Modify_Procedure;
/*Test student access*/
CONNECT sgilbert1/TheSecPass0;
show user;
SELECT * FROM InstructorDBA.Section_Info;
/*Test instructor access*/
CONNECT mlopez3/TheSecPass2;
show user;
SELECT * FROM InstructorDBA.Section_Info;

CONNECT InstructorDBA/brr1wik7;
show user;  

/*Class Schedule Modify Procedure - Admins have full rights to the class schedule*/
GRANT SELECT, INSERT, DELETE, UPDATE ON Class_Sched TO admin_role;

/*Test Class Schedule Management Procedure*/
/*Test admin access*/
CONNECT bevans1/TheSecPass0;
show user;
SAVEPOINT Schedule_Account_Modify_Procedure;
SELECT * FROM InstructorDBA.Class_Sched;
UPDATE InstructorDBA.Class_Sched SET Sched_Notes = 'test';
INSERT INTO InstructorDBA.Class_Sched (Sched_Num,           Sched_Day, Sched_Time, Sched_Day_Off, Sched_Notes)
    VALUES              (9999,'Sun',     '0900-1100','Oct. 21st',   'Weekend Schedule');
SELECT * FROM InstructorDBA.Class_Sched;
DELETE FROM InstructorDBA.Class_Sched WHERE Sched_Num = 9999;
ROLLBACK TO Schedule_Account_Modify_Procedure;

/*Test instructor access*/
CONNECT mlopez3/TheSecPass2;
show user;
SELECT * FROM InstructorDBA.Class_Sched;

/*Test student access*/
CONNECT sgilbert1/TheSecPass0;
show user;
SELECT * FROM InstructorDBA.Class_Sched;

CONNECT InstructorDBA/brr1wik7;
show user;  

/*Admin Support Procedure - Admins have the ability to assist with adding classes for instructors or signing up students
  for classes if necessary.*/
GRANT SELECT, INSERT, DELETE, UPDATE ON Instr_Classes TO admin_role;
GRANT SELECT, INSERT, DELETE, UPDATE ON Student_Class_Signup TO admin_role;

/*Test Admin Support Schedule Management Procedure*/
/*Test admin access*/
CONNECT bevans1/TheSecPass0;
show user;
SAVEPOINT Admin_Support_Account_Modify_Procedure;
SELECT * FROM InstructorDBA.Instr_Classes;
SELECT * FROM InstructorDBA.Student_Class_Signup;
UPDATE InstructorDBA.Instr_Classes SET Class_Notes = 'test';
UPDATE InstructorDBA.Student_Class_Signup SET Student_Grade = 'test';

INSERT INTO InstructorDBA.Instr_Classes (Instr_Num, Sched_Num, Course_Num, Class_Notes, Class_Room)
    VALUES                ('8',       '9',       '9',        'Room Ready','Z');
    
    
INSERT INTO InstructorDBA.Student_Class_Signup (Student_Num, Instr_Num, Sched_Num,  Student_Grade)
    VALUES                (10, 9, 9,  'A');

SELECT * FROM InstructorDBA.Instr_Classes;
SELECT * FROM InstructorDBA.Student_Class_Signup;

DELETE FROM InstructorDBA.Instr_Classes WHERE Instr_Num = 8 AND Sched_Num = 9;
DELETE FROM InstructorDBA.Student_Class_Signup WHERE Student_Num = 10 AND Instr_Num = 9 AND Sched_Num = 9;
ROLLBACK TO Admin_Support_Account_Modify_Procedure;

/*Test instructor access*/
CONNECT mlopez3/TheSecPass2;
show user;

INSERT INTO InstructorDBA.Instr_Classes (Instr_Num, Sched_Num, Course_Num, Class_Notes, Class_Room)
    VALUES                ('8',       '9',       '9',        'Room Ready','Z');

/*Test student access*/
CONNECT sgilbert1/TheSecPass0;
show user;
DELETE FROM InstructorDBA.Student_Class_Signup WHERE Student_Num = 1 AND Instr_Num = 1 AND Sched_Num = 1;

CONNECT InstructorDBA/brr1wik7;
show user;  


/*Admin Account Restriction Procedure - Admins can only select & update the Admin_List table.*/
GRANT SELECT, UPDATE (Admin_Address, Admin_PhoneNum, Admin_LName, Admin_FName, Admin_ZipCode) ON Admin_List TO admin_role;
/*Use VPD to create policy restricting admin to only be able to view and update their information. Only the InstructorDBA user 
  can update this table.*/
CREATE OR REPLACE FUNCTION Get_Admin_Name (
 schema_v IN VARCHAR2, 
 tbl_v IN VARCHAR2)

RETURN VARCHAR2 IS
BEGIN
 RETURN ('User_Name = USER OR USER = ''InstructorDBA''') ;
END Get_Admin_Name;
/
BEGIN
 DBMS_RLS.ADD_POLICY (
  object_schema     => 'InstructorDBA', 
  object_name       => 'Admin_List',
  policy_name       => 'Hide_Admin_Info', 
  policy_function   => 'Get_Admin_Name',
  statement_types   => 'update',
  update_check     =>  TRUE);
END;
/

/*Test Admin restriction policy*/
/*Test admin account*/
CONNECT bevans1/TheSecPass0; 
show user;
SAVEPOINT Admin_Restriction_Procedure;
SELECT * FROM InstructorDBA.Admin_List;
UPDATE InstructorDBA.Admin_List SET Admin_Address = 'Changeit!';
UPDATE InstructorDBA.Admin_List SET Admin_Num = 1234555;
SELECT * FROM InstructorDBA.Admin_List;
ROLLBACK TO Admin_Restriction_Procedure;
/*Test instructor account*/
CONNECT mlopez3/TheSecPass2; 
show user;
SELECT * FROM InstructorDBA.Admin_List;

/*Test student access*/
CONNECT sgilbert1/TheSecPass0;
show user;
SELECT * FROM Admin_List;

/*Test InstructorDBA account*/
CONNECT InstructorDBA/brr1wik7 
show user;
SELECT * FROM Admin_List;

/*Instructor View Procedure - Personal info, section info, class schedule with course info, name and student number enrolled in classes.
Also, complete class schedule without student names.*/
/*Show personal info*/
CREATE OR REPLACE VIEW Instr_Personal_Info AS
SELECT * FROM Instr_List 
    WHERE Instr_List.User_Name = USER WITH CHECK OPTION;
GRANT SELECT ON Instr_Personal_Info TO instructor_role;

/*Show section info*/
CREATE OR REPLACE VIEW Instr_Section_Info AS
    SELECT * FROM Section_Info
        INNER JOIN Instr_List USING (Section_Num)
            WHERE Instr_List.User_Name = USER WITH CHECK OPTION;
GRANT SELECT ON Instr_Section_Info TO instructor_role;

/*Show class schedules info*/
GRANT SELECT ON Class_Sched TO instructor_role;

/*Show course info*/
GRANT SELECT ON Course_List TO instructor_role;

/*Show class schedule and course info*/            
CREATE OR REPLACE VIEW Instr_Class_Course_Info AS
SELECT Course_Name, Course_Desc, Course_Hours, Admin_LName, Admin_FName,
    Sched_Day, Sched_Time, Sched_Day_Off, Sched_Notes, 
        Class_Notes, Class_Room FROM Instr_List INNER JOIN Instr_Classes USING (Instr_Num)
            INNER JOIN Class_Sched USING (Sched_Num)
            INNER JOIN Course_List USING (Course_Num)
            INNER JOIN Admin_List USING (Admin_Num)
                WHERE Instr_List.User_Name = USER WITH CHECK OPTION;
GRANT SELECT ON Instr_Class_Course_Info TO instructor_role;                

/*Show students enrolled in classes*/
CREATE OR REPLACE VIEW Instr_Student_Class AS
    SELECT Course_Name, Sched_Day, Sched_Time, Sched_Day_Off, Class_Room, 
            Student_Num, Student_LName, Student_FName, Student_Grade FROM Instr_List INNER JOIN Instr_Classes USING (Instr_Num)
                INNER JOIN Class_Sched USING (Sched_Num)
                INNER JOIN Course_List USING (Course_Num)
                INNER JOIN Student_Class_Signup USING (Instr_Num, Sched_Num)
                INNER JOIN Student_List USING (Student_Num)
                    WHERE Instr_List.User_Name = USER WITH CHECK OPTION;
GRANT SELECT ON Instr_Student_Class TO instructor_role;

/*Show entire class schedule*/
CREATE OR REPLACE VIEW Instr_All_Class AS
SELECT Instr_LName, Instr_FName, Course_Name, Course_Desc, Course_Hours, Admin_LName, Admin_FName,
    Sched_Day, Sched_Time, Sched_Day_Off, Sched_Notes, 
        Class_Notes, Class_Room FROM Instr_List INNER JOIN Instr_Classes USING (Instr_Num)
            INNER JOIN Class_Sched USING (Sched_Num)
            INNER JOIN Course_List USING (Course_Num)
            INNER JOIN Admin_List USING (Admin_Num);
GRANT SELECT ON Instr_All_Class TO instructor_role;  

/*Test Instructor View Policy*/
CONNECT mlopez3/TheSecPass2;
show user;
SELECT * FROM InstructorDBA.Instr_Personal_Info;
SELECT * FROM InstructorDBA.Instr_Section_Info;
SELECT * FROM InstructorDBA.Instr_Class_Course_Info;
SELECT * FROM InstructorDBA.Instr_Student_Class;
SELECT * FROM InstructorDBA.Instr_All_Class;
SELECT * FROM InstructorDBA.Class_Sched;
SELECT * FROM InstructorDBA.Course_List;

/*Test student ability to view*/
CONNECT sgilbert1/TheSecPass0;
show user;
SELECT * FROM InstructorDBA.Instr_Personal_Info;
SELECT * FROM InstructorDBA.Instr_Section_Info;
SELECT * FROM InstructorDBA.Instr_Class_Course_Info;
SELECT * FROM InstructorDBA.Instr_Student_Class;
SELECT * FROM InstructorDBA.Instr_All_Class;
SELECT * FROM InstructorDBA.Class_Sched;
SELECT * FROM InstructorDBA.Course_List;

CONNECT InstructorDBA/brr1wik7;    
show user;


/*Instructor Modify Procedure - update personal info, class notes, student grades enrolled in class, remove students*/

/*Update personal info*/
GRANT UPDATE (Instr_Address, Instr_PhoneNum, Instr_LName, Instr_FName, Instr_ZipCode) ON Instr_Personal_Info TO instructor_role;

/*Update their class schedule*/
CREATE OR REPLACE VIEW Instr_Classes_Update AS
    SELECT Instr_Classes.SCHED_NUM SCHED_NUM,
Instr_Classes.COURSE_NUM COURSE_NUM,
Instr_Classes.CLASS_NOTES CLASS_NOTES,
Instr_Classes.CLASS_ROOM CLASS_ROOM FROM Instr_Classes INNER JOIN Instr_List USING (Instr_Num)
        WHERE Instr_List.User_Name = USER WITH CHECK OPTION;
GRANT SELECT, UPDATE (Class_Notes) ON Instr_Classes_Update TO instructor_role;  

/*Update student grade enrolled in their classes. Remove students from their classes*/
CREATE OR REPLACE VIEW Instr_Student_Modify AS
    SELECT Student_Num, Instr_Num, Sched_Num, Student_Grade FROM Instr_List INNER JOIN Instr_Classes USING (Instr_Num)
        INNER JOIN Student_Class_Signup USING (Instr_Num, Sched_Num)
            WHERE Instr_List.User_Name = USER WITH CHECK OPTION;
GRANT SELECT, UPDATE (Student_Grade) , DELETE ON Instr_Student_Modify TO instructor_role;

/*Test instructor update on personal info*/
CONNECT mlopez3/TheSecPass2;
show user;
SAVEPOINT Instr_Modify_Personal_Procedure;
SELECT * FROM InstructorDBA.Instr_Personal_Info;
UPDATE InstructorDBA.Instr_Personal_Info SET Instr_Address = '867 Orange St';
UPDATE InstructorDBA.Instr_Personal_Info SET User_Name = 'BillyBob7';
SELECT * FROM InstructorDBA.Instr_Personal_Info;
ROLLBACK TO Instr_Modify_Personal_Procedure;
/*Test student account access*/
CONNECT sgilbert1/TheSecPass0;
show user;
UPDATE InstructorDBA.Instr_Personal_Info SET Instr_Address = '867 Orange St';
SELECT * FROM InstructorDBA.Instr_Personal_Info;

/*Test instructor ability to select and update on their class schedule*/
CONNECT mlopez3/TheSecPass2;
show user;
SAVEPOINT Instr_Modify_Class_Procedure;
SELECT * FROM InstructorDBA.Instr_Classes_Update;
UPDATE InstructorDBA.Instr_Classes_Update SET Class_Notes = 'A/C Broke' WHERE Sched_Num = 3;
UPDATE InstructorDBA.Instr_Classes_Update SET Class_Room = 'Party_Room' WHERE Sched_Num = 3;
SELECT * FROM InstructorDBA.Instr_Classes_Update;
ROLLBACK TO Instr_Modify_Class_Procedure;
/*Test Select & Update with instructor trying to update another instructor's class*/
CONNECT brussell2/TheSecPass1;
show user;
SELECT * FROM InstructorDBA.Instr_Classes_Update;
UPDATE InstructorDBA.Instr_Classes_Update SET Class_Notes = 'A/C Broke' WHERE Sched_Num = 3;
UPDATE InstructorDBA.Instr_Classes_Update SET Class_Notes = 'A/C Broke' WHERE Instr_Num = 3 AND Sched_Num = 3;
SELECT * FROM InstructorDBA.Instr_Classes_Update;

/*Test student account access*/
CONNECT sgilbert1/TheSecPass0;
show user;
SELECT * FROM InstructorDBA.Instr_Classes_Update;
UPDATE InstructorDBA.Instr_Classes_Update SET Class_Notes = 'A/C Broke' WHERE Sched_Num = 3;

/*Test instructor ability to select, update, and delete students from their class*/
CONNECT mlopez3/TheSecPass2;
show user;
SAVEPOINT Instr_Modify_Delete_Point;
SELECT * FROM InstructorDBA.Instr_Student_Modify;
UPDATE InstructorDBA.Instr_Student_Modify SET Student_Grade = 'F' WHERE Student_Num = 2;
UPDATE InstructorDBA.Instr_Student_Modify SET Student_Grade = 'F' WHERE Student_Num = 3;
UPDATE InstructorDBA.Instr_Student_Modify SET Student_Num = 4 WHERE Student_Num = 3;
SELECT * FROM InstructorDBA.Instr_Student_Modify;
DELETE FROM InstructorDBA.Instr_Student_Modify WHERE Student_Num = 3;
SELECT * FROM InstructorDBA.Instr_Student_Modify;
ROLLBACK TO Instr_Modify_Delete_Point;

/*Test student access*/
CONNECT sgilbert1/TheSecPass0;
show user;
SELECT * FROM InstructorDBA.Instr_Student_Modify;
UPDATE InstructorDBA.Instr_Student_Modify SET Student_Grade = 'F' WHERE Student_Num = 2;
DELETE FROM InstructorDBA.Instr_Student_Modify WHERE Student_Num = 2;
SELECT * FROM InstructorDBA.Instr_Student_Modify;

CONNECT InstructorDBA/brr1wik7;    
show user;


/*Student View Procedure - personal info, instructor class schedule, classes enrolled in, grades for classes*/
/*Show personal info*/
CREATE OR REPLACE VIEW Student_Personal_Info AS
SELECT * FROM Student_List 
    WHERE Student_List.User_Name = USER WITH CHECK OPTION;
GRANT SELECT ON Student_Personal_Info TO student_role;

/*View the instructor class schedule*/
GRANT SELECT ON Instr_All_Class TO student_role; 


/*See what classes they are enrolled in and their grade*/
CREATE OR REPLACE VIEW Student_Class_Grade_View AS
    SELECT Student_LName, Student_FName, Course_Name, Student_Grade,
                Instr_LName, Instr_FName, Sched_Day, Sched_Time, Sched_Day_Off, Class_Room 
                    FROM Student_List INNER JOIN Student_Class_Signup USING (Student_Num)
                        INNER JOIN Instr_Classes USING (Instr_Num, Sched_Num)
                        INNER JOIN Class_Sched USING (Sched_Num)
                        INNER JOIN Course_List USING (Course_Num)
                        INNER JOIN Instr_List USING (Instr_Num)
                            WHERE Student_List.User_Name = USER WITH CHECK OPTION;
GRANT SELECT ON Student_Class_Grade_View TO student_role;


/*Test Student View personal info*/
CONNECT sgilbert1/TheSecPass0;
show user;
SELECT * FROM InstructorDBA.Student_Personal_Info;

/*Test instructor access*/
CONNECT mlopez3/TheSecPass2;
show user;
SELECT * FROM InstructorDBA.Student_Personal_Info;

/*Test Student View instructor class schedule*/
CONNECT sgilbert1/TheSecPass0;
show user;
SELECT * FROM InstructorDBA.Instr_All_Class;

/*Test Student View classes enrolled in and grade*/
CONNECT sgilbert1/TheSecPass0;
show user;
SELECT * FROM InstructorDBA.Student_Class_Grade_View;
/*Test instructor access*/
CONNECT mlopez3/TheSecPass2;
show user;
SELECT * FROM InstructorDBA.Student_Class_Grade_View;

CONNECT InstructorDBA/brr1wik7;    
show user;
/*Student Modify Procedure - update personal info and enroll in class*/
  
/*Student update personal information*/
GRANT UPDATE (Student_Address, Student_PhoneNum, Student_LName, Student_FName, Student_Zipcode) ON Student_Personal_Info TO student_role;
/*Student enroll in classes*/
/*Trigger for Student class enrollment - Prevent students from signing other students up for class.*/
CREATE OR REPLACE TRIGGER Student_Class_Signup_Trigger
BEFORE INSERT
   ON Student_Class_Signup
   FOR EACH ROW

DECLARE
   Tmp_Counter INTEGER;
   Tmp_Student_Num INTEGER;
BEGIN
    /*Only run code for Student users*/
    SELECT count(*) into Tmp_Counter FROM Student_List WHERE Student_List.User_Name = USER;
    IF Tmp_Counter > 0 THEN
        SELECT Student_Num INTO Tmp_Student_Num FROM Student_List WHERE Student_List.User_Name = USER;
            :new.Student_Num := Tmp_Student_Num;
            :new.Student_Grade := '';
    END IF;
END;
/
GRANT INSERT  ON Student_Class_Signup TO student_role;

/*Test update personal info*/
CONNECT sgilbert1/TheSecPass0;
show user;
SAVEPOINT Student_Modify_Personal_Point;
SELECT * FROM InstructorDBA.Student_Personal_Info;
UPDATE InstructorDBA.Student_Personal_Info SET Student_ZipCode = '90210';
UPDATE InstructorDBA.Student_Personal_Info SET User_Name = 'HackerMode';
SELECT * FROM InstructorDBA.Student_Personal_Info;
ROLLBACK TO Student_Modify_Personal_Point;
/*Test instructor access*/
CONNECT mlopez3/TheSecPass2;
show user;
UPDATE InstructorDBA.Student_Personal_Info SET Student_ZipCode = '90210';


/*Test enroll in class*/
CONNECT sgilbert1/TheSecPass0;
show user;
SAVEPOINT Student_Class_Signup_Point;
SELECT * FROM InstructorDBA.Student_Class_Grade_View;
INSERT INTO InstructorDBA.Student_Class_Signup (Student_Num, Instr_Num, Sched_Num,  Student_Grade)
        VALUES                ( 3,6, 6,  'A');

INSERT INTO InstructorDBA.Student_Class_Signup (Student_Num, Instr_Num, Sched_Num,  Student_Grade)
        VALUES                ( 1,3, 3,  'A');

SELECT * FROM InstructorDBA.Student_Class_Grade_View;
ROLLBACK TO Student_Class_Signup_Point;

/*Test instructor access*/
CONNECT mlopez3/TheSecPass2;
show user;
INSERT INTO InstructorDBA.Student_Class_Signup (Student_Num, Instr_Num, Sched_Num,  Student_Grade)
        VALUES                ( 3,6, 6,  'A');

/*Test admin access*/
CONNECT bevans1/TheSecPass0;
show user;
SAVEPOINT Admin_Student_Class_Signup_Point;
INSERT INTO InstructorDBA.Student_Class_Signup (Student_Num, Instr_Num, Sched_Num,  Student_Grade)
        VALUES                ( 3,6, 6,  'A');
SELECT  * FROM InstructorDBA.Student_Class_Signup;
ROLLBACK TO Admin_Student_Class_Signup_Point;
CONNECT InstructorDBA/brr1wik7;
show user;        

/*Class Tentative Schedule Procedure - InstructorDBA and admins can view/create tentative schedules, instructors can view
tentative schedules, and students can view approved schedules.*/

connect sys/brr1wik7 as sysdba;
show user;
GRANT SELECT ON InstructorDBA.Student_List TO lbacsys;
GRANT SELECT ON InstructorDBA.Instr_List TO lbacsys;
GRANT SELECT ON InstructorDBA.Admin_List TO lbacsys;

CONNECT lbacsys/brr1wik7; 
show user;

BEGIN
 SA_SYSDBA.CREATE_POLICY ('Sched_OLS_POL', 'ols_col', 'READ_CONTROL');

 SA_COMPONENTS.CREATE_LEVEL ('Sched_OLS_POL',40,'HS','HIGHLY_SENSITIVE');
 SA_COMPONENTS.CREATE_LEVEL ('Sched_OLS_POL',30,'S','SENSITIVE');

 SA_LABEL_ADMIN.CREATE_LABEL  ('Sched_OLS_POL',40,'HS');
 SA_LABEL_ADMIN.CREATE_LABEL  ('Sched_OLS_POL',30,'S');  

 SA_USER_ADMIN.SET_LEVELS ('Sched_OLS_POL','InstructorDBA', 'HS','S');

/*Student account update classification level*/
  FOR x IN (SELECT User_Name FROM InstructorDBA.Student_List)
  LOOP
  SA_USER_ADMIN.SET_LEVELS ('Sched_OLS_POL',''||x.User_Name||'', 'S','S');
  END LOOP;  
  
/*Instructor account update classification level*/
  FOR x IN (SELECT User_Name FROM InstructorDBA.Instr_List)
  LOOP
  SA_USER_ADMIN.SET_LEVELS ('Sched_OLS_POL',''||x.User_Name||'', 'HS','S');
  END LOOP; 
  
/*Admin account update classification level*/
  FOR x IN (SELECT User_Name FROM InstructorDBA.Admin_List)
  LOOP
  SA_USER_ADMIN.SET_LEVELS ('Sched_OLS_POL',''||x.User_Name||'', 'HS','S');
  END LOOP;   
  
SA_POLICY_ADMIN.APPLY_TABLE_POLICY ('Sched_OLS_POL','InstructorDBA', 'Class_Sched');
END;
/

/*Update classification column and test access*/
connect sys/brr1wik7 as sysdba;
show user;
UPDATE InstructorDBA.Class_Sched SET ols_col = CHAR_TO_LABEL('Sched_OLS_POL','S');
UPDATE InstructorDBA.Class_Sched SET ols_col = CHAR_TO_LABEL('Sched_OLS_POL','HS') WHERE Sched_Notes = 'Beta';
SELECT * FROM InstructorDBA.Class_Sched;
GRANT SELECT ON InstructorDBA.Class_Sched TO student_role;

/*Test InstructorDBA access*/
CONNECT InstructorDBA/brr1wik7;
show user; 
SELECT * FROM Class_Sched;
SAVEPOINT InstructorDBA_Student_Class_Sched_Insert;
INSERT INTO Class_Sched (Sched_Num,           Sched_Day, Sched_Time, Sched_Day_Off, Sched_Notes, ols_col)
    VALUES              (12345,'All',     '24 Hours','7 days a week',   'Alpha', CHAR_TO_LABEL('Sched_OLS_POL','HS'));  
SELECT * FROM Class_Sched;    
ROLLBACK TO InstructorDBA_Student_Class_Sched_Insert;


/*Test admin access*/
CONNECT bevans1/TheSecPass0;
show user;
SELECT * FROM InstructorDBA.Class_Sched;
SAVEPOINT Admin_Student_Class_Sched_Insert;
INSERT INTO InstructorDBA.Class_Sched (Sched_Num,           Sched_Day, Sched_Time, Sched_Day_Off, Sched_Notes, ols_col)
    VALUES              (12345,'All',     '24 Hours','7 days a week',   'Alpha', CHAR_TO_LABEL('Sched_OLS_POL','HS')); 
SELECT * FROM InstructorDBA.Class_Sched;    
ROLLBACK TO Admin_Student_Class_Sched_Insert;


/*Test instructor access*/
CONNECT mlopez3/TheSecPass2;
show user;
SELECT * FROM InstructorDBA.Class_Sched;
SAVEPOINT Instructor_Student_Class_Sched_Insert;
INSERT INTO InstructorDBA.Class_Sched (Sched_Num,           Sched_Day, Sched_Time, Sched_Day_Off, Sched_Notes, ols_col)
    VALUES              (12345,'All',     '24 Hours','7 days a week',   'Alpha', CHAR_TO_LABEL('Sched_OLS_POL','HS')); 
SELECT * FROM InstructorDBA.Class_Sched;    
ROLLBACK TO Instructor_Student_Class_Sched_Insert;

/*Test student access*/
CONNECT sgilbert1/TheSecPass0;
show user;
SELECT * FROM InstructorDBA.Class_Sched;
SAVEPOINT Student_Student_Class_Sched_Insert;
INSERT INTO InstructorDBA.Class_Sched (Sched_Num,           Sched_Day, Sched_Time, Sched_Day_Off, Sched_Notes, ols_col)
    VALUES              (12345,'All',     '24 Hours','7 days a week',   'Alpha', CHAR_TO_LABEL('Sched_OLS_POL','HS')); 
SELECT * FROM InstructorDBA.Class_Sched;    
ROLLBACK TO Student_Student_Class_Sched_Insert;
