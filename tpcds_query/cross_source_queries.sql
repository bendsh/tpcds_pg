-- 跨数据库查询集合
-- 包含同时使用database_01和database_02表的查询

-- 查询1跨数据库 (Query 1)
select count(*)
from database_01.store_sales
   , database_02.household_demographics
   , database_02.time_dim
   , database_01.store
where ss_sold_time_sk = time_dim.t_time_sk
  and ss_hdemo_sk = household_demographics.hd_demo_sk
  and ss_store_sk = s_store_sk
  and time_dim.t_hour = 8
  and time_dim.t_minute >= 30
  and household_demographics.hd_dep_count = 5
  and store.s_store_name = 'ese'
order by count(*) LIMIT 100;

-- 查询3跨数据库 (Query 3)
WITH all_sales AS (SELECT d_year
                        , i_brand_id
                        , i_class_id
                        , i_category_id
                        , i_manufact_id
                        , SUM(sales_cnt) AS sales_cnt
                        , SUM(sales_amt) AS sales_amt
                   FROM (SELECT d_year
                              , i_brand_id
                              , i_class_id
                              , i_category_id
                              , i_manufact_id
                              , cs_quantity - COALESCE(cr_return_quantity, 0)        AS sales_cnt
                              , cs_ext_sales_price - COALESCE(cr_return_amount, 0.0) AS sales_amt
                         FROM database_01.catalog_sales
                                  JOIN database_01.item ON i_item_sk = cs_item_sk
                                  JOIN database_01.date_dim ON d_date_sk = cs_sold_date_sk
                                  LEFT JOIN database_02.catalog_returns ON (cs_order_number = cr_order_number
                             AND cs_item_sk = cr_item_sk)
                         WHERE i_category = 'Shoes'
                         UNION
                         SELECT d_year
                              , i_brand_id
                              , i_class_id
                              , i_category_id
                              , i_manufact_id
                              , ss_quantity - COALESCE(sr_return_quantity, 0)     AS sales_cnt
                              , ss_ext_sales_price - COALESCE(sr_return_amt, 0.0) AS sales_amt
                         FROM database_01.store_sales
                                  JOIN database_01.item ON i_item_sk = ss_item_sk
                                  JOIN database_01.date_dim ON d_date_sk = ss_sold_date_sk
                                  LEFT JOIN database_01.store_returns ON (ss_ticket_number = sr_ticket_number
                             AND ss_item_sk = sr_item_sk)
                         WHERE i_category = 'Shoes'
                         UNION
                         SELECT d_year
                              , i_brand_id
                              , i_class_id
                              , i_category_id
                              , i_manufact_id
                              , ws_quantity - COALESCE(wr_return_quantity, 0)     AS sales_cnt
                              , ws_ext_sales_price - COALESCE(wr_return_amt, 0.0) AS sales_amt
                         FROM database_01.web_sales
                                  JOIN database_01.item ON i_item_sk = ws_item_sk
                                  JOIN database_01.date_dim ON d_date_sk = ws_sold_date_sk
                                  LEFT JOIN database_02.web_returns ON (ws_order_number = wr_order_number
                             AND ws_item_sk = wr_item_sk)
                         WHERE i_category = 'Shoes') sales_detail
                   GROUP BY d_year, i_brand_id, i_class_id, i_category_id, i_manufact_id)
SELECT prev_yr.d_year AS prev_year
     , curr_yr.d_year AS year
                          ,curr_yr.i_brand_id
                          ,curr_yr.i_class_id
                          ,curr_yr.i_category_id
                          ,curr_yr.i_manufact_id
                          ,prev_yr.sales_cnt AS prev_yr_cnt
                          ,curr_yr.sales_cnt AS curr_yr_cnt
                          ,curr_yr.sales_cnt-prev_yr.sales_cnt AS sales_cnt_diff
                          ,curr_yr.sales_amt-prev_yr.sales_amt AS sales_amt_diff
