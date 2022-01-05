
--////////////////////////////////////////////////VIEWS/////////////////////////////////////////////////////////

--View for medical data only
create view [Medical data]  as
select p.patient_id, p.age,  p.sex, p.excersise_angine, p.oldpeak, c.TYPE,  b.CHOLESTEROL, b.fasting_blood_suger,
r.ECG_results, s.slope, v.Maxing_Heart_Rate, v.Resting_Blood_Preasure
from patient p 
join PATIENT_SUFF_FROM_CHESTPAIN i on p.patient_ID=i.patient_ID join CHEST_PAIN_TYPE  c on i.chest_ID = c.chest_ID
join BLOOD_SAMPLE b on p.patient_ID = b.patient_ID
join patient_undergoing_ECG e on p.patient_ID = e.patinent_ID join resting_ecg r on e.ECG_ID = r.ECG_ID
join [PATIENT-HAS_st_slope] h on h.patient_ID = p.patient_ID join  st_slope s on h.st_ID = s.[st-ID]
join Vital_Measurments v on v.Patient_ID = p.patient_ID

select * from [Medical data];


--////////////////////////////////////////////////FUNCTIONS/////////////////////////////////////////////////////////


--1--Displaying cholesterol normal ranges and make a function that takes the 
--number and returns if it’s within the normal  range, higher or lower
create function Cholesterol_Ranges(@reading int)
returns varchar(50)
	begin
	declare @message varchar(50)
	if(@reading <200)
		set @message = 'Normal Range'
	else if (@reading <= 239)
		set @message = 'Borderline High'
	else
		set @message = 'Very High'
	return @message
	end

	
select dbo.Cholesterol_Ranges(110)

--Function Shows the result of Maxheart-rate Normal/high
 create function Heart_Rate_range (@result int, @id int)
 returns varchar(100)
 begin
	declare @range varchar(100)
	declare @age int 
	select @age = age from patient where patient_ID = @id
	if ((220 - @age) < @result )
		set @range = 'high Max heart rate'
	else 
		set @range = 'Normal'
	return @range
end
select dbo.Heart_Rate_range (160, 5)
select dbo.Heart_Rate_range (190, 5)

--Function that takes patientID  and returns  patient data stored in view
create function [getpatient medical data]  (@pnum int)
returns table
as
return
	(
	 select * 
	 from [Medical data] 
	 where patient_id = @pnum
	)
select * from [getpatient medical data] (5)


--Function that takes patient id and returns blood presure status and patient's name

create function resting_blood_test (@pID int)
returns varchar(300)
begin 

 declare @msg varchar(300),@rest int,@name varchar(50)
 select
     @rest = [Resting_Blood_Preasure],@name=p.name
 from Vital_Measurments v,patient p
 where p.patient_ID=v.Patient_ID
 and p.patient_ID=@pID

       if(@rest =120)
	   
	     set @msg=  'Patient '+@name+'RESTING Blood Pressure Is Normal'
 
       else if  (@rest <=90)
	   
	   set @msg ='Patient '+@name+'RESTING Blood Pressure Is less'
       else if  (@rest >120 and @rest <139 )
	   
	   set @msg ='Patient '+@name+'RESTING Blood Pressure Is prehyper'
	    else if  (@rest >=140 )
	   set @msg ='Patient '+@name+'RESTING Blood Pressure Is high'
	    return @msg 
end
drop function [dbo].[resting_blood_test]

select [dbo].[resting_blood_test](1)

--View info about patient 
create function GetInf (@id int)
returns table 
as
return 
		( select *
		   from [dbo].[patient] p
		   where p.patient_ID= @id
		)

select * from GetInf(10)


--////////////////////////////////////////////////PROCEDURES/////////////////////////////////////////////////////////


--1	Displaying which gender has higher heart rate than the other
 
create proc Gender_Heart_Rate
as
  declare @male int = 
  (select count(p.sex) from patient p inner join Vital_Measurments v on p.patient_ID = v.Patient_ID
  where v.Maxing_Heart_Rate > 170 and sex = 'M')
  declare @female int = 
  (select count(p.sex) from patient p inner join Vital_Measurments v on p.patient_ID = v.Patient_ID
  where v.Maxing_Heart_Rate > 170 and sex = 'F')
  select concat('Number of Females that have heart rate more than 170 is ',@female)
  select concat('Number of Males that have heart rate more than 170 is ',@male)

  Gender_Heart_Rate

  --2 Procedure counts chest_id to find out how many patients are in every type
create procedure chest_pain_patients
as
select COUNT(s.chest_ID) as total_OF_patients,c.TYPE from [dbo].[CHEST_PAIN_TYPE] c ,[dbo].[PATIENT_SUFF_FROM_CHESTPAIN] s
where s.chest_ID=c.chest_ID
group by c.TYPE
chest_pain_patients


---3-Procedure counts how many patients suffer from heart disease

create procedure heart  @id int
as

 declare @heart varchar(50),@msg  varchar(300)
 select
    @heart=count(heart_disease) 
 from patient
     where heart_disease=@id

	select case 
           when @id=0 then 'there are '+@heart +' '+'patient not have heart disease'
		   when @id=1 then  'there are '+@heart +' '+'patient have heart disease'
       end

	drop procedure [dbo].[heart]

	execute heart 1


	--////////////////////////////////////////////////TRIGGERS/////////////////////////////////////////////////////////
	
