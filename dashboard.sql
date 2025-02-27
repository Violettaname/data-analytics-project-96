/*запрос для определения количества пользователей, которые заходят на сайт по дням */

select
    date(visit_date),
    count(visitor_id)
from sessions
group by 1

/* */
