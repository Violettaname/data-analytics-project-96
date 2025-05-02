/* Расчеты метрик произведены на основе таблицы aggregate_last_paid_click, построенной по модели атрибуции Last Paid Click */
WITH tab AS (
    SELECT
        visitor_id,
        MAX(visit_date) AS last_date
    FROM sessions
    WHERE medium != 'organic'
    GROUP BY 1
),
tab2 AS (
    SELECT
        DATE(t.last_date) AS visit_date,
        s.source AS utm_source,
        s.medium AS utm_medium,
        s.campaign AS utm_campaign,
        COUNT(DISTINCT t.visitor_id) AS visitors_count,
        COUNT(l.lead_id) AS leads_count,
        COUNT(
            CASE
                WHEN
                    l.status_id = 142
                    OR l.closing_reason = 'Успешно реализовано'
                    THEN l.visitor_id
            END
        ) AS purchases_count,
        SUM(l.amount) AS revenue
    FROM tab AS t
    INNER JOIN
        sessions AS s
        ON t.visitor_id = s.visitor_id AND t.last_date = s.visit_date
    LEFT JOIN
        leads AS l
        ON s.visitor_id = l.visitor_id AND t.last_date <= l.created_at
    GROUP BY 1, 2, 3, 4
),
ads AS (
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
),
aggregate_last_paid_click as (
SELECT
    t2.visit_date,
    t2.visitors_count,
    t2.utm_source,
    t2.utm_medium,
    t2.utm_campaign,
    a.total_cost,
    t2.leads_count,
    t2.purchases_count,
    t2.revenue
FROM tab2 AS t2
LEFT JOIN ads AS a
    ON
        t2.visit_date = a.campaign_date
        AND t2.utm_source = a.utm_source
        AND t2.utm_medium = a.utm_medium
        AND t2.utm_campaign = a.utm_campaign
ORDER BY 9 DESC NULLS LAST, 1 ASC, 5 DESC, 2, 3, 4
)
	
/* Для более детального анализа в дашборде добавлены интерактивные фильтры по дате, источнику трафика, типу кампании и наименованию рекламной кампании */
/* количество посетителей, лидов, покупателей */
SELECT 
	sum(visitors_count) AS visitors,
	sum(leads_count) AS leads,
	sum(purchases_count) AS purchases
FROM aggregate_last_paid_click;

/* конверсия из клика в лид, из лида в оплату */
SELECT 
	round(sum(leads_count) * 100.00 / sum(visitors_count), 2) AS conv_click_to_lead,
	round(sum(purchases_count)*100.0/sum(leads_count), 2) AS conv_lead_to_purchase
FROM aggregate_last_paid_click;

/* выручка, затраты, CPU, CPL, CPPU, ROI */
SELECT 
	sum(revenue) AS revenue,
	sum(total_cost) AS costs,
	round(sum(total_cost) / sum(visitors_count), 2) AS cpu,
	round(sum(total_cost) / sum(leads_count), 2) AS cpl,
	round(sum(total_cost) / sum(purchases_count), 2) AS cppu
	round((SUM(revenue)-SUM(total_cost))*100.0/(SUM(total_cost)), 2) AS roi,
FROM aggregate_last_paid_click;

/* динамика посещений */
SELECT
    visit_date,
    CASE
        WHEN utm_source LIKE ('vk%') THEN 'vk'
        WHEN utm_source LIKE lower('yandex%') THEN 'yandex'
        ELSE 'other'
    END AS utm_source,
    sum(visitors_count) AS visitors
FROM aggregate_last_paid_click
GROUP BY
    visit_date, CASE
        WHEN utm_source LIKE ('vk%') THEN 'vk'
        WHEN utm_source LIKE lower('yandex%') THEN 'yandex'
        ELSE 'other'
    END
ORDER BY visitors DESC

/* источники трафика: распределение трафика по каналам */
SELECT
    CASE
        WHEN utm_source LIKE ('vk%') THEN 'vk'
        WHEN utm_source LIKE lower('yandex%') THEN 'yandex'
        ELSE 'other'
    END AS source,
    sum(visitors_count) AS visitors
FROM aggregate_last_paid_click
GROUP BY
    CASE
        WHEN utm_source LIKE ('vk%') THEN 'vk'
        WHEN utm_source LIKE lower('yandex%') THEN 'yandex'
        ELSE 'other'
    END
ORDER BY visitors DESC