--1	Setting a trigger to record patients with heart rate that puts them in danger in a new table called emergency with 
--(patient name, id, heart rate, phone number). This table is for the doctor to avoid any catastrophic events)

create table Emergency_Patients(
	id int,
	p_name varchar(30),
	phone varchar(30),
	heart_rate int,
)

create trigger High_Heart_Rate
on [dbo].[Vital_Measurments]
after update,insert
as 
	if ((select Maxing_Heart_Rate from inserted)> 170)
	begin
		declare @p_id int = (select patient_id from inserted)
		declare @p_name varchar(30) = (select name from inserted i inner join patient p on i.Patient_ID = p.patient_ID)
		declare @phone varchar(30) = (select PHONE from inserted i inner join PHONE p on p.PATIENT_ID = i.Patient_ID)
		declare @rate int = (select Maxing_Heart_Rate from inserted)
		insert into Emergency_Patients(id,p_name,phone,heart_rate)
		values(@p_id,@p_name,@phone,@rate)
	end

insert into [dbo].[Vital_Measurments](Vital_Id,Resting_Blood_Preasure,Maxing_Heart_Rate,Patient_ID)
values(13,130,180,16)

select * from Emergency_Patients
---trigger for preventing update any vital measurments 
create TRIGGER safety1   
ON vital_measurments   
instead of  update   
AS   
   select ('You must disable Trigger "safety" to update!')  
     
update vital_measurments
set Resting_Blood_Preasure  = 200
where Patient_ID = 1;

--Trigger for preventing medical data view updating
CREATE TRIGGER safety   
ON [Medical data]   
instead of  update   
AS   
   select ('You must disable Trigger "safety" to update!')  
   ROLLBACK

 --A trigger stores in another table every insert query happens on patient table
create table history
(
username varchar(50) ,
ModifiedDate  date ,
deleted_id int,
inserted_id int)

go

create trigger DATA_Modified
on [dbo].[patient]
after insert
as 
   
      begin
	        declare @oldID int , @newID int ,@ID int,@note varchar(50)
			begin
			select @newID =[patient_ID]from inserted
			select @oldID  = [patient_ID]from deleted
		   insert into history values( SUSER_NAME() , getdate() , @oldID,@newID )
		   end
		   begin 
		   select SUSER_NAME()as username , getdate()as date ,@newID as inserted_id
		   end
		
	  end


	  insert into patient ([name])values ('s')
select * from history

--A trigger prevents any delete dml on patient table
create trigger t2
on patient 
instead of  delete 
as 
select 'not allow'
--////////////////////////////////////////////////SOME SELECTS STATEMENTS/////////////////////////////////////////////////////////
--1-Displaying which gender is more likely to have exercise angina
select count(sex),sex from patient where excersise_angine = 'Y' group by sex 


--2- the top 3 ages that have the highst num of patient having heart disease;  
Select top 3* from (
select count(age) as Num, p.age from [patient] p where heart_disease = 0 group by age
) newtable
order by age desc;


 --Selecting random sample of 100 patient
 select top 100* from patient p  join PATIENT_SUFF_FROM_CHESTPAIN c oN
 p.patient_ID = c.patient_ID  join patient_undergoing_ECG E on
 p.patient_ID = e.patinent_ID  join [PATIENT-HAS_st_slope] s on
 p.patient_ID = s.patient_ID 
 order by NEWID()

 
--Status result of each patient

select [name],[fasting_blood_suger],[TYPE],[heart_disease],[ECG_results],[Resting_Blood_Preasure],[Maxing_Heart_Rate] 
from
[dbo].[BLOOD_SAMPLE] b,[dbo].[patient] P,
[dbo].[CHEST_PAIN_TYPE] c,
[dbo].[resting_ecg] r,[dbo].
[Vital_Measurments] v,
[dbo].[patient_undergoing_ECG] pa,
[dbo].[PATIENT_SUFF_FROM_CHESTPAIN] ch
where
b.patient_ID=p.patient_ID and P.patient_ID=v.Patient_ID and 
ch.patient_ID=p.patient_ID and ch.chest_ID=c.chest_ID and 
r.ECG_ID=pa.ECG_ID and
pa.patinent_ID=p.patient_ID


 --////////////////////////////////////////////////RULE/////////////////////////////////////////////////////////

 
--Creating a rule on heart_dieases and sex
create rule heart_dieases as @s=0 or @s=1; 
go
sp_bindrule heart_dieases , 'patient.heart_disease';
create rule gen as @s='F' or @s='M';
go
sp_bindrule heart_dieases , 'patient.sex';

 --////////////////////////////////////////////////NON CLUSTER INDEX/////////////////////////////////////////////////////////

--Create a nonclustered index on age
create nonclustered index ix_age on patient (age);
 --////////////////////////////////////////////////SEQUENCE/////////////////////////////////////////////////////////

create sequence patient_ID
start with 1
increment by 1
minvalue 1
maxvalue 1000

