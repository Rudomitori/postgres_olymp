with directions as (
    select
        id, x, y,
        -- A direction that the snake moved from a cell in.
        -- Because the snake can not move diagonally
        -- x and y can not have non-zero difference 
        -- at the same time 
        case lead(x, 1, x) over (order by id) - x
            when -1 then 'L'
            when 1 then 'R'
            else case lead(y, 1, y) over (order by id) - y
                when -1 then 'U'
                when 1 then 'D'
                else 'H'
            end
        end as dir
    from snake
),  segments as (
    select 
        id, x, y,
        -- because of default value of lag function
        -- the snake's tail is mapped to one of the first 4 cases
        case lag(dir, 1, dir) over (order by id) || dir
            when 'UU' then '│'
            when 'DD' then '│'
            when 'RR' then '─'
            when 'LL' then '─'
            when 'RU' then '┘'
            when 'DL' then '┘'
            when 'RD' then '┐'
            when 'UL' then '┐'
            when 'UR' then '┌'
            when 'LD' then '┌'
            when 'LU' then '└'
            when 'DR' then '└'
            -- 'LR', 'RL', 'UD', 'DU' are impossible
            else 'ö'
        end as seg
    from directions
) select
        t1.line,
        string_agg(
            coalesce(s.seg, '.'),
            ''
            -- Order cells in a row by column
            order by col
        ) as snake
    -- Create empty cells
    from (select generate_series(0, 9)) as t1(line)
    join (select generate_series(0, 9)) t2(col) on true
    -- Insert the snake segments into the cells
    left join segments s on s.x = t2.col and s.y = t1.line
    group by t1.line
    order by t1.line;