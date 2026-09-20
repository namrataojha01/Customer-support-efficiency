create database customer_support;

select * from customer_support.customer_support_tickets;

-- Basic SQL Questions
-- Calculate the total number of tickets, total escalated tickets, and escalation rate (%) for each ticket_type?

select ticket_type,
count(ticket_id) as total_ticket,
sum(escalated) as total_escalated_ticket,
round(sum(escalated) * 100.0/count(ticket_id),2) as escalated_rate
from customer_support.customer_support_tickets
group by ticket_type
order by total_ticket desc;

-- Calculate the average response time, average resolution time, and average customer satisfaction score for each priority.

select priority, round(avg(avg_response_time_minutes),2) as avg_response_time,
round(avg(resolution_time_hours),2) as avg_resolution_time,
round(avg(customer_satisfaction_score),2) as avg_satisfaction_score 
from customer_support.customer_support_tickets
group by priority
order by priority ;

-- Find the ticket_type where the average resolution time is greater than 24 hours.
select ticket_type,
round(avg(resolution_time_hours),2) as avg_resolution_time
from customer_support.customer_support_tickets
group by ticket_type
having avg_resolution_time > 24
order by avg_resolution_time desc;


-- Calculate the total tickets and total escalated tickets for each channel, 
-- and display the channel with the highest number of escalations first.

select channel,count(ticket_id) as total_ticket,
sum(escalated) as total_escalated
from customer_support.customer_support_tickets
group by channel
order by total_escalated desc;

/*Classify tickets based on avg_response_time_minutes:

≤ 15 → Fast
16–30 → Moderate

30 → Slow

Then calculate the number of tickets in each response-time category*/

SELECT
    CASE
        WHEN avg_response_time_minutes <= 15 THEN 'Fast'
        WHEN avg_response_time_minutes <= 30 THEN 'Moderate'
        ELSE 'Slow'
    END AS response_time_category,
    COUNT(ticket_id) AS total_tickets
FROM customer_support.customer_support_tickets
GROUP BY
    CASE
        WHEN avg_response_time_minutes <= 15 THEN 'Fast'
        WHEN avg_response_time_minutes <= 30 THEN 'Moderate'
        ELSE 'Slow'
    END
ORDER BY total_tickets DESC;
          
		
/*Categorize customers based on customer_satisfaction_score:

1–2 → At Risk
3 → Neutral
4–5 → Satisfied

Then calculate the escalation rate for each satisfaction category*/

SELECT
    CASE
        WHEN customer_satisfaction_score BETWEEN 1 AND 2 THEN 'At Risk'
        WHEN customer_satisfaction_score = 3 THEN 'Neutral'
        WHEN customer_satisfaction_score BETWEEN 4 AND 5 THEN 'Satisfied'
    END AS satisfaction_category,

    COUNT(ticket_id) AS total_tickets,

    SUM(escalated) AS total_escalated,

    ROUND(
        SUM(escalated) * 100.0 / COUNT(ticket_id),
        2
    ) AS escalation_rate

FROM customer_support.customer_support_tickets

GROUP BY
    CASE
        WHEN customer_satisfaction_score BETWEEN 1 AND 2 THEN 'At Risk'
        WHEN customer_satisfaction_score = 3 THEN 'Neutral'
        WHEN customer_satisfaction_score BETWEEN 4 AND 5 THEN 'Satisfied'
    END

ORDER BY escalation_rate DESC;



-- Find all tickets whose resolution_time_hours is greater than the overall average resolution time?

SELECT
    ticket_id,
    ticket_type,
    priority,
    resolution_time_hours
FROM customer_support.customer_support_tickets
WHERE resolution_time_hours > (
    SELECT AVG(resolution_time_hours)
    FROM customer_support.customer_support_tickets
)
ORDER BY resolution_time_hours DESC;


-- Find the ticket_type whose escalation rate is higher than the overall escalation rate.

 SELECT
    ticket_type,
    COUNT(ticket_id) AS total_tickets,
    SUM(escalated) AS total_escalated,
    ROUND(SUM(escalated) * 100.0 / COUNT(ticket_id), 2) AS escalation_rate
FROM customer_support.customer_support_tickets
GROUP BY ticket_type
HAVING
    SUM(escalated) * 100.0 / COUNT(ticket_id) >
    (
        SELECT SUM(escalated) * 100.0 / COUNT(ticket_id)
        FROM customer_support.customer_support_tickets
    )
ORDER BY escalation_rate DESC;


-- Using a CTE, calculate the total tickets and escalated tickets for each ticket_type, and then calculate the escalation rate.

WITH ticket_summary AS (
    SELECT
        ticket_type,
        COUNT(ticket_id) AS total_tickets,
        SUM(escalated) AS total_escalated
    FROM customer_support.customer_support_tickets
    GROUP BY ticket_type
)

SELECT
    ticket_type,
    total_tickets,
    total_escalated,
    ROUND(total_escalated * 100.0 / total_tickets, 2) AS escalation_rate
FROM ticket_summary
ORDER BY escalation_rate DESC;

-- Using a CTE, calculate the escalation rate for each priority and return the priority with the highest escalation rate

WITH priority_summary AS (
    SELECT
        priority,
        COUNT(ticket_id) AS total_tickets,
        SUM(escalated) AS total_escalated
    FROM customer_support.customer_support_tickets
    GROUP BY priority
)

SELECT
    priority,
    total_tickets,
    total_escalated,
    ROUND(total_escalated * 100.0 / total_tickets, 2) AS escalation_rate
