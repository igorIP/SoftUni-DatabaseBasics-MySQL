#Exercises: Subqueries and JOINs

use soft_uni;

#1. Employee Address

select	e.employee_id,
		e.job_title,
        a.address_id,
        a.address_text
from employees as `e`
join addresses as `a`
on e.address_id = a.address_id
order by e.address_id
limit 5;


#2.Addresses with Towns

select	e.first_name,
		e.last_name,
        t.name town,
        a.address_text
	from employees as `e`
	join addresses as `a`
    on e.address_id = a.address_id
	join towns as `t`
    on a.town_id = t.town_id
	order by e.first_name, e.last_name
	limit 5;
	
     
#3.Sales Employee

select	e.employee_id,
		e.first_name,
        e.last_name,
        d.name department_name
		from employees as `e`
        join departments as `d`
        on e.department_id = d.department_id
        where d.name = 'Sales'
        order by e.employee_id desc;
	

#4.Employee Departments

select	e.employee_id,
		e.first_name,
        e.salary,
        d.name department_name
	from employees as `e`
	join departments as `d`
	on e.department_id = d.department_id
    where salary > 15000
    order by d.department_id desc
    limit 5;
    
    
#5.Employees Without Project

select	e.employee_id,
		ep.project_id,
		e.first_name
		from employees as `e`
		left join employees_projects as `ep`
        on e.employee_id = ep.employee_id
        where ep.project_id is null
        order by e.employee_id desc
		limit 3;
		
        
#6.Employees Hired After

select	e.first_name, e.last_name,e.hire_date,d.name dept_name
        from employees as `e`
		join departments as `d` on e.department_id = d.department_id
        where d.name in ('Sales', 'Finance')
			and date(e.hire_date) > "1999/1/1 00:00:00.000000"
        order by e.hire_date asc;
        
        
#7. Employees with Project    

select	e.employee_id,
		e.first_name,
        p.name project_name
		from employees as `e`
		join employees_projects as `ep`
        on e.employee_id = ep.employee_id
		join projects as `p`
        on ep.project_id = p.project_id
		where p.end_date is null 
        and date(p.start_date) > '2002-08-13 00:00:00.000000'
        order by e.first_name , p.name 
        limit 5; 
        
        
#8. Employee 24

select
	e.employee_id,
	e.first_name,
	if(year(p.start_date) >= 2005,
		null,
		p.name) as project_name
from 
	employees as `e`
		join 
	employees_projects as `ep` on e.employee_id = ep.employee_id
		join
	projects as `p` on ep.project_id = p.project_id
where
	e.employee_id = 24
order by p.name;


#9.Employee Manager

select
	e.employee_id,
    e.first_name,
    e.manager_id,
    em.first_name as manager_name
from
	employees as `e`
		 join
	employees as `em` on e.manager_id = em.employee_id
where
	e.manager_id in (3,7)
order by e.first_name;


#10. Employee Summary

select
    e.employee_id,
    concat(e.first_name, ' ', e.last_name) as employee_name,
    concat(em.first_name, ' ', em.last_name ) as manager_name,
    d.name as department_name
from 
	employees as `e` 
		join
	employees as`em` on e.manager_id = em.employee_id
		join
	departments as `d` on e.department_id = d.department_id
    order by e.employee_id
    limit 5;
    
    
#11.Min Average Salary

select min(min_average_salary) as min_average_salary
from
	(
    select  
	avg(e.salary) as min_average_salary
    from
	employees as `e`
	group by e.department_id
    ) as `e`;
    
    
#12. Highest Peaks in Bulgaria   

select
	c.country_code,
	m.mountain_range,
    p.peak_name,
    p.elevation
from countries as `c`
		join	
	mountains_countries as `mc` on c.country_code = mc.country_code
		join
	mountains as `m` on mc.mountain_id = m.id
		join
        peaks as `p` on m.id = p.mountain_id
where 
	c.country_code = 'BG' and p.elevation > 2835
order by p.elevation desc;


#13.Count Mointain Ranges

select 
	c.country_code,
    count(*) as mountain_range
from
	countries as `c`
		join
	mountains_countries as `mc` on c.country_code = mc.country_code
		join 
	mountains as `m` on mc.mountain_id = m.id
where 
	c.country_code in ('BG', 'US', 'RU')
group by 
	c.country_code
order by mountain_range desc;


#14.Countries With Rivers

select 
	c.country_name,
    r.river_name
from countries as `c`
	left join 
countries_rivers as `cr` on c.country_code = cr.country_code
	left join
rivers as `r` on cr.river_id = r.id
where c.continent_code = 'AF'
order by c.country_name
limit 5;


#15.*Continents and Currencies

select
	c.continent_code,
    c.currency_code,
	count(*) currency_usage
from
	countries c 
group by c.currency_code, c.continent_code
having currency_usage > 1
and currency_usage  = (
	select 
        count(*) cn
    from
        countries  c2
    where
        c2.continent_code = c.continent_code
    group by c2.currency_code
    order by cn desc
    limit 1)
order by c.continent_code, c.currency_code;
	

#16.Countries Without Mountains

SELECT COUNT(if(mc.mountain_id is null, 1, null)) as country_count
from
	countries as `c`
		left join mountains_countries as `mc` on c.country_code = mc.country_code;
		
	
#17.Highest Peak and Longest River by Country

select 
	c.country_name,
    max(p.elevation) highest_peak_elevation,
    max(r.length) longest_river_length
from
	countries as c
		left join
	mountains_countries as mp on c.country_code = mp.country_code
		left join
	peaks as p on mp.mountain_id = p.mountain_id
		left join
	countries_rivers as cr on c.country_code = cr.country_code
		left join 
	rivers as r on cr.river_id = r.id 
group by 
    c.country_name
order by 
	highest_peak_elevation desc,longest_river_length desc, c.country_name
limit 5;
        
        
        
        
        
        
