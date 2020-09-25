/*
*** Warning this script drops and creates the dbo.Department and dbo.DepartmentHistory tables

This script demonstrates methods to group sets of intervals of sequential date data. 
For example, say you want to find every time the manager for a department changed.

DeptID	ManagerID	DeptName	SysStartTime	SysEndTime
10	100	Production	2020-09-25 17:57:00.2263833	2020-09-25 17:57:06.8827115
10	100	Dept A	2020-09-25 17:57:06.8827115	2020-09-25 17:57:06.9608716
10	100	Dept B	2020-09-25 17:57:06.9608716	2020-09-25 17:57:07.0389641
10	100	Dept C	2020-09-25 17:57:07.0389641	2020-09-25 17:57:07.1170614
10	100	Dept D	2020-09-25 17:57:07.1170614	2020-09-25 17:57:07.1952132
10	100	Dept E	2020-09-25 17:57:07.1952132	2020-09-25 17:57:07.2733118
10	100	Dept F	2020-09-25 17:57:07.2733118	2020-09-25 17:57:07.3514368
10	110	Dept F	2020-09-25 17:57:07.3514368	2020-09-25 17:57:16.1015601
10	110	Dept A	2020-09-25 17:57:16.1015601	2020-09-25 17:57:16.1796965
10	110	Dept B	2020-09-25 17:57:16.1796965	2020-09-25 17:57:16.2578201
10	110	Dept C	2020-09-25 17:57:16.2578201	2020-09-25 17:57:16.3359702
10	110	Dept D	2020-09-25 17:57:16.3359702	2020-09-25 17:57:16.4140748
10	110	Dept E	2020-09-25 17:57:16.4140748	2020-09-25 17:57:16.4765744
10	110	Dept F	2020-09-25 17:57:16.4765744	2020-09-25 17:57:16.5547558
10	120	Dept F	2020-09-25 17:57:16.5547558	2020-09-25 17:57:30.3205488
10	120	Dept A	2020-09-25 17:57:30.3205488	2020-09-25 17:57:30.3986717
10	120	Dept B	2020-09-25 17:57:30.3986717	2020-09-25 17:57:30.4611860
10	120	Dept C	2020-09-25 17:57:30.4611860	2020-09-25 17:57:30.5393075
10	120	Dept D	2020-09-25 17:57:30.5393075	2020-09-25 17:57:30.6174314
10	120	Dept E	2020-09-25 17:57:30.6174314	2020-09-25 17:57:30.6955560
10	120	Dept F	2020-09-25 17:57:30.6955560	2020-09-25 17:57:30.7736779
10	130	Dept F	2020-09-25 17:57:30.7736779	2020-09-25 17:57:39.9769075
10	130	Dept A	2020-09-25 17:57:39.9769075	2020-09-25 17:57:40.0550381
10	130	Dept B	2020-09-25 17:57:40.0550381	2020-09-25 17:57:40.1331569
10	130	Dept C	2020-09-25 17:57:40.1331569	2020-09-25 17:57:40.1956434
10	130	Dept D	2020-09-25 17:57:40.1956434	2020-09-25 17:57:40.2737688
10	130	Dept E	2020-09-25 17:57:40.2737688	2020-09-25 17:57:40.3519043
10	130	Dept F	2020-09-25 17:57:40.3519043	2020-09-25 17:57:40.4300562
10	140	Dept F	2020-09-25 17:57:40.4300562	2020-09-25 17:57:48.4613802
10	140	Dept A	2020-09-25 17:57:48.4613802	2020-09-25 17:57:48.5395261
10	140	Dept B	2020-09-25 17:57:48.5395261	2020-09-25 17:57:48.6176392
10	140	Dept C	2020-09-25 17:57:48.6176392	2020-09-25 17:57:48.6957635
10	140	Dept D	2020-09-25 17:57:48.6957635	2020-09-25 17:57:48.7739243
10	140	Dept E	2020-09-25 17:57:48.7739243	2020-09-25 17:57:48.8364328
10	140	Dept F	2020-09-25 17:57:48.8364328	2020-09-25 17:57:48.9145200
10	150	Dept F	2020-09-25 17:57:48.9145200	2020-09-25 17:58:06.2741688
10	150	Dept A	2020-09-25 17:58:06.2741688	2020-09-25 17:58:06.3522861
10	150	Dept B	2020-09-25 17:58:06.3522861	2020-09-25 17:58:06.4304151
10	150	Dept C	2020-09-25 17:58:06.4304151	2020-09-25 17:58:06.5085559
10	150	Dept D	2020-09-25 17:58:06.5085559	2020-09-25 17:58:06.5710375
10	150	Dept E	2020-09-25 17:58:06.5710375	2020-09-25 17:58:06.6491772
10	150	Dept F	2020-09-25 17:58:06.6491772	2020-09-25 17:58:06.7272939
10	120	Dept F	2020-09-25 17:58:06.7272939	2020-09-25 17:58:11.7273296
10	120	Dept A	2020-09-25 17:58:11.7273296	2020-09-25 17:58:11.7898402
10	120	Dept B	2020-09-25 17:58:11.7898402	2020-09-25 17:58:11.8679718
10	120	Dept C	2020-09-25 17:58:11.8679718	2020-09-25 17:58:11.9460798
10	120	Dept D	2020-09-25 17:58:11.9460798	2020-09-25 17:58:12.0242776
10	120	Dept E	2020-09-25 17:58:12.0242776	2020-09-25 17:58:12.1023790
10	120	Dept F	2020-09-25 17:58:12.1023790	2020-09-25 17:58:12.1804941
10	130	Dept F	2020-09-25 17:58:12.1804941	9999-12-31 23:59:59.9999999


Desired output should be:
DeptID	ManagerID	mindt	maxdt
10	100	2020-09-25 17:57:00.2263833	2020-09-25 17:57:07.3514368
10	110	2020-09-25 17:57:07.3514368	2020-09-25 17:57:16.5547558
10	120	2020-09-25 17:57:16.5547558	2020-09-25 17:57:30.7736779
10	130	2020-09-25 17:57:30.7736779	2020-09-25 17:57:40.4300562
10	140	2020-09-25 17:57:40.4300562	2020-09-25 17:57:48.9145200
10	150	2020-09-25 17:57:48.9145200	2020-09-25 17:58:06.7272939
10	120	2020-09-25 17:58:06.7272939	2020-09-25 17:58:12.1804941
10	130	2020-09-25 17:58:12.1804941	9999-12-31 23:59:59.9999999


Reference:
https://docs.microsoft.com/en-us/sql/relational-databases/tables/creating-a-system-versioned-temporal-table?view=sql-server-ver15#creating-a-temporal-table-with-a-default-history-table

- New Solution to the Packing Intervals Problem https://www.itprotoday.com/sql-server/new-solution-packing-intervals-problem
*/


