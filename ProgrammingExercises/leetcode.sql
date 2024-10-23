/*
Leetcode solution: https://leetcode.com/problems/department-top-three-salaries/solutions/5194119/performant-solution-using-dense-rank-to-sequentially-rank-by-department-and-salary/

    This SQL query retrieves the top 3 employees with the highest salary in each department.
    It uses the DENSE_RANK() function to assign sequential ranks to employees within each department based on their salary.
    The result includes the department name, employee name, and employee salary.
    The query joins the Employee and Department tables based on the departmentId column.
    Only the employees with ranks less than or equal to 3 are included in the result.
*/

select  d.name as Department,  e1.name as Employee, e1.salary as Salary from
(
    select *, dense_rank() over(
        partition by departmentId
        order by salary desc) rownum
    from Employee
 ) e1
join Department d
on  e1.departmentId=d.Id
where e1.rownum <=3



