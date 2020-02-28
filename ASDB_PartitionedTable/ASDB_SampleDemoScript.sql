/*
DO NOT RUN IN PRODUCTION, THIS SCRIPT DROPS AND DELETES TABLES.

This script demonstrates the table partitioning feature in Azure SQL Database (ASDB).

Tables:
1. dbo.alignedTable1 - table with partitioned aligned indexes. 
	Both the clustered index and non-clustered index are partitioned using the same partition scheme/function
2. dbo.nonAlignedTable1 - table without partitioned aligned indexes. 
	The clustered index is partitioned while the non-clustered index is not partitioned.
3. dbo.nonAlignedTable2- table without partitioned aligned indexes. 
	The clustered index is not partitioned while the non-clustered index is partitioned.

Partition function with initial range boundary values on:
	DATEADD(dd,-4, getdate()): 4 days ago
	DATEADD(dd,-1, getdate()) : yesterday
	getdate() : today's date

*/

---------------------------------------------------------------
--------     Cleanup Queries               --------------------
---------------------------------------------------------------
/*
drop table if exists dbo.staging1
drop table if exists dbo.staging2
drop table if exists dbo.staging3
drop table if exists dbo.alignedTable1
drop table if exists dbo.nonAlignedTable1
drop table if exists dbo.nonAlignedTable2
drop partition scheme sch1
drop partition function pf1
*/
go

---------------------------------------------------------------
-------- Partition Function and Scheme     --------------------
---------------------------------------------------------------
-- Step1: Create Partition Function **********************
--Range right means the defined boundary value falls to the partition to the right
--note that although getdate() is used to specify the partition, the partition range values are static, not dynamic
CREATE PARTITION FUNCTION [pf1] (DATE) AS RANGE RIGHT FOR VALUES    (
	 -- partiton1 is everything < 4 days ago
	 DATEADD(dd,-4, getdate()),  --  >= 4 days ago & < yesterday
	DATEADD(dd,-1, getdate()), --  >= yesterday & < today's date
	 getdate() -- partition4 >= today's date
	 );

--$PARTITION helper function to see which partition a value falls in:
select cast(DATEADD(dd,-5, getdate()) as date) as [rangeValue], $PARTITION.[pf1](DATEADD(dd,-5, getdate())) as partitionNumber--p1
select cast(DATEADD(dd,-4, getdate()) as date)as [rangeValue], $PARTITION.[pf1](DATEADD(dd,-4, getdate())) as partitionNumber--p2
select cast(DATEADD(dd,-3, getdate()) as date)as [rangeValue], $PARTITION.[pf1](DATEADD(dd,-3, getdate())) as partitionNumber--p2
select cast(DATEADD(dd,-2, getdate()) as date)as [rangeValue], $PARTITION.[pf1](DATEADD(dd,-2, getdate())) as partitionNumber--p2
select cast(DATEADD(dd,-1, getdate()) as date)as [rangeValue], $PARTITION.[pf1](DATEADD(dd,-1, getdate())) as partitionNumber --p3
select cast(getdate() as date)as [rangeValue], $PARTITION.[pf1](getdate()) as partitionNumber --p4
select cast(DATEADD(dd,1, getdate()) as date)as [rangeValue], $PARTITION.[pf1](DATEADD(dd,1, getdate())) as partitionNumber --p4

-- Step2: Create Parition Scheme  **************************************
-- Unlike on-prem SQL Server, in ASDB Single database, you cannot control FG placement so just choose PRIMARY filegroup
CREATE PARTITION SCHEME sch1 AS PARTITION [pf1]
	ALL TO ([PRIMARY]);
GO

---------------------------------------------------------------
-------- Partition Aligned Sample    --------------------------
-- Partitioned aligned demo: Both clustered index and non-clustered index will be partition aligned
---------------------------------------------------------------

-- Step3:  *******************
-- Create non-partitioned table and load data. We will enable partitioning after loading some initial data.
CREATE TABLE [dbo].[alignedTable1] 
([pkcol] [int] NOT NULL,
 [datacol] [int] NULL,
 [datacol2] [int] NULL,
 [datacol3] [int] NULL,
 [partitioncol] date not null);
 --add pk clustered index (no partitioning yet)
ALTER TABLE dbo.alignedTable1 ADD CONSTRAINT PK_alignedTable1 PRIMARY KEY CLUSTERED (pkcol);