FROM all_sales curr_yr, all_sales prev_yr
WHERE curr_yr.i_brand_id=prev_yr.i_brand_id
  AND curr_yr.i_class_id=prev_yr.i_class_id
  AND curr_yr.i_category_id=prev_yr.i_category_id
  AND curr_yr.i_manufact_id=prev_yr.i_manufact_id
  AND curr_yr.d_year=2000
  AND prev_yr.d_year=2000-1
  AND CAST (curr_yr.sales_cnt AS DECIMAL (17
    , 2))/ CAST (prev_yr.sales_cnt AS DECIMAL (17
    , 2))
    <0.9
ORDER BY sales_cnt_diff, sales_amt_diff
    LIMIT 100;

-- 查询5跨数据库 (Query 5)
with inv as
         (select w_warehouse_name
               , w_warehouse_sk
               , i_item_sk
               , d_moy
               , stdev
               , mean
               , case mean when 0 then null else stdev / mean end cov
          from (select w_warehouse_name
                     , w_warehouse_sk
                     , i_item_sk
                     , d_moy
                     , stddev_samp(inv_quantity_on_hand) stdev
                     , avg(inv_quantity_on_hand)         mean
                from database_02.inventory
                   , database_01.item
                   , database_02.warehouse
                   , database_01.date_dim
                where inv_item_sk = i_item_sk
                  and inv_warehouse_sk = w_warehouse_sk
                  and inv_date_sk = d_date_sk
                  and d_year = 2001
                group by w_warehouse_name, w_warehouse_sk, i_item_sk, d_moy) foo
          where case mean when 0 then 0 else stdev / mean end > 1)
select inv1.w_warehouse_sk
     , inv1.i_item_sk
     , inv1.d_moy
     , inv1.mean
     , inv1.cov
     , inv2.w_warehouse_sk
     , inv2.i_item_sk
     , inv2.d_moy
     , inv2.mean
     , inv2.cov
from inv inv1,
     inv inv2
where inv1.i_item_sk = inv2.i_item_sk
  and inv1.w_warehouse_sk = inv2.w_warehouse_sk
  and inv1.d_moy = 1
  and inv2.d_moy = 1 + 1
order by inv1.w_warehouse_sk, inv1.i_item_sk, inv1.d_moy, inv1.mean, inv1.cov
       , inv2.d_moy, inv2.mean, inv2.cov;

-- 查询6跨数据库 (Query 6)
with ssr as
         (select s_store_id                                    as store_id,
                 sum(ss_ext_sales_price)                       as sales,
                 sum(coalesce(sr_return_amt, 0))               as returns,
                 sum(ss_net_profit - coalesce(sr_net_loss, 0)) as profit
          from database_01.store_sales
                   left outer join database_01.store_returns on
              (ss_item_sk = sr_item_sk and ss_ticket_number = sr_ticket_number),
               database_01.date_dim,
               database_01.store,
               database_01.item,
               database_01.promotion
          where ss_sold_date_sk = d_date_sk
            and d_date between cast('2002-08-04' as date)
              and (cast('2002-08-04' as date) + 30 days)
            and ss_store_sk = s_store_sk
            and ss_item_sk = i_item_sk
            and i_current_price > 50
            and ss_promo_sk = p_promo_sk
            and p_channel_tv = 'N'
          group by s_store_id)
        ,
     csr as
         (select cp_catalog_page_id                            as catalog_page_id,
                 sum(cs_ext_sales_price)                       as sales,
                 sum(coalesce(cr_return_amount, 0))            as returns,
                 sum(cs_net_profit - coalesce(cr_net_loss, 0)) as profit
          from database_01.catalog_sales
                   left outer join database_02.catalog_returns on
              (cs_item_sk = cr_item_sk and cs_order_number = cr_order_number),
               database_01.date_dim,
               database_02.catalog_page,
               database_01.item,
               database_01.promotion
          where cs_sold_date_sk = d_date_sk
            and d_date between cast('2002-08-04' as date)
              and (cast('2002-08-04' as date) + 30 days)
            and cs_catalog_page_sk = cp_catalog_page_sk
            and cs_item_sk = i_item_sk
            and i_current_price > 50
            and cs_promo_sk = p_promo_sk
            and p_channel_tv = 'N'
          group by cp_catalog_page_id)
        ,
     wsr as
         (select web_site_id,
                 sum(ws_ext_sales_price)                       as sales,
                 sum(coalesce(wr_return_amt, 0))               as returns,
                 sum(ws_net_profit - coalesce(wr_net_loss, 0)) as profit
          from database_01.web_sales
                   left outer join database_02.web_returns on
              (ws_item_sk = wr_item_sk and ws_order_number = wr_order_number),
               database_01.date_dim,
               database_02.web_site,
               database_01.item,
               database_01.promotion
          where ws_sold_date_sk = d_date_sk
            and d_date between cast('2002-08-04' as date)
              and (cast('2002-08-04' as date) + 30 days)
            and ws_web_site_sk = web_site_sk
            and ws_item_sk = i_item_sk
            and i_current_price > 50
            and ws_promo_sk = p_promo_sk
            and p_channel_tv = 'N'
          group by web_site_id)
