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
        COUNT(distinct t.visitor_id) AS visitors_count,
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
    LEFT JOIN leads AS l ON s.visitor_id = l.visitor_id AND t.last_date <= l.created_at
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
)

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
ORDER BY 9 DESC NULLS LAST, 1 ASC, 5 DESC, 2, 3, 4;