-- Load data into partition 2 which holds data from two days ago (use the $PARTITION function to confirm)
DECLARE @val INT
declare @partCol date = DATEADD(dd,-2, getdate()); -- yesterday
select @partCol as [rangeValue], $PARTITION.[pf1](@partCol) as partitionNumber --p2
SELECT @val=1
WHILE @val <=1000
BEGIN  
   INSERT INTO dbo.alignedTable1(pkcol, datacol, datacol2, datacol3, partitioncol) VALUES (@val, @val+1, @val+1, @val+1, @partCol)
   set @val = @val + 1
END


--Step 4: Convert nonpartitioned table to partitioned. 
--drop the non-partitioned clustered index, we will create a new partitioned index
ALTER TABLE dbo.alignedTable1 DROP CONSTRAINT PK_alignedTable1 -- must drop cluIdx to recreate

-- Add partitioned clustered index
-- https://docs.microsoft.com/en-us/sql/relational-databases/partitions/partitioned-tables-and-indexes?view=sql-server-ver15#partitioning-clustered-indexes
-- cluIdx clustering key must contain the partitioning column, sql will silently add it as key column not explicitly specified
-- if cluIdx is unique, you must explicitly specify that the clustered index key contain the partitioning column.
ALTER TABLE dbo.alignedTable1 ADD CONSTRAINT PK_alignedTable1 PRIMARY KEY CLUSTERED  (pkcol,partitioncol) ON sch1(partitioncol)
/* If clustered index is not a primary key, you create the clustered index as follows:
	CREATE unique CLUSTERED INDEX IX_alignedTable1_partitioncol
	ON dbo.alignedTable1 (pkcol,partitioncol)
	ON sch1(partitioncol)
*/

-- Add partitioned non-clustered index
CREATE NONCLUSTERED INDEX NCIX_alignedTable1 ON dbo.alignedTable1 (datacol)
  ON sch1(partitioncol)

--Step5: Add new data into the partition holding data for 1 day(s) after today *****************************************************
DECLARE @val INT
declare @startingPK int
declare @partCol date = DATEADD(dd, 1,getdate()); -- one day later  ***
select @startingPK = MAX(pkcol) + 1 from alignedTable1
SELECT @val = @startingPK
WHILE @val < @startingPK + 30
BEGIN  
   INSERT INTO dbo.alignedTable1(pkcol, datacol, datacol2, datacol3, partitioncol) VALUES (@val, @val+2, @val+2, @val+2, @partCol)
   set @val = @val + 1
END

--Step6: Add a new partition via the SPLIT command. The new boundary value is set to one day after today *****************************************************
declare @partCol date = DATEADD(dd, 1,getdate()); -- one day later
select cast(@partCol as date)as [rangeValue], $PARTITION.[pf1](@partCol) as oldPartitionNumber --p4
alter partition scheme sch1 next used [primary]; -- should not need in ASDB but may fail  without it
ALTER PARTITION FUNCTION pf1() SPLIT RANGE ( @partCol) 
select cast(@partCol as date)as [rangeValue], $PARTITION.[pf1](@partCol) as newPartitionNumber --p5
-- (optional) Run QryA: Note that the mostly recently added rows have now ben moved to the last partition
go
---------------------------------------------------------------
-------- Partition Non-Aligned Sample 1  ------------------------
--The clustered index is partitioned while the non-clustered index is not partitioned.
---------------------------------------------------------------

-- Step3:  *******************
-- Create non-partitioned table and load data first. We will then enable partitioning
CREATE TABLE [dbo].[nonAlignedTable1] 
([pkcol] [int] NOT NULL,
 [datacol] [int] NULL,
 [datacol2] [int] NULL,
 [datacol3] [int] NULL,
 [partitioncol] date not null);
--add pk clustered index (no partitioning yet)
ALTER TABLE dbo.nonAlignedTable1 ADD CONSTRAINT PK_nonAlignedTable1 PRIMARY KEY CLUSTERED (pkcol); 

-- Load data into partition 2 which holds data from two days ago (use the $PARTITION function to confirm)
DECLARE @val INT
declare @partCol date = DATEADD(dd,-2, getdate()); -- yesterday
SELECT @val=1
WHILE @val <=1000
BEGIN  
   INSERT INTO dbo.nonAlignedTable1(pkcol, datacol, datacol2, datacol3, partitioncol) VALUES (@val, @val+1, @val+1, @val+1, @partCol)
   set @val = @val + 1
END

