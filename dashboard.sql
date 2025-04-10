/* Расчеты метрик произведены на основе таблицы aggregate_last_paid_click, построенной по модели атрибуции Last Paid Click */
/* Для более детального анализа в дашборде добавлены интерактивные фильтры по дате, источнику трафика, типу кампании и наименованию рекламной кампании, 
поэтому запросы написаны для общего вывода данных */
/* количество посетителей */
SELECT 
	sum(visitors_count) AS visitors
FROM aggregate_last_paid_click;

/* количество лидов */
SELECT 
	sum(leads_count) AS leads 
FROM aggregate_last_paid_click;

/* количество покупателей */
SELECT 
	sum(purchases_count) AS purchases 
FROM aggregate_last_paid_click;

/* конверсия из клика в лид */
SELECT 
	round(sum(leads_count) * 100.00 / sum(visitors_count), 2) AS conv_click_to_lead 
FROM aggregate_last_paid_click;

/* конверсия из лида в оплату */
SELECT 
	round(sum(purchases_count)*100.0/sum(leads_count), 2) AS conv_lead_to_purchase 
FROM aggregate_last_paid_click;

/* окупаемость */
SELECT 
	round((SUM(revenue)-SUM(total_cost))*100.0/(SUM(total_cost)), 2) AS roi
FROM aggregate_last_paid_click;

/* выручка */
SELECT 
	sum(revenue) AS revenue 
FROM aggregate_last_paid_click;

/* затраты */
SELECT 
	sum(total_cost) AS costs 
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

/* Затраты на рекламу */
SELECT
    visit_date,
    utm_source,
    sum(total_cost) AS costs
FROM aggregate_last_paid_click
WHERE utm_source IN ('vk', 'yandex')
GROUP BY visit_date, utm_source
ORDER BY costs DESC

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

/* итоговая таблица */