select channel
     , id
     , sum(sales)   as sales
     , sum(returns) as returns
     , sum(profit)  as profit
from (select 'store channel'     as channel
           , 'store' || store_id as id
           , sales
           , returns
           , profit
      from ssr
      union all
      select 'catalog channel'                 as channel
           , 'catalog_page' || catalog_page_id as id
           , sales
           , returns
           , profit
      from csr
      union all
      select 'web channel'             as channel
           , 'web_site' || web_site_id as id
           , sales
           , returns
           , profit
      from wsr) x
group by rollup (channel, id)
order by channel
       , id LIMIT 100;

-- 查询10跨数据库 (Query 10)
with ws as
         (select d_year AS              ws_sold_year,
                 ws_item_sk,
                 ws_bill_customer_sk    ws_customer_sk,
                 sum(ws_quantity)       ws_qty,
                 sum(ws_wholesale_cost) ws_wc,
                 sum(ws_sales_price)    ws_sp
          from database_01.web_sales
                   left join database_02.web_returns on wr_order_number = ws_order_number and ws_item_sk = wr_item_sk
                   join database_01.date_dim on ws_sold_date_sk = d_date_sk
          where wr_order_number is null
          group by d_year, ws_item_sk, ws_bill_customer_sk),
     cs as
         (select d_year AS              cs_sold_year,
                 cs_item_sk,
                 cs_bill_customer_sk    cs_customer_sk,
                 sum(cs_quantity)       cs_qty,
                 sum(cs_wholesale_cost) cs_wc,
                 sum(cs_sales_price)    cs_sp
          from database_01.catalog_sales
                   left join database_02.catalog_returns on cr_order_number = cs_order_number and cs_item_sk = cr_item_sk
                   join database_01.date_dim on cs_sold_date_sk = d_date_sk
          where cr_order_number is null
          group by d_year, cs_item_sk, cs_bill_customer_sk),
     ss as
         (select d_year AS              ss_sold_year,
                 ss_item_sk,
                 ss_customer_sk,
                 sum(ss_quantity)       ss_qty,
                 sum(ss_wholesale_cost) ss_wc,
                 sum(ss_sales_price)    ss_sp
          from database_01.store_sales
                   left join database_01.store_returns on sr_ticket_number = ss_ticket_number and ss_item_sk = sr_item_sk
                   join database_01.date_dim on ss_sold_date_sk = d_date_sk
          where sr_ticket_number is null
          group by d_year, ss_item_sk, ss_customer_sk)
select ss_customer_sk,
       round(ss_qty / (coalesce(ws_qty, 0) + coalesce(cs_qty, 0)), 2) ratio,
       ss_qty                                                         store_qty,
       ss_wc                                                          store_wholesale_cost,
       ss_sp                                                          store_sales_price,
       coalesce(ws_qty, 0) + coalesce(cs_qty, 0)                      other_chan_qty,
       coalesce(ws_wc, 0) + coalesce(cs_wc, 0)                        other_chan_wholesale_cost,
       coalesce(ws_sp, 0) + coalesce(cs_sp, 0)                        other_chan_sales_price
