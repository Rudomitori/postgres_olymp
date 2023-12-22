with recursive r as (
    select 
        0 as step_number,
        current_setting('nma.string') as str,
        null::integer as rule_id
    union
    select 
        step_number + 1,
        t.s,
        rule_id
        from (
            select step_number, substr(str, 0, pos) || b || substr(str, pos + length(a)) as s, rule_id
            -- This subquery is used to avoid duplication of "position(a in s)"
            from (
                select 
                    step_number, str,
                    a, b, id as rule_id,
                    position(a in str) as pos
                from r, nma
            ) t
            where pos > 0
            -- We need to explicitly order rules
            -- because default order can differ 
            -- after updates or deletions
            order by rule_id
            limit 1
        ) t
    where step_number < 1000
)
select step_number as n, str as s, rule_id as id
from r;