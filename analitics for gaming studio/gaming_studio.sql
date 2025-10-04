/* Проект «Секреты Тёмнолесья»
 * Цель проекта: изучить влияние характеристик игроков и их игровых персонажей 
 * на покупку внутриигровой валюты «райские лепестки», а также оценить 
 * активность игроков при совершении внутриигровых покупок
 * 
 * Автор: Бойко Галина 
 * Дата: 31/12/2024
*/

-- Часть 1. Исследовательский анализ данных
-- Задача 1. Исследование доли платящих игроков

-- 1.1. Доля платящих пользователей по всем данным:
select total_users,
	total_payers,
	total_payers::real / total_users as part
from (select count(id) as total_users,
	(select
		count(id) 
	from fantasy.users
	where payer = 1) as total_payers
from fantasy.users) as counting

-- 1.2. Доля платящих пользователей в разрезе расы персонажа:
select race,
	total_payers,
	total_users,
	total_payers::real / total_users as part
from 
	(select race,
		count(id) as total_users
	from fantasy.users 
	join race using(race_id)
	group by race) as countig_user
join
	(select race,
		count(id) as total_payers
	from fantasy.users
	join race using(race_id)
	where payer = 1
	group by race) as counting_payer using(race)


-- Задача 2. Исследование внутриигровых покупок
-- 2.1. Статистические показатели по полю amount:
select count(transaction_id) as count_events,
	sum(amount::numeric) as sum_amount,
	min(amount::numeric) as min_amount,
	max(amount::numeric) as max_amount,
	round(avg(amount::numeric), 4) as avg_amount,
	percentile_disc(0.5) within group (order by amount) as median_amount,
	round(stddev(amount::numeric), 4) as stddev_amount
from fantasy.events
where amount > 0
union 
select count(transaction_id) as count_events,
	sum(amount::numeric) as sum_amount,
	min(amount::numeric) as min_amount,
	max(amount::numeric) as max_amount,
	round(avg(amount::numeric), 4) as avg_amount,
	percentile_disc(0.5) within group (order by amount) as median_amount,
	round(stddev(amount::numeric), 4) as stddev_amount
from fantasy.events

-- 2.2: Аномальные нулевые покупки:
select count(*) as count_amount,
	count(*) filter(where amount = 0) as count_null_amount,
	count(*) filter(where amount = 0) / count(*)::real as part_null_amount
from fantasy.events

-- 2.3: Сравнительный анализ активности платящих и неплатящих игроков:
select 
	CASE WHEN payer = 1 THEN 'Платящий' ELSE 'Неплатящий' END AS payer,
	count(id) as total_users,
	round(avg(total_events_per_user::numeric), 4) as avg_events,
	round(avg(sum_amount_per_user::numeric), 4) as avg_amount
from 
	(select id, 
		count(transaction_id) as total_events_per_user,
		sum(amount) as sum_amount_per_user
	from fantasy.events
	where amount > 0
	group by id) as counting
join fantasy.users using(id)
group by payer
	
-- 2.4: Популярные эпические предметы:
select game_items,
	count(events.item_code) as total_items,
	count(events.transaction_id)::real / (select count(transaction_id) from fantasy.events  where amount > 0) as item_per_items,
	count(distinct id)::real / (select count(distinct id) from fantasy.events where amount > 0) as user_per_users
from fantasy.events 
join fantasy.items using(item_code)
join fantasy.users using(id)
where amount > 0
group by game_items
order by total_items desc 

-- Часть 2. Решение ad hoc-задач

-- Задача 1. Зависимость активности игроков от расы персонажа:
with gamers_stat as (
-- Считаем статистику по покупателям
	select race, 
		race_id,
		count(id) as total_gamers
	from fantasy.race 
	join fantasy.users using(race_id)
	group by race_id),
buyers_stat as (
-- Считаем статистику по покупкам с фильтрацией нулевых покупок
	select race_id,
		count(distinct id) as total_buyers,
		count(distinct id) filter(where payer = 1) / count(distinct id)::real as payer_buyers_share
	from fantasy.users
	join fantasy.events using(id)
	where amount > 0
	group by race_id),
orders_stat as (
-- Считаем статистику по транзакциям с фильтрацией нулевых покупок
	select race_id,
		count(transaction_id) as total_orders,
		sum(amount) as total_amount 
	from fantasy.users
	join fantasy.events using(id)
	where amount > 0
	group by race_id)
select 
    race,
    -- выводим статистику по игрокам
    total_gamers,
    total_buyers,
    round(total_buyers::numeric/total_gamers, 4) as buyers_share,
    payer_buyers_share::numeric(6, 4),
    -- выводим статистику по покупкам
    round(total_orders::numeric/total_buyers, 4) as orders_per_buyer,
    round(total_amount::numeric/total_buyers, 4) as total_amount_per_buyer,
    round(total_amount::numeric/total_orders, 4) as avg_amount_per_buyer
from gamers_stat join buyers_stat using(race_id) join orders_stat using(race_id)

-- Задача 2: Частота покупок
select 
	case 
		when freq_group = 1 then 'высокая частота'
		when freq_group = 2 then 'умеренная частота'
		else 'низкая частота'
	end as freq_group,
	count(id) as total_users,
	sum(payer) as total_payers,
	sum(payer)::real / count(id) as payers_part,
	avg(total_purchase) as avg_number_of_purchase,
	avg(avg_days_between_purchases)	as avg_days
from (select 
		id,
		total_purchase,
		avg_days_between_purchases,
		payer,
		ntile(3) over(order by avg_days_between_purchases) as freq_group
	from (select 
			id,
			count(transaction_id) as total_purchase,
			avg(interval) as avg_days_between_purchases,
			payer
		from (select
				transaction_id,
				id,
				date - lag(date) over(partition by id order by date) as interval,
				payer
			from (select 
					transaction_id,
					e.id,
					date::date,
					payer,
					amount
				from fantasy.events as e
				join fantasy.users using(id)
				where amount <> 0) as date_to_date
			) as days_between_purchases
		group by id, payer) as counting
	where total_purchase >= 25) as freq_grouping
	group by freq_group
