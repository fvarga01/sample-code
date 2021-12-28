------------------------ Alternative 1
USE [master]
GO

drop database dbWork;
drop database dbProj;
drop database dbNumberedDb; 
drop login [developer];
drop login [app_account];
DROP LOGIN [trusted_db_owner];
go

CREATE LOGIN [developer] WITH PASSWORD=N'<enter pwd here>', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF;
CREATE LOGIN [app_account] WITH PASSWORD=N'<enter pwd here>', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF;
CREATE LOGIN [trusted_db_owner] WITH PASSWORD=N'<enter pwd here>', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
GO

-- This account is only being used to limit the DB ownership, it is never going to be used to connect, so we can disable it
ALTER LOGIN [trusted_db_owner] DISABLE
go

create database dbWork; --schemas owned by dbo, uWorkGroup  has select on schema; uWorkGroupApp has SEL, INS, UPD, DEL, EXEC in App schema
create database dbProj; --schemas owned by dbo, uWorkGroup  has db_datareader, db_datawriter, db_ddladmin on schema. create obj in dbo schema blocked by ddl trigger
create database dbNumberedDb; --schemas owned by dbo
go

-- break ownership
ALTER AUTHORIZATION ON DATABASE::dbWork TO [trusted_db_owner]
ALTER AUTHORIZATION ON DATABASE::dbNumberedDb TO [trusted_db_owner]
go

-- No more CDOC for dbProj
alter database dbWork set db_chaining on;
alter database dbNumberedDb set db_chaining on;
-- go


USE [dbNumberedDb]; ----------------------------------------------------------------------------------------------------------------------------------
go
CREATE SCHEMA [schNum] AUTHORIZATION [dbo];
go
create table [dbNumberedDb].schNum.tbl1 (col1 int)
insert into [dbNumberedDb].schNum.tbl1 values (1), (2), (3) ,(4) ,(5)
select u.name userN, sch.name, o.name objN from sys.objects o 
	left join sys.database_principals u on o.principal_id=u.principal_id 
	join sys.schemas sch on sch.schema_id = o.schema_id
	where o.name like '%tbl%' order by o.name
go


use [dbWork] ----------------------------------------------------------------------------------------------------------------------------------
go
CREATE SCHEMA [schWork] AUTHORIZATION [dbo];
go
create view [schWork].vw1 as select * from dbNumberedDb.schNum.tbl1;
go

-- ** security note: note_1
-- Optional: 
-- It may be possible that you want to grant SELECT & EXECUTE to developers on the work DB in order to help devs create the reports before signing
-- CREATE USER [developer] FOR LOGIN [developer];
-- GRANT SELECT, EXECUTE ON SCHEMA::[schWork] TO [developer];
-- go

use dbProj ----------------------------------------------------------------------------------------------------------------------------------
go
CREATE SCHEMA [schProj] AUTHORIZATION [dbo];
go

CREATE USER [developer] FOR LOGIN [developer]
GO
GRANT DELETE ON SCHEMA::[schProj] TO [developer]
GRANT EXECUTE ON SCHEMA::[schProj] TO [developer]
GRANT INSERT ON SCHEMA::[schProj] TO [developer]
GRANT SELECT ON SCHEMA::[schProj] TO [developer]
GRANT UPDATE ON SCHEMA::[schProj] TO [developer]
go
ALTER ROLE [db_datareader] ADD MEMBER [developer]
ALTER ROLE [db_datawriter] ADD MEMBER [developer]
ALTER ROLE [db_ddladmin] ADD MEMBER [developer]
GO

CREATE USER [app_account] FOR LOGIN [app_account]
GO
GRANT EXECUTE ON SCHEMA::[schProj] TO [app_account]
GRANT SELECT ON SCHEMA::[schProj] TO [app_account]
go

----------------------------------------------------------------
-- Granting permission via signed modules
--
CREATE MASTER KEY ENCRYPTION BY PASSWORD = '<Secret p@ssw0rD>'
go

CREATE CERTIFICATE [cert_dbProj] WITH SUBJECT = 'dbProj signing certificate'
go

