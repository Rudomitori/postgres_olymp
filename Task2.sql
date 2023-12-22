with month as (
    -- Parse the date once to reuse later
    select to_date(current_setting('calendar.year') || current_setting('calendar.month'), 'YYYYMM') as v
), days as (
    -- Generate sequence of the days of the month
    select generate_series(
        month.v,
        month.v + make_interval(months := 1, days := -1),
        '1 day'
    )::date as day
    from month
), days_positions as (
    -- Find position of days in the calendar
    select
        day,
        extract(isodow from day) as row,
        1 + (date_trunc('week', day)::date - date_trunc('week', month.v)::date) / 7 as col
    from days, month
), calendar_cells as (
    -- Generate cells of the future calendar.
    -- The cells are more than the days
    -- and it will help to handle aligning of weeks in the calendar.
    select t.row, generate_series(1, max(col)) as col
    from days_positions, generate_series(1, 7) as t(row)
    group by t.row
), calendar as (
    -- Insert the days into the calendar cells
    -- and aggregate rows of the cells into arrays
    select array_agg(day) as days, cc.row
    from calendar_cells cc
    left join days_positions dp 
        on cc.col = dp.col and cc.row = dp.row
    group by cc.row
    order by cc.row
) select
      row as n,
      (select 
           -- The first cell in a row can haven't 
           -- a day but the second always has one
           to_char(days[2], 'Dy') 
               || ' '
               || string_agg(
                      coalesce(
                          -- 'dd' format generates leading zeros
                          -- that must be removed
                          regexp_replace(to_char(day, 'dd'), '^0', ' '),
                          -- if a cell hasn't a corresponding day
                          -- it will be displayed as 2 spaces
                          '  '
                      ),
                      ' '
                  )
       from unnest(days) as t(day)) as calendar
from calendar;