from ss
         left join ws on (ws_sold_year = ss_sold_year and ws_item_sk = ss_item_sk and ws_customer_sk = ss_customer_sk)
         left join cs on (cs_sold_year = ss_sold_year and cs_item_sk = ss_item_sk and cs_customer_sk = ss_customer_sk)
where (coalesce(ws_qty, 0) > 0 or coalesce(cs_qty, 0) > 0)
  and ss_sold_year = 2001
order by ss_customer_sk,
         ss_qty desc, ss_wc desc, ss_sp desc,
         other_chan_qty,
         other_chan_wholesale_cost,
         other_chan_sales_price,
         ratio LIMIT 100;

-- 查询13跨数据库 (Query 13)
select cc_call_center_id Call_Center,
       cc_name           Call_Center_Name,
       cc_manager        Manager,
       sum(cr_net_loss)  Returns_Loss
from database_02.call_center,
     database_02.catalog_returns,
     database_01.date_dim,
     database_01.customer,
     database_01.customer_address,
     database_01.customer_demographics,
     database_02.household_demographics
where cr_call_center_sk = cc_call_center_sk
  and cr_returned_date_sk = d_date_sk
  and cr_returning_customer_sk = c_customer_sk
  and cd_demo_sk = c_current_cdemo_sk
  and hd_demo_sk = c_current_hdemo_sk
  and ca_address_sk = c_current_addr_sk
  and d_year = 2002
  and d_moy = 11
  and ((cd_marital_status = 'M' and cd_education_status = 'Unknown')
    or (cd_marital_status = 'W' and cd_education_status = 'Advanced Degree'))
  and hd_buy_potential like 'Unknown%'
  and ca_gmt_offset = -6
group by cc_call_center_id, cc_name, cc_manager, cd_marital_status, cd_education_status
order by sum(cr_net_loss) desc;

-- 查询14跨数据库 (Query 14)
select *
from (select w_warehouse_name
           , i_item_id
           , sum(case
                     when (cast(d_date as date) < cast('2000-05-19' as date))
                         then inv_quantity_on_hand
                     else 0 end) as inv_before
           , sum(case
                     when (cast(d_date as date) >= cast('2000-05-19' as date))
                         then inv_quantity_on_hand
                     else 0 end) as inv_after
      from database_02.inventory
         , database_02.warehouse
         , database_01.item
         , database_01.date_dim
      where i_current_price between 0.99 and 1.49
        and i_item_sk = inv_item_sk
        and inv_warehouse_sk = w_warehouse_sk
        and inv_date_sk = d_date_sk
        and d_date between (cast('2000-05-19' as date) - 30 days)
          and (cast('2000-05-19' as date) + 30 days)
      group by w_warehouse_name, i_item_id) x
where (case
           when inv_before > 0
               then inv_after / inv_before
           else null
    end) between 2.0 / 3.0 and 3.0 / 2.0
order by w_warehouse_name
       , i_item_id LIMIT 100;

-- 查询17跨数据库 (Query 17)
select count(distinct ws_order_number) as "order count"
     , sum(ws_ext_ship_cost)           as "total shipping cost"
     , sum(ws_net_profit)              as "total net profit"
from database_01.web_sales ws1
   , database_01.date_dim
   , database_01.customer_address
   , database_02.web_site
where d_date between '1999-4-01' and
    (cast('1999-4-01' as date) + 60 days)
  and ws1.ws_ship_date_sk = d_date_sk
  and ws1.ws_ship_addr_sk = ca_address_sk
  and ca_state = 'WI'
  and ws1.ws_web_site_sk = web_site_sk
  and web_company_name = 'pri'
  and exists (select *
              from database_01.web_sales ws2
              where ws1.ws_order_number = ws2.ws_order_number
                and ws1.ws_warehouse_sk <> ws2.ws_warehouse_sk)
  and not exists(select *
                 from database_02.web_returns wr1
                 where ws1.ws_order_number = wr1.wr_order_number)
order by count(distinct ws_order_number) LIMIT 100;

