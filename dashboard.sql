/* запрос для определения общего количества уникальных пользователей, которые посетили сайт */

select
	count(distinct visitor_id) as count_users
from sessions;

/* запрос для опреления общего количества посетителей сайта */

select
	count(visitor_id) as count_visitor
from sessions;

/*запрос для определения количества уникальных пользователей, которые заходили на сайт по дням */

select
	date(visit_date) as date,
	count(distinct visitor_id) as count_users
from sessions
group by 1;

/* запрос для определения каналов, которые приводят посетителей в разрезе дней */

select 
	date(date_trunc('day', visit_date)) as day,
	(case
		when source like ('vk%') then 'vk'
		when source like ('yandex%') then 'yandex'
		else 'other'
	end) as sourse,
	count(visitor_id) as count_visitors
from sessions
where medium != 'organic'
group by 1, 2
union all
select
	date(date_trunc('day', visit_date)) as day,
	(case
		when medium = 'organic' then 'organic'
	end) as source,
	count(visitor_id) as count_visitors
from sessions
where (case
		when medium = 'organic' then 'organic'
	end) is not null
group by 1, 2
order by 1;

/* запрос для определения каналов, которые приводят посетителей по неделям */

select 
	date(date_trunc('week', visit_date)) as week,
	(case
		when source like ('vk%') then 'vk'
		when source like ('yandex%') then 'yandex'
		else 'other'
	end) as sourse,
	count(visitor_id) as count_visitors
from sessions
where medium != 'organic'
group by 1, 2
union all
select
	date(date_trunc('week', visit_date)) as week,
	(case
		when medium = 'organic' then 'organic'
	end) as source,
	count(visitor_id) as count_visitors
from sessions
where (case
		when medium = 'organic' then 'organic'
	end) is not null
group by 1, 2
order by 1;

/* запрос для определения каналов, которые приводят посетителей за месяц */

select 
	date(date_trunc('month', visit_date)) as month,
	(case
		when source like ('vk%') then 'vk'
		when source like ('yandex%') then 'yandex'
		else 'other'
	end) as sourse,
	count(visitor_id) as count_visitors
from sessions
where medium != 'organic'
group by 1, 2
union all
select
	date(date_trunc('month', visit_date)) as month,
	(case
		when medium = 'organic' then 'organic'
	end) as source,
	count(visitor_id) as count_visitors
from sessions
where (case
		when medium = 'organic' then 'organic'
	end) is not null
group by 1, 2;

/* запрос для определения общего количества лидов */

select
	count(lead_id) as leads_count
from leads;

/* запрос для определения конверсии из клика в лид и из лида в оплату */


