/* Проект первого модуля: анализ данных для агентства недвижимости
 * Часть 2. Решаем ad hoc задачи
 * 
 * Автор: Бойко Галина
 * Дата: 24.01.25
*/

-- Пример фильтрации данных от аномальных значений
-- Определим аномальные значения (выбросы) по значению перцентилей:
WITH limits AS (
    SELECT
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats
),
-- Найдем id объявлений, которые не содержат выбросы:
filtered_id AS(
    SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits)
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
            AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL)
    )
-- Выведем объявления без выбросов:
SELECT *
FROM real_estate.flats
WHERE id IN (SELECT * FROM filtered_id);


-- Задача 1: Время активности объявлений
-- Результат запроса должен ответить на такие вопросы:
-- 1. Какие сегменты рынка недвижимости Санкт-Петербурга и городов Ленинградской области 
--    имеют наиболее короткие или длинные сроки активности объявлений?
	with percentils as (
		select 
		percentile_disc(0.99) within group (order by total_area) as perc_99_ta,
		percentile_disc(0.99) within group (order by rooms) as perc_99_r,
		percentile_disc(0.99) within group (order by balcony) as perc_99_b,
		percentile_disc(0.99) within group (order by ceiling_height) as perc_99_ch,
		percentile_disc(0.01) within group (order by ceiling_height) as perc_01_ch
		from real_estate.flats
	),
	preprocessing as (
		select id
		from real_estate.flats 
		where total_area < (select perc_99_ta from percentils) and
				rooms < (select perc_99_r from percentils) and
				balcony < (select perc_99_b from percentils) and
				ceiling_height < (select perc_99_ch from percentils) and 
				ceiling_height > (select perc_01_ch from percentils)
	),
	counting as (
		select *,
			last_price / total_area as price_per_metre,
			days_exposition / 30 as month_exposition
		from real_estate.flats
		join real_estate.advertisement using(id)
		where id in (select * from preprocessing)
	),
	categorization as (
		select *,
			case
				when month_exposition < 1 then 'до 1 месяца'
				when month_exposition < 3 then 'до 3 месяцев'
				when month_exposition < 6 then 'до 6 месяцев'
				else 'дольше 6 месяце'
			end as duration,
			case
				when last_price < 5000000 then 'ekonom'
				when last_price < 10000000 then 'comfort'
				when last_price < 20000000 then 'business'
				else 'elite'
			end as class_category,
			case 
				when is_apartment = 1 then 'apart'
				else 'not_apart'
			end as is_apart,
			case 
				when open_plan = 1 then 'open'
				else 'close'
			end as is_open
		from counting
		join real_estate.city using(city_id)
		join real_estate.type using(type_id)
		where type = 'город'
		order by duration
	)
	select 
		class_category,
		avg(month_exposition)
	from categorization
	group by class_category
	order by avg(month_exposition)
	
	
-- 2. Какие характеристики недвижимости, включая площадь недвижимости, среднюю стоимость квадратного метра, 
--    количество комнат и балконов и другие параметры, влияют на время активности объявлений? 
--    Как эти зависимости варьируют между регионами?
-- 3. Есть ли различия между недвижимостью Санкт-Петербурга и Ленинградской области по полученным результатам?
-- код ниже относится к пунктам 2 и 3
		with percentils as (
		select 
		percentile_disc(0.99) within group (order by total_area) as perc_99_ta,
		percentile_disc(0.99) within group (order by rooms) as perc_99_r,
		percentile_disc(0.99) within group (order by balcony) as perc_99_b,
		percentile_disc(0.99) within group (order by ceiling_height) as perc_99_ch,
		percentile_disc(0.01) within group (order by ceiling_height) as perc_01_ch
		from real_estate.flats
	),
	preprocessing as (
		select id
		from real_estate.flats 
		where total_area < (select perc_99_ta from percentils) and
				rooms < (select perc_99_r from percentils) and
				balcony < (select perc_99_b from percentils) and
				ceiling_height < (select perc_99_ch from percentils) and 
				ceiling_height > (select perc_01_ch from percentils)
	),
	counting as (
		select *,
			last_price / total_area as price_per_metre,
			days_exposition / 30 as month_exposition
		from real_estate.flats
		join real_estate.advertisement using(id)
		where id in (select * from preprocessing) and days_exposition is not null
	),
	categorization as (
		select *,
			case 
				when city != 'Санкт-Петербург' then 'Лен. область'
				else 'Санкт-Петербург'
			end as region,	
			case 
				when month_exposition < 1 then 'до 1 месяца'
				when month_exposition < 3 then 'до 3 месяцев'
				when month_exposition < 6 then 'до 6 месяцев'
				else 'дольше 6 месяце'
			end as duration
		from counting
		join real_estate.city using(city_id)
		join real_estate.type using(type_id)
		where type = 'город' 
		order by region desc, duration
	)
	select 
		region,
		duration,
		count(id) as number_of_ads,
		avg(price_per_metre)::numeric(8,2) as avg_price_per_metre,
		avg(total_area)::numeric(5,2) as avg_area,
		avg(rooms)::numeric(4,2) as avg_rooms,
		avg(balcony)::numeric(4,2) as avg_balcony,
		avg(floor)::numeric(4,2) as avg_floor,
		avg(parks_around3000)::numeric(3,2) as avg_parks,
		avg(ponds_around3000)::numeric(3,2) as avg_ponds,
		avg(ceiling_height)::numeric(3,2) as avg_ceiling_height
	from categorization
	group by region, duration
	order by region desc