FROM priority_summary
ORDER BY escalation_rate DESC
LIMIT 1;

-- Using a CTE, classify customers into New, Regular, and Loyal based on customer_tenure_months, and calculate the average CSAT and escalation rate for each segment.
WITH customer_segments AS (
    SELECT
        ticket_id,
        customer_tenure_months,
        customer_satisfaction_score,
        escalated,
        CASE
            WHEN customer_tenure_months <= 12 THEN 'New'
            WHEN customer_tenure_months <= 36 THEN 'Regular'
            ELSE 'Loyal'
        END AS customer_tenure_segment
    FROM customer_support.customer_support_tickets
)

SELECT
    customer_tenure_segment,
    COUNT(ticket_id) AS total_tickets,
    ROUND(AVG(customer_satisfaction_score), 2) AS avg_csat,
    SUM(escalated) AS total_escalated,
    ROUND(
        SUM(escalated) * 100.0 / COUNT(ticket_id),
        2
    ) AS escalation_rate
FROM customer_segments
GROUP BY customer_tenure_segment
ORDER BY escalation_rate DESC;

-- Rank tickets within each ticket_type based on resolution_time_hours, from highest to lowest.

SELECT
    ticket_id,
    ticket_type,
    resolution_time_hours,
    RANK() OVER (
        PARTITION BY ticket_type
        ORDER BY resolution_time_hours DESC
    ) AS resolution_rank
FROM customer_support.customer_support_tickets
ORDER BY ticket_type, resolution_rank;

-- Find the top 3 tickets with the longest resolution time within each priority
WITH ranked_tickets AS (
    SELECT
        ticket_id,
        ticket_type,
        priority,
        resolution_time_hours,
        ROW_NUMBER() OVER (
            PARTITION BY priority
            ORDER BY resolution_time_hours DESC
        ) AS resolution_rank
    FROM customer_support.customer_support_tickets
)

SELECT
    ticket_id,
    ticket_type,
    priority,
    resolution_time_hours,
    resolution_rank
FROM ranked_tickets
WHERE resolution_rank <= 3
ORDER BY priority, resolution_rank;


-- Calculate the escalation rate for each ticket_type and compare it with the overall escalation rate using a CTE and window function
WITH ticket_summary AS (
    SELECT
        ticket_type,
        COUNT(ticket_id) AS total_tickets,
        SUM(escalated) AS total_escalated
    FROM customer_support.customer_support_tickets
    GROUP BY ticket_type
),

ticket_rates AS (
    SELECT
        ticket_type,
        total_tickets,
        total_escalated,
        ROUND(
            total_escalated * 100.0 / total_tickets,
            2
        ) AS escalation_rate,

        ROUND(
            SUM(total_escalated) OVER () * 100.0 /
            SUM(total_tickets) OVER (),
            2
        ) AS overall_escalation_rate

    FROM ticket_summary
)

SELECT
    ticket_type,
    total_tickets,
    total_escalated,
    escalation_rate,
    overall_escalation_rate,
    ROUND(
        escalation_rate - overall_escalation_rate,
        2
    ) AS difference_from_overall
FROM ticket_rates
ORDER BY escalation_rate DESC;


/*Customer Support Risk Analysis:
Create a query that displays each ticket's:

ticket_type
priority
response_time_band
satisfaction_band
escalation_risk
actual escalated status

Then calculate the actual escalation rate for each risk category*/
WITH ticket_risk AS (
    SELECT
        ticket_id,
        ticket_type,
        priority,

        -- Response Time Band
        CASE
            WHEN avg_response_time_minutes <= 15 THEN 'Fast'
            WHEN avg_response_time_minutes <= 30 THEN 'Moderate'
            ELSE 'Slow'
        END AS response_time_band,

        -- Satisfaction Band
        CASE
            WHEN customer_satisfaction_score <= 2 THEN 'At Risk'
            WHEN customer_satisfaction_score = 3 THEN 'Neutral'
            ELSE 'Satisfied'
        END AS satisfaction_band,

        -- Escalation Risk Score
        (
            CASE WHEN avg_response_time_minutes > 30 THEN 2 ELSE 0 END
            +
            CASE WHEN resolution_time_hours > 24 THEN 2 ELSE 0 END
            +
            CASE WHEN messages_count > 30 THEN 1 ELSE 0 END
            +
            CASE WHEN customer_satisfaction_score <= 2 THEN 2 ELSE 0 END
            +
            CASE WHEN priority = 'Critical' THEN 1 ELSE 0 END
        ) AS escalation_risk_score,

        escalated
    FROM customer_support.customer_support_tickets
),

risk_category AS (
    SELECT
        *,
        CASE
            WHEN escalation_risk_score >= 5 THEN 'High Risk'
            WHEN escalation_risk_score >= 3 THEN 'Medium Risk'
            ELSE 'Low Risk'
        END AS escalation_risk
    FROM ticket_risk
)

SELECT
    ticket_type,
    priority,
    response_time_band,
    satisfaction_band,
    escalation_risk,
    escalated,
    COUNT(ticket_id) AS total_tickets,
    SUM(escalated) AS total_escalated,
    ROUND(
        SUM(escalated) * 100.0 / COUNT(ticket_id),
        2
    ) AS actual_escalation_rate
FROM risk_category
GROUP BY
    ticket_type,
    priority,
    response_time_band,
    satisfaction_band,
    escalation_risk,
    escalated
ORDER BY actual_escalation_rate DESC;