--Cleanup
/*
alter table dbo.Department SET (SYSTEM_VERSIONING = OFF)
drop table dbo.Department
drop table dbo.DepartmentHistory
*/

-----------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
-- STEP1: Create and populate the table. Two tables, Department and DepartmentHistory will be created
-----------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------

CREATE TABLE Department
(
    DeptID INT NOT NULL PRIMARY KEY CLUSTERED
  , DeptName VARCHAR(50) NOT NULL
  , ManagerID INT NULL
  , ParentDeptID INT NULL
  , SysStartTime DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL
  , SysEndTime DATETIME2 GENERATED ALWAYS AS ROW END NOT NULL
  , PERIOD FOR SYSTEM_TIME (SysStartTime, SysEndTime)
)
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.DepartmentHistory));

-- insert initial rows
INSERT INTO [dbo].[Department]  VALUES(10, 'Production', 100, 1, default, default);
INSERT INTO [dbo].[Department]  VALUES(11, 'Production', 101, 1, default, default);
INSERT INTO [dbo].[Department]  VALUES(12, 'Production', 102, 1, default, default);
GO

-----------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
--STEP2: Update rows  - this will add changes to history table
-----------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------

GO
Update dbo.Department set DeptName = 'Dept A' where DeptID  = 10
GO -- *** WARNING If you don't put the batch separator, updates will be processed as an entire batch so you will only see last batch change ***
Update dbo.Department set DeptName = 'Dept B' where DeptID  = 10
GO
Update dbo.Department set DeptName = 'Dept C' where DeptID  = 10
GO
Update dbo.Department set DeptName = 'Dept D' where DeptID  = 10
GO
Update dbo.Department set DeptName = 'Dept E' where DeptID  = 10
GO
Update dbo.Department set DeptName = 'Dept F' where DeptID  = 10
GO
Update dbo.Department set ManagerID = 110 where DeptID = 10
GO
Update dbo.Department set DeptName = 'Dept A' where DeptID  = 11
GO
Update dbo.Department set DeptName = 'Dept B' where DeptID  = 11
GO
Update dbo.Department set DeptName = 'Dept C' where DeptID  = 11
GO
Update dbo.Department set DeptName = 'Dept D' where DeptID  = 11
GO
Update dbo.Department set DeptName = 'Dept E' where DeptID  = 11
GO
Update dbo.Department set DeptName = 'Dept F' where DeptID  = 11
GO
Update dbo.Department set ManagerID = 111 where DeptID = 11