-- Задача 2: Сезонность объявлений
-- Результат запроса должен ответить на такие вопросы:
-- 1. В какие месяцы наблюдается наибольшая активность в публикации объявлений о продаже недвижимости? 
--    А в какие — по снятию? Это показывает динамику активности покупателей.
-- 2. Совпадают ли периоды активной публикации объявлений и периоды, 
--    когда происходит повышенная продажа недвижимости (по месяцам снятия объявлений)?
-- 3. Как сезонные колебания влияют на среднюю стоимость квадратного метра и среднюю площадь квартир? 
--    Что можно сказать о зависимости этих параметров от месяца?
	
with percentils as (
	select 
	percentile_disc(0.99) within group (order by total_area) as perc_99_ta,
	percentile_disc(0.99) within group (order by rooms) as perc_99_r,
	percentile_disc(0.99) within group (order by balcony) as perc_99_b,
	percentile_disc(0.99) within group (order by ceiling_height) as perc_99_ch,
	percentile_disc(0.01) within group (order by ceiling_height) as perc_01_ch
	from real_estate.flats
),
preprocessing as (
	select id
	from real_estate.flats 
	where total_area < (select perc_99_ta from percentils) and
			rooms < (select perc_99_r from percentils) and
			balcony < (select perc_99_b from percentils) and
			ceiling_height < (select perc_99_ch from percentils) and 
			ceiling_height > (select perc_01_ch from percentils)
),
counting as (
	select *,
		extract(month from first_day_exposition) as first_month,
		extract(month from first_day_exposition + ((days_exposition || ' days')::interval)) as last_month,
		extract(year from first_day_exposition) as first_year,
		extract(year from first_day_exposition + ((days_exposition || ' days')::interval)) as last_year,
		last_price / total_area as price_per_metre
	from real_estate.flats
	join real_estate.advertisement using(id)
	where id in (select * from preprocessing)
),
filter as (
	select *
	from counting
	join real_estate.city using(city_id)
	join real_estate.type using(type_id)
	where first_year > 2014 and first_year < 2019 and last_year > 2014 and last_year < 2019 and type = 'город'
),
datation1 as (
	select first_month,
		count(id) as cnt_in,
		avg(price_per_metre)::numeric(8,2) as avg_price,
		avg(total_area)::numeric(5,2) as avg_area
	from filter
	group by first_month
),
datation2 as (
	select last_month,
		count(id) as cnt_out
	from filter
	group by last_month
)
select last_month as month,
	cnt_in,
	cnt_out,
	avg_price,
	avg_area
from datation1
join datation2 on datation2.last_month = datation1.first_month
order by month

-- Задача 3: Анализ рынка недвижимости Ленобласти
-- Результат запроса должен ответить на такие вопросы:
-- 1. В каких населённые пунктах Ленинградской области наиболее активно публикуют объявления о продаже недвижимости?
-- 2. В каких населённых пунктах Ленинградской области — самая высокая доля снятых с публикации объявлений? 
--    Это может указывать на высокую долю продажи недвижимости.
-- 3. Какова средняя стоимость одного квадратного метра и средняя площадь продаваемых квартир в различных населённых пунктах? 
--    Есть ли вариация значений по этим метрикам?
-- 4. Среди выделенных населённых пунктов какие пункты выделяются по продолжительности публикации объявлений? 
--    То есть где недвижимость продаётся быстрее, а где — медленнее.
with percentils as (
	select 
	percentile_disc(0.99) within group (order by total_area) as perc_99_ta,
	percentile_disc(0.99) within group (order by rooms) as perc_99_r,
	percentile_disc(0.99) within group (order by balcony) as perc_99_b,
	percentile_disc(0.99) within group (order by ceiling_height) as perc_99_ch,
	percentile_disc(0.01) within group (order by ceiling_height) as perc_01_ch
	from real_estate.flats
),
preprocessing as (
	select id
	from real_estate.flats 
	where total_area < (select perc_99_ta from percentils) and
			rooms < (select perc_99_r from percentils) and
			balcony < (select perc_99_b from percentils) and
			ceiling_height < (select perc_99_ch from percentils) and 
			ceiling_height > (select perc_01_ch from percentils)
),
counting as (
	select *,
		last_price / total_area as price_per_metre,
		days_exposition / 30 as month_exposition,
		extract(month from first_day_exposition) as first_month,
		extract(month from first_day_exposition + ((days_exposition || ' days')::interval)) as last_month,
		extract(year from first_day_exposition) as first_year,
		extract(year from first_day_exposition + ((days_exposition || ' days')::interval)) as last_year
	from real_estate.flats
	join real_estate.advertisement using(id)
	join real_estate.city using(city_id)
	join real_estate.type using(type_id)
	where id in (select * from preprocessing)
),
count_cities as (
	select city,
		count(id) as number_of_all,
		avg(price_per_metre)::numeric(8,2) as avg_price_per_metre,
		avg(total_area)::numeric(4,2) as avg_area,
		avg(days_exposition)::numeric(5,2) as avg_days_exposition
	from counting
	where city != 'Санкт-Петербург'
	group by city
),
count_out_adv as (
	select city,
		count(id)::real as number_of_out
	from counting
	where city != 'Санкт-Петербург' and days_exposition is not null
	group by city
)
select city,
	number_of_all,
	(number_of_out / number_of_all)::numeric(3,2) as part_of_out,
	avg_price_per_metre,
	avg_area,
	avg_days_exposition
from count_cities
join count_out_adv using(city)
where number_of_all >= 40
order by part_of_out desc
