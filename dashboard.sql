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

/* запрос для определения общего количества уникальных лидов */

select
	count(distinct lead_id) as leads_count
from leads;

/* запрос для определения общего количества посещений, лидов и совершенных покупок по источникам переходов */

select
	(case
		when source like ('vk%') then 'vk'
		when source like ('yandex%') then 'yandex'
		else 'other'
	end) as source,
	count(s.visitor_id) as count_visitors,
	count(l.lead_id) as count_leads,
	count(case
		when l.status_id = 142 then l.lead_id 
	end
	) as count_purchases
	from sessions as s
	left join leads as l on s.visitor_id = l.visitor_id 
where medium != 'organic'
group by 1
union all
select 
	(case
		when medium = 'organic' then 'organic'
	end) as source,
	count(s.visitor_id) as count_visitors,
	count(l.lead_id) as count_leads,
	count(case
		when l.status_id = 142 then l.lead_id 
	end
	) as count_purchases
	from sessions as s
	left join leads as l on s.visitor_id = l.visitor_id 
where (case
		when medium = 'organic' then 'organic'
	end) is not null
group by 1

/* запрос для определения конверсии из клика в лид, из лида в оплату и из клика в оплату */

with tab as (
select
	(case
		when source like ('vk%') then 'vk'
		when source like ('yandex%') then 'yandex'
		else 'other'
	end) as source,
	count(s.visitor_id) as count_visitors,
	count(l.lead_id) as count_leads,
	count(case
		when l.status_id = 142 then l.lead_id 
	end
	) as count_purchases
	from sessions as s
	left join leads as l on s.visitor_id = l.visitor_id 
where medium != 'organic'
group by 1
union all
select 
	(case
		when medium = 'organic' then 'organic'
	end) as source,
	count(s.visitor_id) as count_visitors,
	count(l.lead_id) as count_leads,
	count(case
		when l.status_id = 142 then l.lead_id 
	end
	) as count_purchases
	from sessions as s
	left join leads as l on s.visitor_id = l.visitor_id 
where (case
		when medium = 'organic' then 'organic'
	end) is not null
group by 1
)
select
	tab.source,
	round(((tab.count_leads * 100.00) / tab.count_visitors), 2) as conv_visit_to_lead,
	round(((tab.count_purchases * 100.00) / tab.count_leads), 2) as conv_lead_to_purchases,
	round(((tab.count_purchases * 100.00) / tab.count_visitors), 2) conv_visit_to_purchases
from tab

/* запрос для определения затрат по каналам: yandex и vk в динамике по дням */

SELECT
        DATE(campaign_date) AS campaign_date,
        utm_source,
        utm_medium,
        utm_campaign,
        SUM(daily_spent) AS total_cost
    FROM vk_ads
    GROUP BY 1, 2, 3, 4
    UNION ALL
    SELECT
        DATE(campaign_date),
        utm_source,
        utm_medium,
        utm_campaign,
        SUM(daily_spent)
    FROM ya_ads
    GROUP BY 1, 2, 3, 4