-- 查询24跨数据库 (Query 24)
select substr(w_warehouse_name, 1, 20)
     , sm_type
     , web_name
     , sum(case when (ws_ship_date_sk - ws_sold_date_sk <= 30) then 1 else 0 end) as "30 days"
     , sum(case
               when (ws_ship_date_sk - ws_sold_date_sk > 30) and
                    (ws_ship_date_sk - ws_sold_date_sk <= 60) then 1
               else 0 end)                                                        as "31-60 days"
     , sum(case
               when (ws_ship_date_sk - ws_sold_date_sk > 60) and
                    (ws_ship_date_sk - ws_sold_date_sk <= 90) then 1
               else 0 end)                                                        as "61-90 days"
     , sum(case
               when (ws_ship_date_sk - ws_sold_date_sk > 90) and
                    (ws_ship_date_sk - ws_sold_date_sk <= 120) then 1
               else 0 end)                                                        as "91-120 days"
     , sum(case when (ws_ship_date_sk - ws_sold_date_sk > 120) then 1 else 0 end) as ">120 days"
from database_01.web_sales
   , database_02.warehouse
   , database_02.ship_mode
   , database_02.web_site
   , database_01.date_dim
where d_month_seq between 1217 and 1217 + 11
  and ws_ship_date_sk = d_date_sk
  and ws_warehouse_sk = w_warehouse_sk
  and ws_ship_mode_sk = sm_ship_mode_sk
  and ws_web_site_sk = web_site_sk
group by substr(w_warehouse_name, 1, 20)
       , sm_type
       , web_name
order by substr(w_warehouse_name, 1, 20)
       , sm_type
       , web_name LIMIT 100;

-- 查询33跨数据库 (Query 33)
select substr(r_reason_desc, 1, 20)
     , avg(ws_quantity)
     , avg(wr_refunded_cash)
     , avg(wr_fee)
from database_01.web_sales
   , database_02.web_returns
   , database_02.web_page
   , database_01.customer_demographics cd1
   , database_01.customer_demographics cd2
   , database_01.customer_address
   , database_01.date_dim
   , database_01.reason
where ws_web_page_sk = wp_web_page_sk
  and ws_item_sk = wr_item_sk
  and ws_order_number = wr_order_number
  and ws_sold_date_sk = d_date_sk
  and d_year = 2001
  and cd1.cd_demo_sk = wr_refunded_cdemo_sk
  and cd2.cd_demo_sk = wr_returning_cdemo_sk
  and ca_address_sk = wr_refunded_addr_sk
  and r_reason_sk = wr_reason_sk
  and (
        (
                    cd1.cd_marital_status = 'D'
                and
                    cd1.cd_marital_status = cd2.cd_marital_status
                and
                    cd1.cd_education_status = 'Primary'
                and
                    cd1.cd_education_status = cd2.cd_education_status
                and
                    ws_sales_price between 100.00 and 150.00
            )
        or
        (
                    cd1.cd_marital_status = 'U'
                and
                    cd1.cd_marital_status = cd2.cd_marital_status
                and
                    cd1.cd_education_status = 'Unknown'
                and
                    cd1.cd_education_status = cd2.cd_education_status
                and
                    ws_sales_price between 50.00 and 100.00
            )
        or
        (
                    cd1.cd_marital_status = 'M'
                and
                    cd1.cd_marital_status = cd2.cd_marital_status
                and
                    cd1.cd_education_status = 'Advanced Degree'
                and
                    cd1.cd_education_status = cd2.cd_education_status
                and
                    ws_sales_price between 150.00 and 200.00
            )
    )
  and (
        (
                    ca_country = 'United States'
                and
                    ca_state in ('SC', 'IN', 'VA')
                and ws_net_profit between 100 and 200
            )
        or
        (
                    ca_country = 'United States'
                and
                    ca_state in ('WA', 'KS', 'KY')
                and ws_net_profit between 150 and 300
            )
        or
        (
                    ca_country = 'United States'
                and
                    ca_state in ('SD', 'WI', 'NE')
                and ws_net_profit between 50 and 250
            )
    )
group by r_reason_desc
order by substr(r_reason_desc, 1, 20)
       , avg(ws_quantity)
       , avg(wr_refunded_cash)
       , avg(wr_fee) LIMIT 100;
