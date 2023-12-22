with weight_of_sold as (
    -- Total weight of the sold oranges
    select sum(-net_weight) as v
    from oranges
    where net_weight < 0
), cumulative_sums as (
    select
        ts,
        price,
        -- Find a cumulative sum of left oranges
        sum(net_weight) over (order by ts) - weight_of_sold.v as value
    from oranges, weight_of_sold
    where net_weight > 0
    group by ts, weight_of_sold.v, price
), left_oranges as (
    select
        price, 
        -- To find the weights of the left oranges
        -- from the cumulative sums
        -- we need find difference between the sum of a current
        -- and a prev one
        value - lag(value, 1, 0) over (order by ts) as net_weight
    from cumulative_sums
    -- If a cumulative sum is < 0
    -- then the oranges corresponded to this time is totally sold
    where value > 0
) 
    select sum(price * net_weight)::numeric(10, 2) as amount
    from left_oranges;