--Step 4: Convert nonpartitioned table to partitioned. 
--drop the non-partitioned clustered index, and add a new partitioned clustered index
ALTER TABLE dbo.nonAlignedTable1 DROP CONSTRAINT PK_nonAlignedTable1
ALTER TABLE dbo.nonAlignedTable1 ADD CONSTRAINT PK_nonAlignedTable1 PRIMARY KEY CLUSTERED  (pkcol,partitioncol) ON sch1(partitioncol)

--add non-partitioned non-clustered index:
CREATE NONCLUSTERED INDEX NCIX_nonAlignedTable1 ON dbo.nonAlignedTable1 (datacol) ON [PRIMARY]

--Step5: Add new data into the partition holding data for 2 day(s) after today *****************************************************
DECLARE @val INT
declare @startingPK int
declare @partCol date = DATEADD(dd, 2,getdate()); -- two days later ***
select @startingPK = MAX(pkcol) + 1 from nonAlignedTable1
SELECT @val = @startingPK
WHILE @val < @startingPK + 30
BEGIN  
   INSERT INTO dbo.nonAlignedTable1(pkcol, datacol, datacol2, datacol3, partitioncol) VALUES (@val, @val+2, @val+2, @val+2, @partCol)
   set @val = @val + 1
END

--Step6: Add a new partition via the SPLIT command. The new boundary value is set to two days after today ***************************************************
declare @partCol date = DATEADD(dd, 2,getdate()); -- two days later
select cast(@partCol as date)as [rangeValue], $PARTITION.[pf1](@partCol) as partitionNumber --p4/5
alter partition scheme sch1 next used [primary]; -- should not need in ASDB but may fail  without it
ALTER PARTITION FUNCTION pf1() SPLIT RANGE ( @partCol) 
select cast(@partCol as date)as [rangeValue], $PARTITION.[pf1](@partCol) as partitionNumber --p5/6
-- Run QryA: Note that the mostly recently added rows have now ben moved to a new partition
go

---------------------------------------------------------------
-------- Partition Non-Aligned Sample 2  ------------------------
--The clustered index is not partitioned while the non-clustered index is partitioned.
---------------------------------------------------------------

-- Step3:  *******************
-- Create non-partitioned table and load data first. We will then enable partitioning
CREATE TABLE [dbo].[nonAlignedTable2] 
([pkcol] [int] NOT NULL,
 [datacol] [int] NULL,
 [datacol2] [int] NULL,
 [datacol3] [int] NULL,
 [partitioncol] date not null);
--add pk clustered index (no partitioning yet)
ALTER TABLE dbo.nonAlignedTable2 ADD CONSTRAINT PK_nonAlignedTable2 PRIMARY KEY CLUSTERED (pkcol); 

-- Load data into partition 2 which holds data from two days ago (use the $PARTITION function to confirm)
DECLARE @val INT
declare @partCol date = DATEADD(dd,-2, getdate()); -- yesterday
SELECT @val=1
WHILE @val <=1000
BEGIN  
   INSERT INTO dbo.nonAlignedTable2(pkcol, datacol, datacol2, datacol3, partitioncol) VALUES (@val, @val+1, @val+1, @val+1, @partCol)
   set @val = @val + 1
END

--Step 4: Convert nonpartitioned table to partitioned. 
--keep non-partitioned clustered index but add a partitioned non-clustered index:
CREATE NONCLUSTERED INDEX NCIX_nonAlignedTable2 ON dbo.nonAlignedTable2 (datacol)
  ON sch1(partitioncol)

--Step5: Add new data into the partition holding data for 3 day(s) after today *****************************************************
DECLARE @val INT
declare @startingPK int
declare @partCol date = DATEADD(dd, 3,getdate()); -- three days later ***
select @startingPK = MAX(pkcol) + 1 from nonAlignedTable2
SELECT @val = @startingPK
WHILE @val < @startingPK + 30
BEGIN  
   INSERT INTO dbo.nonAlignedTable2(pkcol, datacol, datacol2, datacol3, partitioncol) VALUES (@val, @val+2, @val+2, @val+2, @partCol)
   set @val = @val + 1
END

--Step6: Add a new partition via the SPLIT command. The new boundary value is set to two days after today ***************************************************
declare @partCol date = DATEADD(dd, 3,getdate()); -- two days later
select cast(@partCol as date)as [rangeValue], $PARTITION.[pf1](@partCol) as partitionNumber --p4/5/6
alter partition scheme sch1 next used [primary]; -- should not need in ASDB but may fail  without it
ALTER PARTITION FUNCTION pf1() SPLIT RANGE ( @partCol) 
select cast(@partCol as date)as [rangeValue], $PARTITION.[pf1](@partCol) as partitionNumber --p5/6/7
-- Run QryA: Note that the mostly recently added rows have now ben moved to a new partition
go