/* количество лидов по каналам */
SELECT
    CASE
        WHEN utm_source LIKE ('vk%') THEN 'vk'
        WHEN utm_source LIKE lower('yandex%') THEN 'yandex'
        ELSE 'other'
    END AS source,
    sum(leads_count) AS leads
FROM aggregate_last_paid_click
GROUP BY
    CASE
        WHEN utm_source LIKE ('vk%') THEN 'vk'
        WHEN utm_source LIKE lower('yandex%') THEN 'yandex'
        ELSE 'other'
    END
ORDER BY leads DESC

/* количество посетителей, лидов, покупателей по каналам (воронка: клик --> лид --> оплата) */
SELECT
    CASE
        WHEN utm_source LIKE ('vk%') THEN 'vk'
        WHEN utm_source LIKE lower('yandex%') THEN 'yandex'
        ELSE 'other'
    END AS source,
    sum(visitors_count) AS visitors,
    sum(leads_count) AS leads,
    sum(purchases_count) AS purchases
FROM aggregate_last_paid_click
GROUP BY
    CASE
        WHEN utm_source LIKE ('vk%') THEN 'vk'
        WHEN utm_source LIKE lower('yandex%') THEN 'yandex'
        ELSE 'other'
    END
ORDER BY visitors DESC

/* Конверсии по каналам, % */
SELECT
    CASE
        WHEN utm_source LIKE ('vk%') THEN 'vk'
        WHEN utm_source LIKE lower('yandex%') THEN 'yandex'
        ELSE 'other'
    END AS sourse,
    round(sum(leads_count) * 100.00 / sum(visitors_count), 2) AS conv_click_to_lead,
    round(sum(purchases_count) * 100.0 / sum(leads_count), 2) AS conv_lead_to_purchase
FROM aggregate_last_paid_click
GROUP BY
    CASE
        WHEN utm_source LIKE ('vk%') THEN 'vk'
        WHEN utm_source LIKE lower('yandex%') THEN 'yandex'
        ELSE 'other'
    END
ORDER BY conv_click_to_lead DESC

/* общие затраты на рекламу */
select
    ya.utm_source,
    sum(ya.daily_spent) as costs
from ya_ads as ya
group by 1
union all
select
    va.utm_source,
    sum(va.daily_spent) as costs
from vk_ads as va
group by 1;

/* окупаемость рекламных кампаний*/
SELECT
    utm_campaign,
    utm_source,
    ROUND((SUM(revenue) - SUM(total_cost)) * 100.0 / (SUM(total_cost)), 2) AS source
FROM aggregate_last_paid_click
WHERE utm_source IN ('yandex', 'vk')
GROUP BY utm_campaign, utm_source
ORDER BY source DESC NULLS LAST

/* динамика окупаемости */
SELECT
    visit_date,
    ROUND((SUM(revenue) - SUM(total_cost)) * 100.0 / (SUM(total_cost)), 2) AS roi
FROM aggregate_last_paid_click
GROUP BY visit_date

/* итоговая таблица по агрегации source */
SELECT
    utm_source AS source,
    sum(visitors_count) AS visitors,
    sum(leads_count) AS leads,
    sum(purchases_count) AS purchases,
    sum(total_cost) AS cost,
    sum(revenue) AS revenue,
    round(sum(total_cost) / sum(visitors_count), 2) AS cpu,
    round(sum(total_cost) / sum(leads_count), 2) AS cpl,
    round(sum(total_cost) / sum(purchases_count), 2) AS cppu,
    round((sum(revenue) - sum(total_cost)) * 100.00 / sum(total_cost), 2) AS roi
FROM aggregate_last_paid_click
GROUP BY utm_source
ORDER BY roi DESC NULLS LAST

/* итоговая таблица по агрегации medium */
SELECT
    utm_medium AS medium,
    sum(visitors_count) AS visitors,
    sum(leads_count) AS leads,
    sum(purchases_count) AS purchases,
    sum(total_cost) AS cost,
    sum(revenue) AS revenue,
    round(sum(total_cost) / sum(visitors_count), 2) AS cpu,
    round(sum(total_cost) / sum(leads_count), 2) AS cpl,
    round(sum(total_cost) / sum(purchases_count), 2) AS cppu,
    round((sum(revenue) - sum(total_cost)) * 100.00 / sum(total_cost), 2) AS roi
FROM aggregate_last_paid_click
GROUP BY utm_medium
ORDER BY roi DESC NULLS LAST;

