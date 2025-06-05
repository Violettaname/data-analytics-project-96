/* Расчеты метрик произведены на основе таблицы aggregate_last_paid_click,
построенной по модели атрибуции Last Paid Click */
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
        s.source AS utm_source,
        s.medium AS utm_medium,
        s.campaign AS utm_campaign,
        DATE(t.last_date) AS visit_date,
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
        ON
            t.visitor_id = s.visitor_id
            AND t.last_date = s.visit_date
    LEFT JOIN leads AS l
        ON
            s.visitor_id = l.visitor_id
            AND t.last_date <= l.created_at
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
        DATE(campaign_date) AS campaign_date,
        utm_source,
        utm_medium,
        utm_campaign,
        SUM(daily_spent) AS total_cost
    FROM ya_ads
    GROUP BY 1, 2, 3, 4
),

aggregate_last_paid_click AS (
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

/* количество посетителей, лидов, покупателей */
SELECT
    SUM(visitors_count) AS visitors,
    SUM(leads_count) AS leads,
    SUM(purchases_count) AS purchases
FROM aggregate_last_paid_click;
/* конверсия из клика в лид, из лида в оплату */
SELECT
    ROUND(
        SUM(leads_count) * 100.00 / SUM(visitors_count), 2
    ) AS conv_click_to_lead,
    ROUND(
        SUM(purchases_count) * 100.0 / SUM(leads_count), 2
    ) AS conv_lead_to_purchase
FROM aggregate_last_paid_click;
/* выручка, затраты, CPU, CPL, CPPU, ROI */
SELECT
    SUM(revenue) AS revenue,
    SUM(total_cost) AS total_cost,
    ROUND(SUM(total_cost) / SUM(visitors_count), 2) AS cpu,
    ROUND(SUM(total_cost) / SUM(leads_count), 2) AS cpl,
    ROUND(SUM(total_cost) / SOM(purchases_count), 2) AS cppu,
    ROUND(
        (SUM(revenue) - SUM(total_cost)) * 100.0 / (SUM(total_cost)), 2
    ) AS roi
FROM aggregate_last_paid_click;
/* динамика посещений */
SELECT
    visit_date,
    CASE
        WHEN utm_source LIKE ('vk%') THEN 'vk'
        WHEN utm_source LIKE LOWER('yandex%') THEN 'yandex'
        ELSE 'other'
    END AS utm_source,
    SUM(visitors_count) AS visitors
FROM aggregate_last_paid_click
GROUP BY 1, 2
ORDER BY 3 DESC;
/* источники трафика: распределение трафика по каналам */
SELECT
    (CASE
        WHEN utm_source LIKE 'vk%' THEN 'vk'
        WHEN utm_source LIKE 'yandex%' THEN 'yandex'
        ELSE 'other'
    END) AS source,
    SUM(visitors_count) AS visitors
FROM aggregate_last_paid_click
GROUP BY 1
ORDER BY 2 DESC;
/* количество лидов по каналам */
SELECT
    (CASE
        WHEN utm_source LIKE 'vk%' THEN 'vk'
        WHEN utm_source LIKE 'yandex%' THEN 'yandex'
        ELSE 'other'
    END) AS source,
    SUM(leads_count) AS leads
FROM aggregate_last_paid_click
GROUP BY 1
ORDER BY 2 DESC;
/* количество посетителей, лидов, покупателей по каналам
(воронка: клик --> лид --> оплата) */
SELECT
    CASE
        WHEN utm_source LIKE ('vk%') THEN 'vk'
        WHEN utm_source LIKE LOWER('yandex%') THEN 'yandex'
        ELSE 'other'
    END AS source,
    SUM(visitors_count) AS visitors,
    SUM(leads_count) AS leads,
    SUM(purchases_count) AS purchases
FROM aggregate_last_paid_click
GROUP BY 1
ORDER BY 2 DESC;
/* Конверсии по каналам, % */
SELECT
    CASE
        WHEN utm_source LIKE ('vk%') THEN 'vk'
        WHEN utm_source LIKE LOWER('yandex%') THEN 'yandex'
        ELSE 'other'
    END AS sourse,
    ROUND(
        SUM(leads_count) * 100.00 / SUM(visitors_count), 2
    ) AS conv_click_to_lead,
    ROUND(
        SUM(purchases_count) * 100.0 / SUM(leads_count), 2
    ) AS conv_lead_to_purchase
FROM aggregate_last_paid_click
GROUP BY 1
ORDER BY 2 DESC;
/* общие затраты на рекламу */
SELECT
    ya.utm_source,
    SUM(ya.daily_spent) AS total_costs
FROM ya_ads AS ya
GROUP BY 1
UNION ALL
SELECT
    va.utm_source,
    SUM(va.daily_spent) AS total_costs
FROM vk_ads AS va
GROUP BY 1;
/* окупаемость рекламных кампаний*/
SELECT
    utm_campaign,
    utm_source,
    ROUND(
        (SUM(revenue) - SUM(total_cost)) * 100.0 / (SUM(total_cost)), 2
    ) AS source
FROM aggregate_last_paid_click
WHERE utm_source IN ('yandex', 'vk')
GROUP BY 1, 2
ORDER BY 3 DESC NULLS LAST;
/* итоговая таблица по агрегации source */
SELECT
    utm_source AS source,
    SUM(visitors_count) AS visitors,
    SUM(leads_count) AS leads,
    SUM(purchases_count) AS purchases,
    SUM(total_cost) AS cost,
    SUM(revenue) AS revenue,
    ROUND(SUM(total_cost) / SUM(visitors_count), 2) AS cpu,
    ROUND(SUM(total_cost) / SUM(leads_count), 2) AS cpl,
    ROUND(SUM(total_cost) / SUM(purchases_count), 2) AS cppu,
    ROUND((SUM(revenue) - SUM(total_cost)) * 100.00 / SUM(total_cost), 2) AS roi
FROM aggregate_last_paid_click
GROUP BY utm_source
ORDER BY roi DESC NULLS LAST;
/* итоговая таблица по агрегации medium */
SELECT
    utm_medium AS medium,
    SUM(visitors_count) AS visitors,
    SUM(leads_count) AS leads,
    SUM(purchases_count) AS purchases,
    SUM(total_cost) AS cost,
    SUM(revenue) AS revenue,
    ROUND(SUM(total_cost) / SUM(visitors_count), 2) AS cpu,
    ROUND(SUM(total_cost) / SUM(leads_count), 2) AS cpl,
    ROUND(SUM(total_cost) / SUM(purchases_count), 2) AS cppu,
    ROUND((SUM(revenue) - SUM(total_cost)) * 100.00 / SUM(total_cost), 2) AS roi
FROM aggregate_last_paid_click
GROUP BY utm_medium
ORDER BY roi DESC NULLS LAST;
/* время закрытия лидов */
WITH tab AS (
    SELECT
        visitor_id,
        MAX(visit_date) AS visit_date
    FROM sessions
    WHERE medium != 'organic'
    GROUP BY 1
),

tab2 AS (
    SELECT
        l.lead_id,
        DATE(t.visit_date) AS click_date,
        DATE(l.created_at) AS conversion_date
    FROM tab AS t
    INNER JOIN
        leads AS l
        ON t.visitor_id = l.visitor_id AND t.visit_date <= l.created_at
),

tab3 AS (
    SELECT
        (conversion_date - click_date) AS days_to_close,
        COUNT(lead_id) AS count_leds
    FROM tab2
    GROUP BY 1
    ORDER BY 1
)

SELECT PERCENTILE_DISC(0.9) WITHIN GROUP (
    ORDER BY days_to_close
) FROM tab3;