---------------------------------------------------------------
-------- Partition Switch              ------------------------
-- in this example will will switch out the data from partition2 to a staging table
---------------------------------------------------------------
--drop table if exists staging1
CREATE TABLE [dbo].[staging1]
([pkcol] [int] NOT NULL,
 [datacol] [int] NULL,
 [datacol2] [int] NULL,
 [datacol3] [int] NULL,
 [partitioncol] date not null)
GO

------------------- STEP1: Switch from partitioned table into staging table -----------------
--index definition between on staging table should match partitioned table, expect staging table is not partitioned.


--OPTION1: partitioned aligned.  Recreate dbo.staging1 before attempting. *********************************************************
-- SWITCH source = alignedTable (partition 2) , dest=staging1
ALTER TABLE dbo.staging1 ADD CONSTRAINT PK_staging1 PRIMARY KEY CLUSTERED  (pkcol,partitioncol)
CREATE NONCLUSTERED INDEX NCIX_staging1 ON dbo.staging1 (datacol)
alter table alignedTable1 switch partition 2 to staging1

--OPTION2: partition non-aligned. Recreate dbo.staging1 before attempting. *********************************************************
-- SWITCH source = nonAlignedTable1 (partition 2) , dest= staging1
---nonAlignedTable1:The clustered index is partitioned while the non-clustered index is not partitioned.
ALTER TABLE dbo.staging1 ADD CONSTRAINT PK_staging1 PRIMARY KEY CLUSTERED  (pkcol,partitioncol)
CREATE NONCLUSTERED INDEX NCIX_staging1 ON dbo.staging1 (datacol)
alter table nonAlignedTable1 switch partition 2 to staging1
/*
	You'll get an error stating indexes are not aligned: 
	Msg 7733, Level 16, State 4, Line 268
	'ALTER TABLE SWITCH' statement failed. The table 'AdventureWorksLT.dbo.nonAlignedTable1' is partitioned while index 'NCIX_nonAlignedTable1' is not partitioned.
*/
--disable the indexes and reattempt:
alter index NCIX_staging1 on staging1 DISABLE;
alter index NCIX_nonAlignedTable1 on nonAlignedTable1 DISABLE;
alter table nonAlignedTable1 switch partition 2 to staging1
select name, is_disabled, type_desc
from sys.indexes where object_id in (object_id('dbo.nonAlignedTable1'),
	object_id('dbo.nonAlignedTable2'),
	object_id('dbo.staging1'))

--data is now successfully moved
select 'nonAlignedTable1' as tblName, partitioncol, $Partition.[pf1](partitioncol) partitionnum, count(*) numrows from nonAlignedTable1 group by partitioncol
select 'staging1' as tblName, partitioncol, count(*) numrows from staging1 group by partitioncol

--go back and re-enable indexes
alter index NCIX_nonAlignedTable1 on nonAlignedTable1 REBUILD;
select name, is_disabled, type_desc
from sys.indexes where object_id in (object_id('dbo.nonAlignedTable1'),
	object_id('dbo.nonAlignedTable2'),
	object_id('dbo.staging1'))

--OPTION3: partition non-aligned.  Recreate dbo.staging1 before attempting. *********************************************************
-- SWITCH source = nonAlignedTable2 (partition 2) , dest=staging1
---nonAlignedTable1:The clustered index is not partitioned while the non-clustered index is partitioned.
ALTER TABLE dbo.[staging1] ADD CONSTRAINT PK_staging1 PRIMARY KEY CLUSTERED (pkcol) 
CREATE NONCLUSTERED INDEX NCIX_staging1 ON dbo.staging1 (datacol)
alter table nonAlignedTable2 switch partition 2 to staging1
/*
Warning: The specified partition 2 for the table 'AdventureWorksLT.dbo.nonAlignedTable2' was ignored in ALTER TABLE SWITCH statement because the table is not partitioned.
Msg 7733, Level 16, State 3, Line 276
'ALTER TABLE SWITCH' statement failed. The index 'NCIX_nonAlignedTable2' is partitioned while table 'AdventureWorksLT.dbo.nonAlignedTable2' is not partitioned.
*/
--disabling indexes will not help here, because the clustered index/heap will need to be partitioned on in order to run the switch
alter index NCIX_staging1 on staging1 DISABLE;--to-re-enable you must rebuild: alter index NCIX_staging1 on staging1 REBUILD
alter index NCIX_nonAlignedTable2 on nonAlignedTable2 DISABLE;--to re-enable you must rebuild: alter index NCIX_nonAlignedTable2 on nonAlignedTable2 REBUILD
select name, is_disabled, type_desc
from sys.indexes where object_id in (object_id('dbo.nonAlignedTable1'),
	object_id('dbo.nonAlignedTable2'),
	object_id('dbo.staging1'))
