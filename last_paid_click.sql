WITH tab AS (
    SELECT
        visitor_id,
        MAX(visit_date) AS last_date
    FROM sessions
    WHERE medium != 'organic'
    GROUP BY 1
)

SELECT
    s.visitor_id,
    s.visit_date,
    s.source AS utm_source,
    s.medium AS utm_medium,
    s.campaign AS utm_campaign,
    l.lead_id,
    l.created_at,
    l.amount,
    l.closing_reason,
    l.status_id
FROM tab AS t
INNER JOIN sessions AS s
    ON t.last_date = s.visit_date AND t.visitor_id = s.visitor_id
LEFT JOIN leads AS l 
    ON s.visitor_id = l.visitor_id
WHERE s.medium != 'organic'
ORDER BY 8 DESC NULLS LAST, 2, 3, 4, 5;