GO
Update dbo.Department set DeptName = 'Dept A' where DeptID  = 10
GO
Update dbo.Department set DeptName = 'Dept B' where DeptID  = 10
GO
Update dbo.Department set DeptName = 'Dept C' where DeptID  = 10
GO
Update dbo.Department set DeptName = 'Dept D' where DeptID  = 10
GO
Update dbo.Department set DeptName = 'Dept E' where DeptID  = 10
GO
Update dbo.Department set DeptName = 'Dept F' where DeptID  = 10
GO
Update dbo.Department set ManagerID = 120 where DeptID = 10
GO
Update dbo.Department set DeptName = 'Dept A' where DeptID  = 11
GO
Update dbo.Department set DeptName = 'Dept B' where DeptID  = 11
GO
Update dbo.Department set DeptName = 'Dept C' where DeptID  = 11
GO
Update dbo.Department set DeptName = 'Dept D' where DeptID  = 11
GO
Update dbo.Department set DeptName = 'Dept E' where DeptID  = 11
GO
Update dbo.Department set DeptName = 'Dept F' where DeptID  = 11
GO
Update dbo.Department set ManagerID = 121 where DeptID = 11


GO
Update dbo.Department set DeptName = 'Dept A' where DeptID  = 10
GO
Update dbo.Department set DeptName = 'Dept B' where DeptID  = 10
GO
Update dbo.Department set DeptName = 'Dept C' where DeptID  = 10
GO
Update dbo.Department set DeptName = 'Dept D' where DeptID  = 10
GO
Update dbo.Department set DeptName = 'Dept E' where DeptID  = 10
GO
Update dbo.Department set DeptName = 'Dept F' where DeptID  = 10
GO
Update dbo.Department set ManagerID = 130 where DeptID = 10
GO
Update dbo.Department set DeptName = 'Dept A' where DeptID  = 11
GO
Update dbo.Department set DeptName = 'Dept B' where DeptID  = 11
GO
Update dbo.Department set DeptName = 'Dept C' where DeptID  = 11
GO
Update dbo.Department set DeptName = 'Dept D' where DeptID  = 11
GO
Update dbo.Department set DeptName = 'Dept E' where DeptID  = 11
GO
Update dbo.Department set DeptName = 'Dept F' where DeptID  = 11
GO
Update dbo.Department set ManagerID = 131 where DeptID = 11


GO
Update dbo.Department set DeptName = 'Dept A' where DeptID  = 10
GO
Update dbo.Department set DeptName = 'Dept B' where DeptID  = 10
GO
Update dbo.Department set DeptName = 'Dept C' where DeptID  = 10
GO
Update dbo.Department set DeptName = 'Dept D' where DeptID  = 10
GO
Update dbo.Department set DeptName = 'Dept E' where DeptID  = 10
GO
Update dbo.Department set DeptName = 'Dept F' where DeptID  = 10
GO
Update dbo.Department set ManagerID = 140 where DeptID = 10
GO
Update dbo.Department set DeptName = 'Dept A' where DeptID  = 11
GO
Update dbo.Department set DeptName = 'Dept B' where DeptID  = 11
GO
Update dbo.Department set DeptName = 'Dept C' where DeptID  = 11
GO
Update dbo.Department set DeptName = 'Dept D' where DeptID  = 11
GO
Update dbo.Department set DeptName = 'Dept E' where DeptID  = 11
GO
Update dbo.Department set DeptName = 'Dept F' where DeptID  = 11
GO
Update dbo.Department set ManagerID = 141 where DeptID = 11

GO
Update dbo.Department set DeptName = 'Dept A' where DeptID  = 10
GO
Update dbo.Department set DeptName = 'Dept B' where DeptID  = 10
GO
Update dbo.Department set DeptName = 'Dept C' where DeptID  = 10
GO
Update dbo.Department set DeptName = 'Dept D' where DeptID  = 10
GO
Update dbo.Department set DeptName = 'Dept E' where DeptID  = 10
GO
Update dbo.Department set DeptName = 'Dept F' where DeptID  = 10
GO
Update dbo.Department set ManagerID = 150 where DeptID = 10
GO
Update dbo.Department set DeptName = 'Dept A' where DeptID  = 11
GO
Update dbo.Department set DeptName = 'Dept B' where DeptID  = 11
GO
Update dbo.Department set DeptName = 'Dept C' where DeptID  = 11
GO
Update dbo.Department set DeptName = 'Dept D' where DeptID  = 11
GO
Update dbo.Department set DeptName = 'Dept E' where DeptID  = 11
GO
Update dbo.Department set DeptName = 'Dept F' where DeptID  = 11
GO
Update dbo.Department set ManagerID = 151 where DeptID = 11