alter table nonAlignedTable2 switch partition 2 to staging1 -- still fails with error 7733





------------------- STEP2: Switch from staging table into partitioned table-----------------

--in this case you need to ensure there is a constraint on the staging table which matches the destination partition
-- add a check constraint to the staging table which matches the date range in partition 2
--alter table staging1 drop constraint ck_partDateRange
declare @min date =  cast(dateadd(dd,-4,getdate()) as date);
declare @max date =  cast(dateadd(dd,-1,getdate()) as date);
declare @sql nvarchar(1000) = N'alter table [staging1] with check add constraint ck_partDateRange check ' + 
		'( partitioncol >= '''+ cast(@min as nvarchar) +''' and '+
		'partitioncol < ''' + cast(@max  as nvarchar) + ''' and partitioncol is not null)';
exec (@sql);


--OPTION1
alter table staging1  switch to alignedTable1 partition 2

--OPTION 2
alter table staging1 switch to nonAlignedTable1 partition 2
--this will fail, indicating indexes are not aligned
/*
	Msg 7733, Level 16, State 4, Line 330
	'ALTER TABLE SWITCH' statement failed. The table 'AdventureWorksLT.dbo.nonAlignedTable1' is partitioned while index 'NCIX_nonAlignedTable1' is not partitioned.
*/
--disable the indexes and reattempt:
alter index NCIX_staging1 on staging1 DISABLE;
alter index NCIX_nonAlignedTable1 on nonAlignedTable1 DISABLE;
alter table staging1 switch to nonAlignedTable1 partition 2
select name, is_disabled, type_desc
	from sys.indexes where object_id in (object_id('dbo.nonAlignedTable1'),
	object_id('dbo.nonAlignedTable2'),
	object_id('dbo.staging1'))
--data is now successfully moved
select 'nonAlignedTable1' as tblName, partitioncol, $Partition.[pf1](partitioncol) partitionnum, count(*) numrows from nonAlignedTable1 group by partitioncol
select 'staging1' as tblName, partitioncol, count(*) numrows from staging1 group by partitioncol
--go back and re-enable indexes
alter index NCIX_nonAlignedTable1 on nonAlignedTable1 REBUILD;
select name, is_disabled, type_desc
from sys.indexes where object_id in (object_id('dbo.nonAlignedTable1'),
	object_id('dbo.nonAlignedTable2'),
	object_id('dbo.staging1'))

--OPTION 3
alter table staging1 switch to nonAlignedTable2 partition 2 --fails because the clustered index/heap is not partitioned

----------------------------------
---- TRUNCATE---------------
----------------------------------

--OPTION1
TRUNCATE TABLE alignedTable1 WITH (PARTITIONS (2))
--succeeds

--OPTION2
TRUNCATE TABLE nonAlignedTable1 WITH (PARTITIONS (2))
/*
Msg 3756, Level 16, State 1, Line 367
TRUNCATE TABLE statement failed. Index 'NCIX_nonAlignedTable1' is not partitioned, but table 'nonAlignedTable1' uses partition function 'pf1'. Index and table must use an equivalent partition function.
*/
--disable the non-aligned indexe and reattempt:
alter index NCIX_nonAlignedTable1 on nonAlignedTable1 DISABLE;
TRUNCATE TABLE nonAlignedTable1 WITH (PARTITIONS (2))
--it now succeeds
--go back and re-enable indexes
alter index NCIX_nonAlignedTable1 on nonAlignedTable1 REBUILD;
select name, is_disabled, type_desc
from sys.indexes where object_id in (object_id('dbo.nonAlignedTable1'),
	object_id('dbo.nonAlignedTable2'),
	object_id('dbo.staging1'))

--OPTION3
TRUNCATE TABLE nonAlignedTable2 WITH (PARTITIONS (2))
TRUNCATE TABLE nonAlignedTable2
/*
Msg 7729, Level 16, State 3, Line 375
Cannot specify partition number in the truncate table statement as the table 'nonAlignedTable2' is not partitioned.
*/

----------------------------------
---- REBUILD/REORG ---------------
----------------------------------

-- REORGANIZE a specific partition  
ALTER INDEX pk_alignedTable1 ON alignedTable1 REORGANIZE PARTITION = 2;  
ALTER INDEX NCIX_alignedTable1 ON alignedTable1 REORGANIZE PARTITION = 2;  

ALTER INDEX pk_nonAlignedTable1 ON nonAlignedTable1 REORGANIZE PARTITION = 2;  
-- since the non-clustered index is not partitioned this would fail, as expected:
ALTER INDEX NCIX_nonAlignedTable1 ON nonAlignedTable1 REORGANIZE PARTITION = 2;  --fails with err 7729

-- since the clustered index is not partitioned this would fail, as expected:
ALTER INDEX pk_nonAlignedTable2 ON nonAlignedTable2 REORGANIZE PARTITION = 2;  --fails with err 7729
ALTER INDEX NCIX_nonAlignedTable2 ON nonAlignedTable2 REORGANIZE PARTITION = 2;  


-- REBUILD a specific partition  
ALTER INDEX pk_alignedTable1 ON alignedTable1 REBUILD PARTITION = 2;  
ALTER INDEX NCIX_alignedTable1 ON alignedTable1 REBUILD PARTITION = 2;  

ALTER INDEX pk_nonAlignedTable1 ON nonAlignedTable1 REBUILD PARTITION = 2;  
-- since the non-clustered index is not partitioned this would fail, as expected:
ALTER INDEX NCIX_nonAlignedTable1 ON nonAlignedTable1 REBUILD PARTITION = 2;  --fails with err 7729

-- since the clustered index is not partitioned this would fail, as expected:
ALTER INDEX pk_nonAlignedTable2 ON nonAlignedTable2 REBUILD PARTITION = 2;  --fails with err 7729
ALTER INDEX NCIX_nonAlignedTable2 ON nonAlignedTable2 REBUILD PARTITION = 2;  

---------------------------------------------------------------
-------- Metadata Queries                  --------------------
---------------------------------------------------------------

-- QryA: view rows in partition
select distinct sch.name, o.name tablename, i.name indexname, p.partition_number, p.rows, f.name
from sys.destination_data_spaces DS
join sys.filegroups F on F.data_space_id = DS.data_space_id
join sys.partition_schemes ps on ps.data_space_id = DS.partition_scheme_id
join sys.indexes i on i.data_space_id = DS.partition_scheme_id
INNER JOIN sys.objects o ON o.object_id=i.object_id
join sys.schemas sch on sch.schema_id = o.schema_id
join sys.partitions p on p.object_id = i.object_id and i.index_id = p.index_id and p.partition_number = DS.destination_id
WHERE sch.name in ('dbo')  and o.name in ('alignedTable1','nonAlignedTable1')

-- QryB: view boundary values and which partition the value belongs to
SELECT 
    PF.function_id   , PF.name   , PF.fanout AS NumPartitions
  , CASE WHEN PF.boundary_vALue_on_right = 0 
      THEN 'LEFT' ELSE 'RIGHT' END AS RangeType
  , PRV.boundary_id   , PRV.vALue
  , CASE WHEN PF.boundary_vALue_on_right = 0 
      THEN PRV.boundary_id ELSE PRV.boundary_id + 1 END AS PartitionNumber
FROM sys.partition_functions AS PF
JOIN sys.partition_range_vALues AS PRV 
	ON PF.function_id = PRV.function_id 


-- QryC: View list of index columns for each index on the table
select sch.name,  object_name(ic.object_id) tablename, i.name indexname,  ic.index_id, ic.index_column_id,  c.name as keyCol
from sys.index_columns ic
join sys.indexes i on ic.object_id = i.object_id
join sys.objects o on ic.object_id = o.object_id
JOIN sys.schemas sch on sch.schema_id = o.schema_id
join sys.all_columns c on ic.object_id = c.object_id and ic.column_id = c.column_id
WHERE sch.name in ('dbo')  and o.name in ('alignedTable1','nonAlignedTable1')

-- QryD: view primary key constraint
select object_name(o.parent_object_id) parenttablename, kc.type_desc, kc.name
from sys.key_constraints kc 
join sys.objects o on o.object_id = kc.object_id
JOIN sys.schemas sch on sch.schema_id = o.schema_id
WHERE sch.name in ('dbo')  and object_name(o.parent_object_id) in ('alignedTable1','nonAlignedTable1')
