with recursive potential_solutions as (
    select 
        array[]::integer[] as quantities,
        0 as total_amount,
        0 as faces_total_count,
        (select max(face_value) from atm) + 1 as last_face_value
    union all
    select 
        array_append(quantities, q) as quantities,
        total_amount + q * face_value as total_amount,
        faces_total_count + q as faces_total_count,
        face_value as last_face_value
    from potential_solutions,
    lateral (
        select generate_series(0, quantity) q, face_value
        from (
            select *
            from atm
            where face_value < last_face_value
            order by face_value desc
            limit 1
        ) f
    ) f
    where total_amount + q * face_value <= current_setting('atm.amount')::int
), final_solution as (
    select quantities
    from potential_solutions
    where current_setting('atm.amount')::int = total_amount
    order by faces_total_count
    limit 1
) select f as face_value, q as quantity
    from (
        select 
            unnest(quantities) as q, 
            unnest((select array_agg(face_value order by face_value desc) from atm)) f
        from final_solution
    ) t
    where q > 0;