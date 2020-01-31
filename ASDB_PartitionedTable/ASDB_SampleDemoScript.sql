--view rows in partition
select distinct sch.name, o.name tablename, i.name indexname, p.partition_number, p.rows, f.name
from sys.destination_data_spaces DS
join sys.filegroups F on F.data_space_id = DS.data_space_id
join sys.partition_schemes ps on ps.data_space_id = DS.partition_scheme_id
join sys.indexes i on i.data_space_id = DS.partition_scheme_id
INNER JOIN sys.objects o ON o.object_id=i.object_id
join sys.schemas sch on sch.schema_id = o.schema_id
join sys.partitions p on p.object_id = i.object_id and i.index_id = p.index_id and p.partition_number = DS.destination_id
WHERE sch.name in ('dbo')  and o.name = 'TABLE1'

-- view boundary values and which partition the value belongs to
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


-- View list of index columns for each index on the table
select sch.name,  object_name(ic.object_id) tablename, i.name indexname,  ic.index_id, ic.index_column_id,  c.name as keyCol
from sys.index_columns ic
join sys.indexes i on ic.object_id = i.object_id
join sys.objects o on ic.object_id = o.object_id
JOIN sys.schemas sch on sch.schema_id = o.schema_id
join sys.all_columns c on ic.object_id = c.object_id and ic.column_id = c.column_id
WHERE sch.name in ('dbo')  and o.name = 'TABLE1'

--view primary key constraint
select object_name(o.parent_object_id) parenttablename, kc.type_desc, kc.name
from sys.key_constraints kc 
join sys.objects o on o.object_id = kc.object_id
JOIN sys.schemas sch on sch.schema_id = o.schema_id
WHERE sch.name in ('dbo')  and o.name = 'PK_TABLE1'

--view partitioncol distribution
SELECT   datepart(yy, partitioncol) pYear,datepart(mm, partitioncol) pMonth, count(*) as numrows
	FROM [dbo].[TABLE1]
group by datepart(yy, partitioncol), datepart(mm, partitioncol)
order by datepart(yy, partitioncol) desc, datepart(mm, partitioncol) desc



-- Step1: Create Partition Function **********************

--drop PARTITION FUNCTION [pf1]
--Range right so boundary value falls to the partition to the right

CREATE PARTITION FUNCTION [pf1] (DATE) AS RANGE RIGHT FOR VALUES    (
	 -- partiton1 is everything < 6/1/1998
	 '6/1/1998', --parititon2 >= 6/1/1998 & < 7/1/1998
	 '7/1/1998',--parititon3 >= 7/1/1998 & < today's date
	 getdate() -- partition4 >= today's date
	 );


--$PARTITION helper function
select $PARTITION.[pf1]('5/4/1998') --p1
select $PARTITION.[pf1]('6/5/1998') --p2
select $PARTITION.[pf1]('7/5/1998') --p3
go
declare @dt date = getdate();
select @dt,  $PARTITION.[pf1](@dt) --p4
--one day after:
declare @dt2 date = dateadd(dd, 1, @dt)
select @dt2,  $PARTITION.[pf1](@dt2) --p4
--one day before:
declare @dt3 date = dateadd(dd, -1, @dt)
select @dt3,  $PARTITION.[pf1](@dt3) --p4
go

-- Step2: Create Parition Schem  **************************************

-- Unlike on-prem SQL Server, in ASDB Single database, you cannot control FG placement so just choose PRIMARY filegroup
-- Create the partition scheme
--drop partition scheme sch1
CREATE PARTITION SCHEME sch1 AS PARTITION [pf1]
	ALL TO ([PRIMARY]);
GO


-- Step 3: Create non-partitioned table. In this example we will partition the clustered index *******************


-- Create non-partitioned table first
--drop table TABLE1
CREATE TABLE [dbo].[TABLE1] 
([pkcol] [int] NOT NULL,
 [datacol] [int] NULL,
 [partitioncol] date not null)
GO
--add pk clustered index
ALTER TABLE dbo.TABLE1 ADD CONSTRAINT PK_TABLE1 PRIMARY KEY CLUSTERED (pkcol) 
GO
-- Populate table
DECLARE @val INT
SELECT @val=1
WHILE @val <=1000
BEGIN  
   INSERT INTO dbo.Table1(pkcol, datacol, partitioncol) VALUES (@val, @val, '7/5/1998')
   set @val = @val + 1
END
GO

--Step 4: Convert nonpartitioned table to partitioned. In this example we will partition the clustered index.

--drop the non-partitioned clustered index, we will create a new partitioned index
ALTER TABLE dbo.TABLE1 DROP CONSTRAINT PK_TABLE1 -- must drop cluIdx to recreate
GO

-- https://docs.microsoft.com/en-us/sql/relational-databases/partitions/partitioned-tables-and-indexes?view=sql-server-ver15#partitioning-clustered-indexes
-- cluIdx clustering key must contain the partitioning column, sql will silently add it as key column not explicitly specified
-- if cluIdx is unique, you must explicitly specify that the clustered index key contain the partitioning column.

--drop index IX_TABLE1_partitioncol  ON dbo.TABLE1
ALTER TABLE dbo.TABLE1 ADD CONSTRAINT PK_TABLE1 PRIMARY KEY CLUSTERED  (pkcol,partitioncol) ON sch1(partitioncol)

/* If clustered index is not a primary key, can create a clustered index as follows:
CREATE unique CLUSTERED INDEX IX_TABLE1_partitioncol ON dbo.TABLE1 (pkcol,partitioncol)
  ON sch1(partitioncol)
*/
GO


--Step5: Add new data *****************************************************
DECLARE @val INT
declare @startingPK int
select @startingPK = MAX(pkcol) + 1 from table1
SELECT @val = @startingPK
WHILE @val < @startingPK + 30
BEGIN  
   INSERT INTO dbo.Table1(pkcol, datacol, partitioncol) VALUES (@val, @val, '1/31/2020')
   set @val = @val + 1
END
go


--Step5: Add a new partition  *****************************************************
alter partition scheme sch1 next used [primary]; -- should not need in ASDB but may fail  without it
ALTER PARTITION FUNCTION pf1() SPLIT RANGE ('11/30/2020') 
go


--partition switch steps:
--create staging table in same filegroup (PRIMARY filegroup in case of ASDB single db)
--split most recent partition by adding boundary point
--bulk load and index staging table
--switch data into next to last partition