GO
Update dbo.Department set DeptName = 'Dept A' where DeptID  = 12
GO
Update dbo.Department set DeptName = 'Dept B' where DeptID  = 12
GO
Update dbo.Department set DeptName = 'Dept C' where DeptID  = 12
GO
Update dbo.Department set DeptName = 'Dept D' where DeptID  = 12
GO
Update dbo.Department set DeptName = 'Dept E' where DeptID  = 12
GO
Update dbo.Department set DeptName = 'Dept F' where DeptID  = 12
GO
Update dbo.Department set ManagerID = 152 where DeptID = 12
GO


--repeat to demonstrate duplicate manager id entries (for example department switched  from mgr1 to mgr2 and at a later point back to mgr1)
GO
Update dbo.Department set DeptName = 'Dept A' where DeptID  = 10
GO
Update dbo.Department set DeptName = 'Dept B' where DeptID  = 10
GO
Update dbo.Department set DeptName = 'Dept C' where DeptID  = 10
GO
Update dbo.Department set DeptName = 'Dept D' where DeptID  = 10
GO
Update dbo.Department set DeptName = 'Dept E' where DeptID  = 10
GO
Update dbo.Department set DeptName = 'Dept F' where DeptID  = 10
GO
Update dbo.Department set ManagerID = 120 where DeptID = 10
GO




Update dbo.Department set DeptName = 'Dept A' where DeptID  = 10
GO
Update dbo.Department set DeptName = 'Dept B' where DeptID  = 10
GO
Update dbo.Department set DeptName = 'Dept C' where DeptID  = 10
GO
Update dbo.Department set DeptName = 'Dept D' where DeptID  = 10
GO
Update dbo.Department set DeptName = 'Dept E' where DeptID  = 10
GO
Update dbo.Department set DeptName = 'Dept F' where DeptID  = 10
GO
Update dbo.Department set ManagerID = 130 where DeptID = 10


-----------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
--STEP3: Interval packing - Opt1
-----------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------

--Find each time ManagerId changes (DeptId = PK)
;with cte1
 as
(
select DeptID, ManagerID, SysStartTime, SysEndTime
    ,LAG(ManagerID, 1, null) OVER (ORDER BY SysStartTime) as prevManager --for each sequential date row, get prev manager id
    ,LEAD(ManagerID, 1, null) OVER (ORDER BY SysStartTime) as nextManager --for each sequential date row, get next manager id
from dbo.Department for SYSTEM_TIME ALL
where DeptId  = 10
), cte2 as
--select * from cte1 order by SysStartTime
(
select DeptID, ManagerID, SysStartTime, SysEndTime
    ,ROW_NUMBER() over (ORDER BY SysStartTime ) rn
from cte1
where   prevManager <> ManagerID or prevManager is null --first startdate
    or nextManager <> ManagerID or nextManager is null --last enddate
)
select distinct DeptID, ManagerID --, SysStartTime, SysEndTime, rn
, mindt = (select MIN(SysStartTime)
    from cte2 B
    where B.ManagerID = A.ManagerID and (B.rn=A.rn or B.rn=A.rn-1))
, maxdt = (select MAX(SysEndTime)
    from cte2 B
    where B.ManagerID = A.ManagerID and (B.rn=A.rn or B.rn=A.rn+1))
from cte2 A
order by mindt

-----------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
--STEP4: Interval packing - Opt2
-----------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------

;with cte1 as (select DeptID, ManagerID, dt, dateCategory
    ,LAG(ManagerID, 1, null) OVER (ORDER BY dt) as prevManager
    ,LEAD(ManagerID, 1, null) OVER (ORDER BY dt) as nextManager
 from
(select DeptID, ManagerID,SysStartTime, SysEndTime from dbo.Department for SYSTEM_TIME ALL) pvt
UNPIVOT
( dt FOR dateCategory in (SysStartTime,SysEndTime )) as unpvt
where DeptID = 10
) select * from cte1
where (
    prevManager <> ManagerID or prevManager is null --first startdate
    or nextManager <> ManagerID or nextManager is null) --last enddate
order by dt

-----------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
--Appendix: View all changes
-----------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------


select DeptID, ManagerID, DeptName, SysStartTime, SysEndTime
from dbo.Department for SYSTEM_TIME ALL
where DeptID=10
order by SysStartTime