-- Generate the script for copying the certificate to dbWork & dbNumberedDb:
declare @cer varbinary(MAX)
declare @cert_name sysname
declare @cmd nvarchar(MAX)
select @cert_name = 'cert_dbProj'
select @cer = CERTENCODED(cert_id(@cert_name))
SET @cmd = '
USE [dbWork]; 
CREATE CERTIFICATE ' + quotename(@cert_name) + ' FROM BINARY = ' + sys.fn_varbintohexstr(@cer) + ';
CREATE USER ' + quotename(@cert_name) + ' FOR CERTIFICATE ' + quotename(@cert_name) + ';
GRANT SELECT, EXECUTE ON SCHEMA::[schWork] TO ' + quotename(@cert_name) + ';
USE [dbNumberedDb]; 
CREATE CERTIFICATE ' + quotename(@cert_name) + ' FROM BINARY = ' + sys.fn_varbintohexstr(@cer) + ';
CREATE USER ' + quotename(@cert_name) + ' FOR CERTIFICATE ' + quotename(@cert_name) + ';'
-- print @cmd
EXEC(@cmd)
go

-- create a SP that will allow developers to sign stored procedures
CREATE PROC sp_sign_module( @schema_name sysname, @proc_name sysname )
WITH EXECUTE AS OWNER
AS
	DECLARE @cmd nvarchar(max)
	SET @cmd = N'ADD SIGNATURE TO ' + quotename(@schema_name) + N'.' + quotename(@proc_name) + N'  BY CERTIFICATE [cert_dbProj];'
	EXEC(@cmd)
go

CREATE PROC sp_sign_objects_in_schema(@schema_name sysname) 
AS
	DECLARE @obj_name sysname
	DECLARE @object_id int
	DECLARE object_to_sign CURSOR FOR SELECT name, object_id FROM sys.objects WHERE type in ('P', 'TF') AND schema_id = schema_id(@schema_name) ORDER BY object_id

	OPEN object_to_sign
	FETCH NEXT FROM object_to_sign INTO @obj_name, @object_id

	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF( NOT EXISTS(SELECT * FROM sys.crypt_properties crypt, sys.certificates certs WHERE crypt.crypt_type = 'SPVC' AND crypt.major_id = @object_id AND certs.thumbprint = crypt.thumbprint AND certs.name = 'cert_dbProj'))
		BEGIN
			EXEC sp_sign_module @schema_name, @obj_name;
		END
		FETCH NEXT FROM object_to_sign INTO @obj_name, @object_id
	END

	CLOSE object_to_sign;
	DEALLOCATE object_to_sign;
go

GRANT EXECUTE ON sp_sign_objects_in_schema TO [developer]
go

----------------------------------------------------------------------
-- run as developer
use dbProj
go
EXECUTE AS LOGIN = 'developer'
go

-- create approved modules
create function schProj.view1()
returns @retval TABLE (col1 int)
as 
BEGIN
	INSERT INTO @retval SELECT * from dbWork.schWork.vw1
	return
END
go

CREATE VIEW schProj.vw1 AS SELECT * FROM schProj.view1()
go

create PROC schProj.proc1
as 
	SELECT * from dbWork.schWork.vw1
go

ADD SIGNATURE TO schProj.view1 BY CERTIFICATE [cert_dbProj] -- will fail as developer has no direct access to the signing cert - OK
go

EXEC [sp_sign_objects_in_schema]  'schProj';
go

-- developer can runs queries directly (See note_1)
SELECT * from dbWork.schWork.vw1
go

SELECT * FROM schProj.vw1; -- OK
SELECT * FROM schProj.view1(); --OK
EXEC schProj.proc1; --OK
go


-----------------------------------------
-- Trying to abuse the ownership chains? 
CREATE USER [trusted_db_owner] FOR LOGIN [trusted_db_owner]
go
delete from dbWork.schWork.vw1 -- expect perm denied - ok
go
create procedure schProj.my_evil_proc1 -- will fail, no permission to create PROC
as
begin
	delete from dbWork.schWork.vw1
end
go

EXEC [sp_sign_objects_in_schema]  'schProj';
go
-- fails: Msg 229, Level 14, State 5, Procedure my_evil_proc1, Line 164
-- The DELETE permission was denied on the object 'vw1', database 'dbWork', schema 'schWork'.
EXEC schProj.my_evil_proc1
go

REVERT
go

------------------------------------------------------------------
--run as application account:

use dbProj
go
EXECUTE AS LOGIN = 'app_account'
go

select * from dbWork.schWork.vw1 -- perm denied  ok
go
select * from dbNumberedDb.schNum.tbl1 -- expect perm denied - ok
go

SELECT * FROM schProj.vw1; -- OK
SELECT * FROM schProj.view1(); --OK
EXEC schProj.proc1; --OK
go

delete from dbWork.schWork.vw1 -- expect perm denied - ok
go

create procedure schProj.my_evil_proc1 -- will fail, no permission to create PROC
as
begin
	delete from dbWork.schWork.vw1
end
go

revert
go


