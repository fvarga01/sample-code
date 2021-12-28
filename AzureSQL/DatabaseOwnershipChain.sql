USE [master]
GO
drop database dbWork;
drop database dbProj;
drop database dbNumberedDb; 
drop login login1;
go
CREATE LOGIN [login1] WITH PASSWORD=N'<enter pwd here>', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
GO
create database dbWork; --schemas owned by dbo, uWorkGroup  has select on schema; uWorkGroupApp has SEL, INS, UPD, DEL, EXEC in App schema
create database dbProj; --schemas owned by dbo, uWorkGroup  has db_datareader, db_datawriter, db_ddladmin on schema. create obj in dbo schema blocked by ddl trigger
create database dbNumberedDb; --schemas owned by dbo
go
alter database dbWork set db_chaining on;
alter database dbProj set db_chaining on;
alter database dbNumberedDb set db_chaining on;
go
USE [dbNumberedDb]; ----------------------------------------------------------------------------------------------------------------------------------
go
GO
CREATE USER [login1] FOR LOGIN [login1]
GRANT CONNECT to [login1]
GO
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
GO
CREATE USER [login1] FOR LOGIN [login1]
GRANT CONNECT to [login1]
GO
GRANT SELECT ON SCHEMA::[schWork] TO [login1]
use dbProj ----------------------------------------------------------------------------------------------------------------------------------
go
CREATE SCHEMA [schProj] AUTHORIZATION [dbo];
go
select * from dbWork.schWork.vw1
go
CREATE USER [login1] FOR LOGIN [login1]
GRANT CONNECT to [login1]
GO
GRANT DELETE ON SCHEMA::[schProj] TO [login1]
GO
GRANT EXECUTE ON SCHEMA::[schProj] TO [login1]
GO
GRANT INSERT ON SCHEMA::[schProj] TO [login1]
GO
GRANT SELECT ON SCHEMA::[schProj] TO [login1]
GO
GRANT UPDATE ON SCHEMA::[schProj] TO [login1]
GO
ALTER ROLE [db_datareader] ADD MEMBER [login1]
GO
ALTER ROLE [db_datawriter] ADD MEMBER [login1]
GO
ALTER ROLE [db_ddladmin] ADD MEMBER [login1]
GO


--run as standard user:

use dbProj
select * from dbWork.schWork.vw1 -- expect sel ok
select * from dbNumberedDb.schNum.tbl1 -- expect perm denied - ok

delete from dbWork.schWork.vw1 -- expect perm denied - ok

alter procedure schProj.proc1
as
begin
	delete from dbWork.schWork.vw1
end
exec dbProj.schProj.proc1 -- Desired behavior=perm denied, actual behavior=delete succeeds

select * from dbWork.schWork.vw1 -- note rows have been deleted