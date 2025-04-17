\timing on

-- 查询1 (原query1.tpl)
with customer_total_return as
         (select sr_customer_sk             as ctr_customer_sk
               , sr_store_sk                as ctr_store_sk
               , sum(SR_RETURN_AMT_INC_TAX) as ctr_total_return
          from store_returns
             , date_dim
          where sr_returned_date_sk = d_date_sk
            and d_year = 1999
          group by sr_customer_sk
                 , sr_store_sk)
select c_customer_id
from customer_total_return ctr1
   , store
   , customer
where ctr1.ctr_total_return > (select avg(ctr_total_return) * 1.2
                               from customer_total_return ctr2
                               where ctr1.ctr_store_sk = ctr2.ctr_store_sk)
  and s_store_sk = ctr1.ctr_store_sk
  and s_state = 'TN'
  and ctr1.ctr_customer_sk = c_customer_sk
order by c_customer_id LIMIT 100;

-- 查询3 (原query3.tpl)
select dt.d_year
     , item.i_brand_id    brand_id
     , item.i_brand       brand
     , sum(ss_net_profit) sum_agg
from date_dim dt
   , store_sales
   , item
where dt.d_date_sk = store_sales.ss_sold_date_sk
  and store_sales.ss_item_sk = item.i_item_sk
  and item.i_manufact_id = 445
  and dt.d_moy = 12
group by dt.d_year
       , item.i_brand
       , item.i_brand_id
order by dt.d_year
       , sum_agg desc
       , brand_id LIMIT 100;

-- 查询7 (原query7.tpl)
select i_item_id,
       avg(ss_quantity)    agg1,
       avg(ss_list_price)  agg2,
       avg(ss_coupon_amt)  agg3,
       avg(ss_sales_price) agg4
from store_sales,
     customer_demographics,
     date_dim,
     item,
     promotion
where ss_sold_date_sk = d_date_sk
  and ss_item_sk = i_item_sk
  and ss_cdemo_sk = cd_demo_sk
  and ss_promo_sk = p_promo_sk
  and cd_gender = 'M'
  and cd_marital_status = 'M'
  and cd_education_status = '4 yr Degree'
  and (p_channel_email = 'N' or p_channel_event = 'N')
  and d_year = 2001
group by i_item_id
order by i_item_id LIMIT 100;

-- 查询9 (原query9.tpl)
select case
           when (select count(*)
                 from store_sales
                 where ss_quantity between 1 and 20) > 31002
               then (select avg(ss_ext_discount_amt)
                     from store_sales
                     where ss_quantity between 1 and 20)
           else (select avg(ss_net_profit)
                 from store_sales
                 where ss_quantity between 1 and 20) end   bucket1,
       case
           when (select count(*)
                 from store_sales
                 where ss_quantity between 21 and 40) > 588
               then (select avg(ss_ext_discount_amt)
                     from store_sales
                     where ss_quantity between 21 and 40)
           else (select avg(ss_net_profit)
                 from store_sales
                 where ss_quantity between 21 and 40) end  bucket2,
       case
           when (select count(*)
                 from store_sales
                 where ss_quantity between 41 and 60) > 2456
               then (select avg(ss_ext_discount_amt)
                     from store_sales
                     where ss_quantity between 41 and 60)
           else (select avg(ss_net_profit)
                 from store_sales
                 where ss_quantity between 41 and 60) end  bucket3,
       case
           when (select count(*)
                 from store_sales
                 where ss_quantity between 61 and 80) > 21645
               then (select avg(ss_ext_discount_amt)
                     from store_sales
                     where ss_quantity between 61 and 80)
           else (select avg(ss_net_profit)
                 from store_sales
                 where ss_quantity between 61 and 80) end  bucket4,
       case
           when (select count(*)
                 from store_sales
                 where ss_quantity between 81 and 100) > 20553
               then (select avg(ss_ext_discount_amt)
                     from store_sales
                     where ss_quantity between 81 and 100)
           else (select avg(ss_net_profit)
                 from store_sales
                 where ss_quantity between 81 and 100) end bucket5
from reason
where r_reason_sk = 1
;

-- 查询10 (原query10.tpl)
select cd_gender,
       cd_marital_status,
       cd_education_status,
       count(*) cnt1,
       cd_purchase_estimate,
       count(*) cnt2,
       cd_credit_rating,
       count(*) cnt3,
       cd_dep_count,
       count(*) cnt4,
       cd_dep_employed_count,
       count(*) cnt5,
       cd_dep_college_count,
       count(*) cnt6
from customer c,
     customer_address ca,
     customer_demographics
where c.c_current_addr_sk = ca.ca_address_sk
  and ca_county in ('Clinton County', 'Platte County', 'Franklin County', 'Louisa County', 'Harmon County')
  and cd_demo_sk = c.c_current_cdemo_sk
  and exists (select *
              from store_sales,
                   date_dim
              where c.c_customer_sk = ss_customer_sk
                and ss_sold_date_sk = d_date_sk
                and d_year = 2002
                and d_moy between 3 and 3 + 3)
  and (exists (select *
               from web_sales,
                    date_dim
               where c.c_customer_sk = ws_bill_customer_sk
                 and ws_sold_date_sk = d_date_sk
                 and d_year = 2002
                 and d_moy between 3 ANd 3 + 3) or
       exists (select *
               from catalog_sales,
                    date_dim
               where c.c_customer_sk = cs_ship_customer_sk
                 and cs_sold_date_sk = d_date_sk
                 and d_year = 2002
                 and d_moy between 3 and 3 + 3))
group by cd_gender,
         cd_marital_status,
         cd_education_status,
         cd_purchase_estimate,
         cd_credit_rating,
         cd_dep_count,
         cd_dep_employed_count,
         cd_dep_college_count
order by cd_gender,
         cd_marital_status,
         cd_education_status,
         cd_purchase_estimate,
         cd_credit_rating,
         cd_dep_count,
         cd_dep_employed_count,
         cd_dep_college_count LIMIT 100;

-- 查询11 (原query11.tpl)
with year_total as (select c_customer_id                                customer_id
                         , c_first_name                                 customer_first_name
                         , c_last_name                                  customer_last_name
                         , c_preferred_cust_flag                        customer_preferred_cust_flag
                         , c_birth_country                              customer_birth_country
                         , c_login                                      customer_login
                         , c_email_address                              customer_email_address
                         , d_year                                       dyear
                         , sum(ss_ext_list_price - ss_ext_discount_amt) year_total
                         , 's'                                          sale_type
                    from customer
                       , store_sales
                       , date_dim
                    where c_customer_sk = ss_customer_sk
                      and ss_sold_date_sk = d_date_sk
                    group by c_customer_id
                           , c_first_name
                           , c_last_name
                           , c_preferred_cust_flag
                           , c_birth_country
                           , c_login
                           , c_email_address
                           , d_year
                    union all
                    select c_customer_id                                customer_id
                         , c_first_name                                 customer_first_name
                         , c_last_name                                  customer_last_name
                         , c_preferred_cust_flag                        customer_preferred_cust_flag
                         , c_birth_country                              customer_birth_country
                         , c_login                                      customer_login
                         , c_email_address                              customer_email_address
                         , d_year                                       dyear
                         , sum(ws_ext_list_price - ws_ext_discount_amt) year_total
                         , 'w'                                          sale_type
                    from customer
                       , web_sales
                       , date_dim
                    where c_customer_sk = ws_bill_customer_sk
                      and ws_sold_date_sk = d_date_sk
                    group by c_customer_id
                           , c_first_name
                           , c_last_name
                           , c_preferred_cust_flag
                           , c_birth_country
                           , c_login
                           , c_email_address
                           , d_year)
select t_s_secyear.customer_id
     , t_s_secyear.customer_first_name
     , t_s_secyear.customer_last_name
     , t_s_secyear.customer_email_address
from year_total t_s_firstyear
   , year_total t_s_secyear
   , year_total t_w_firstyear
   , year_total t_w_secyear
where t_s_secyear.customer_id = t_s_firstyear.customer_id
  and t_s_firstyear.customer_id = t_w_secyear.customer_id
  and t_s_firstyear.customer_id = t_w_firstyear.customer_id
  and t_s_firstyear.sale_type = 's'
  and t_w_firstyear.sale_type = 'w'
  and t_s_secyear.sale_type = 's'
  and t_w_secyear.sale_type = 'w'
  and t_s_firstyear.dyear = 1999
  and t_s_secyear.dyear = 1999 + 1
  and t_w_firstyear.dyear = 1999
  and t_w_secyear.dyear = 1999 + 1
  and t_s_firstyear.year_total > 0
  and t_w_firstyear.year_total > 0
  and case when t_w_firstyear.year_total > 0 then t_w_secyear.year_total / t_w_firstyear.year_total else 0.0 end
    > case when t_s_firstyear.year_total > 0 then t_s_secyear.year_total / t_s_firstyear.year_total else 0.0 end
order by t_s_secyear.customer_id
       , t_s_secyear.customer_first_name
       , t_s_secyear.customer_last_name
       , t_s_secyear.customer_email_address LIMIT 100;

-- 查询16 (原query16.tpl)
select count(distinct cs_order_number) as "order count"
     , sum(cs_ext_ship_cost)           as "total shipping cost"
     , sum(cs_net_profit)              as "total net profit"
from catalog_sales cs1
   , date_dim
   , customer_address
   , call_center
where d_date between '1999-5-01' and
    (cast('1999-5-01' as date) + 60 days)
  and cs1.cs_ship_date_sk = d_date_sk
  and cs1.cs_ship_addr_sk = ca_address_sk
  and ca_state = 'ID'
  and cs1.cs_call_center_sk = cc_call_center_sk
  and cc_county in ('Williamson County', 'Williamson County', 'Williamson County', 'Williamson County',
                    'Williamson County'
    )
  and exists (select *
              from catalog_sales cs2
              where cs1.cs_order_number = cs2.cs_order_number
                and cs1.cs_warehouse_sk <> cs2.cs_warehouse_sk)
  and not exists(select *
                 from catalog_returns cr1
                 where cs1.cs_order_number = cr1.cr_order_number)
order by count(distinct cs_order_number) LIMIT 100;

-- 查询17 (原query17.tpl)
select i_item_id
     , i_item_desc
     , s_state
     , count(ss_quantity)                                        as store_sales_quantitycount
     , avg(ss_quantity)                                          as store_sales_quantityave
     , stddev_samp(ss_quantity)                                  as store_sales_quantitystdev
     , stddev_samp(ss_quantity) / avg(ss_quantity)               as store_sales_quantitycov
     , count(sr_return_quantity)                                 as store_returns_quantitycount
     , avg(sr_return_quantity)                                   as store_returns_quantityave
     , stddev_samp(sr_return_quantity)                           as store_returns_quantitystdev
     , stddev_samp(sr_return_quantity) / avg(sr_return_quantity) as store_returns_quantitycov
     , count(cs_quantity)                                        as catalog_sales_quantitycount
     , avg(cs_quantity)                                          as catalog_sales_quantityave
     , stddev_samp(cs_quantity)                                  as catalog_sales_quantitystdev
     , stddev_samp(cs_quantity) / avg(cs_quantity)               as catalog_sales_quantitycov
from store_sales
   , store_returns
   , catalog_sales
   , date_dim d1
   , date_dim d2
   , date_dim d3
   , store
   , item
where d1.d_quarter_name = '1999Q1'
  and d1.d_date_sk = ss_sold_date_sk
  and i_item_sk = ss_item_sk
  and s_store_sk = ss_store_sk
  and ss_customer_sk = sr_customer_sk
  and ss_item_sk = sr_item_sk
  and ss_ticket_number = sr_ticket_number
  and sr_returned_date_sk = d2.d_date_sk
  and d2.d_quarter_name in ('1999Q1', '1999Q2', '1999Q3')
  and sr_customer_sk = cs_bill_customer_sk
  and sr_item_sk = cs_item_sk
  and cs_sold_date_sk = d3.d_date_sk
  and d3.d_quarter_name in ('1999Q1', '1999Q2', '1999Q3')
group by i_item_id
       , i_item_desc
       , s_state
order by i_item_id
       , i_item_desc
       , s_state LIMIT 100;

-- 查询19 (原query19.tpl)
select i_brand_id              brand_id,
       i_brand                 brand,
       i_manufact_id,
       i_manufact,
       sum(ss_ext_sales_price) ext_price
from date_dim,
     store_sales,
     item,
     customer,
     customer_address,
     store
where d_date_sk = ss_sold_date_sk
  and ss_item_sk = i_item_sk
  and i_manager_id = 8
  and d_moy = 11
  and d_year = 1999
  and ss_customer_sk = c_customer_sk
  and c_current_addr_sk = ca_address_sk
  and substr(ca_zip, 1, 5) <> substr(s_zip, 1, 5)
  and ss_store_sk = s_store_sk
group by i_brand
       , i_brand_id
       , i_manufact_id
       , i_manufact
order by ext_price desc
       , i_brand
       , i_brand_id
       , i_manufact_id
       , i_manufact LIMIT 100;

-- 查询21 (原query21.tpl)
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
      from inventory
         , warehouse
         , item
         , date_dim
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

-- 查询25 (原query25.tpl)
select i_item_id
     , i_item_desc
     , s_store_id
     , s_store_name
     , min(ss_net_profit) as store_sales_profit
     , min(sr_net_loss)   as store_returns_loss
     , min(cs_net_profit) as catalog_sales_profit
from store_sales
   , store_returns
   , catalog_sales
   , date_dim d1
   , date_dim d2
   , date_dim d3
   , store
   , item
where d1.d_moy = 4
  and d1.d_year = 2002
  and d1.d_date_sk = ss_sold_date_sk
  and i_item_sk = ss_item_sk
  and s_store_sk = ss_store_sk
  and ss_customer_sk = sr_customer_sk
  and ss_item_sk = sr_item_sk
  and ss_ticket_number = sr_ticket_number
  and sr_returned_date_sk = d2.d_date_sk
  and d2.d_moy between 4 and 10
  and d2.d_year = 2002
  and sr_customer_sk = cs_bill_customer_sk
  and sr_item_sk = cs_item_sk
  and cs_sold_date_sk = d3.d_date_sk
  and d3.d_moy between 4 and 10
  and d3.d_year = 2002
group by i_item_id
       , i_item_desc
       , s_store_id
       , s_store_name
order by i_item_id
       , i_item_desc
       , s_store_id
       , s_store_name LIMIT 100;

-- 查询27 (原query27.tpl)
select i_item_id,
       s_state,
       grouping(s_state)   g_state,
       avg(ss_quantity)    agg1,
       avg(ss_list_price)  agg2,
       avg(ss_coupon_amt)  agg3,
       avg(ss_sales_price) agg4
from store_sales,
     customer_demographics,
     date_dim,
     store,
     item
where ss_sold_date_sk = d_date_sk
  and ss_item_sk = i_item_sk
  and ss_store_sk = s_store_sk
  and ss_cdemo_sk = cd_demo_sk
  and cd_gender = 'M'
  and cd_marital_status = 'U'
  and cd_education_status = 'Secondary'
  and d_year = 2000
  and s_state in ('TN', 'TN', 'TN', 'TN', 'TN', 'TN')
group by rollup (i_item_id, s_state)
order by i_item_id
       , s_state LIMIT 100;

-- 查询28 (原query28.tpl)
select *
from (select avg(ss_list_price)            B1_LP
           , count(ss_list_price)          B1_CNT
           , count(distinct ss_list_price) B1_CNTD
      from store_sales
      where ss_quantity between 0 and 5
        and (ss_list_price between 28 and 28 + 10
          or ss_coupon_amt between 12573 and 12573 + 1000
          or ss_wholesale_cost between 33 and 33 + 20)) B1,
     (select avg(ss_list_price)            B2_LP
           , count(ss_list_price)          B2_CNT
           , count(distinct ss_list_price) B2_CNTD
      from store_sales
      where ss_quantity between 6 and 10
        and (ss_list_price between 143 and 143 + 10
          or ss_coupon_amt between 5562 and 5562 + 1000
          or ss_wholesale_cost between 45 and 45 + 20)) B2,
     (select avg(ss_list_price)            B3_LP
           , count(ss_list_price)          B3_CNT
           , count(distinct ss_list_price) B3_CNTD
      from store_sales
      where ss_quantity between 11 and 15
        and (ss_list_price between 159 and 159 + 10
          or ss_coupon_amt between 2807 and 2807 + 1000
          or ss_wholesale_cost between 24 and 24 + 20)) B3,
     (select avg(ss_list_price)            B4_LP
           , count(ss_list_price)          B4_CNT
           , count(distinct ss_list_price) B4_CNTD
      from store_sales
      where ss_quantity between 16 and 20
        and (ss_list_price between 24 and 24 + 10
          or ss_coupon_amt between 3706 and 3706 + 1000
          or ss_wholesale_cost between 46 and 46 + 20)) B4,
     (select avg(ss_list_price)            B5_LP
           , count(ss_list_price)          B5_CNT
           , count(distinct ss_list_price) B5_CNTD
      from store_sales
      where ss_quantity between 21 and 25
        and (ss_list_price between 76 and 76 + 10
          or ss_coupon_amt between 2096 and 2096 + 1000
          or ss_wholesale_cost between 50 and 50 + 20)) B5,
     (select avg(ss_list_price)            B6_LP
           , count(ss_list_price)          B6_CNT
           , count(distinct ss_list_price) B6_CNTD
      from store_sales
      where ss_quantity between 26 and 30
        and (ss_list_price between 169 and 169 + 10
          or ss_coupon_amt between 10672 and 10672 + 1000
          or ss_wholesale_cost between 58 and 58 + 20)) B6 LIMIT 100;

-- 查询31 (原query31.tpl)
with ss as
         (select ca_county, d_qoy, d_year, sum(ss_ext_sales_price) as store_sales
          from store_sales,
               date_dim,
               customer_address
          where ss_sold_date_sk = d_date_sk
            and ss_addr_sk = ca_address_sk
          group by ca_county, d_qoy, d_year),
     ws as
         (select ca_county, d_qoy, d_year, sum(ws_ext_sales_price) as web_sales
          from web_sales,
               date_dim,
               customer_address
          where ws_sold_date_sk = d_date_sk
            and ws_bill_addr_sk = ca_address_sk
          group by ca_county, d_qoy, d_year)
select ss1.ca_county
     , ss1.d_year
     , ws2.web_sales / ws1.web_sales     web_q1_q2_increase
     , ss2.store_sales / ss1.store_sales store_q1_q2_increase
     , ws3.web_sales / ws2.web_sales     web_q2_q3_increase
     , ss3.store_sales / ss2.store_sales store_q2_q3_increase
from ss ss1
   , ss ss2
   , ss ss3
   , ws ws1
   , ws ws2
   , ws ws3
where ss1.d_qoy = 1
  and ss1.d_year = 1999
  and ss1.ca_county = ss2.ca_county
  and ss2.d_qoy = 2
  and ss2.d_year = 1999
  and ss2.ca_county = ss3.ca_county
  and ss3.d_qoy = 3
  and ss3.d_year = 1999
  and ss1.ca_county = ws1.ca_county
  and ws1.d_qoy = 1
  and ws1.d_year = 1999
  and ws1.ca_county = ws2.ca_county
  and ws2.d_qoy = 2
  and ws2.d_year = 1999
  and ws1.ca_county = ws3.ca_county
  and ws3.d_qoy = 3
  and ws3.d_year = 1999
  and case when ws1.web_sales > 0 then ws2.web_sales / ws1.web_sales else null end
    > case when ss1.store_sales > 0 then ss2.store_sales / ss1.store_sales else null end
  and case when ws2.web_sales > 0 then ws3.web_sales / ws2.web_sales else null end
    > case when ss2.store_sales > 0 then ss3.store_sales / ss2.store_sales else null end
order by ss1.ca_county;

-- 查询32 (原query32.tpl)
select sum(cs_ext_discount_amt) as "excess discount amount"
from catalog_sales
   , item
   , date_dim
where i_manufact_id = 283
  and i_item_sk = cs_item_sk
  and d_date between '1999-02-22' and
    (cast('1999-02-22' as date) + 90 days)
  and d_date_sk = cs_sold_date_sk
  and cs_ext_discount_amt
    > (select 1.3 * avg(cs_ext_discount_amt)
       from catalog_sales
          , date_dim
       where cs_item_sk = i_item_sk
         and d_date between '1999-02-22' and
           (cast('1999-02-22' as date) + 90 days)
         and d_date_sk = cs_sold_date_sk)
    LIMIT 100;

-- 查询33 (原query33.tpl)
with ss as (select i_manufact_id,
                   sum(ss_ext_sales_price) total_sales
            from store_sales,
                 date_dim,
                 customer_address,
                 item
            where i_manufact_id in (select i_manufact_id
                                    from item
                                    where i_category in ('Books'))
              and ss_item_sk = i_item_sk
              and ss_sold_date_sk = d_date_sk
              and d_year = 1999
              and d_moy = 4
              and ss_addr_sk = ca_address_sk
              and ca_gmt_offset = -5
            group by i_manufact_id),
     cs as (select i_manufact_id,
                   sum(cs_ext_sales_price) total_sales
            from catalog_sales,
                 date_dim,
                 customer_address,
                 item
            where i_manufact_id in (select i_manufact_id
                                    from item
                                    where i_category in ('Books'))
              and cs_item_sk = i_item_sk
              and cs_sold_date_sk = d_date_sk
              and d_year = 1999
              and d_moy = 4
              and cs_bill_addr_sk = ca_address_sk
              and ca_gmt_offset = -5
            group by i_manufact_id),
     ws as (select i_manufact_id,
                   sum(ws_ext_sales_price) total_sales
            from web_sales,
                 date_dim,
                 customer_address,
                 item
            where i_manufact_id in (select i_manufact_id
                                    from item
                                    where i_category in ('Books'))
              and ws_item_sk = i_item_sk
              and ws_sold_date_sk = d_date_sk
              and d_year = 1999
              and d_moy = 4
              and ws_bill_addr_sk = ca_address_sk
              and ca_gmt_offset = -5
            group by i_manufact_id)
select i_manufact_id, sum(total_sales) total_sales
from (select *
      from ss
      union all
      select *
      from cs
      union all
      select *
      from ws) tmp1
group by i_manufact_id
order by total_sales LIMIT 100;

-- 查询35 (原query35.tpl)
select ca_state,
       cd_gender,
       cd_marital_status,
       cd_dep_count,
       count(*) cnt1,
       max(cd_dep_count),
       stddev_samp(cd_dep_count),
       stddev_samp(cd_dep_count),
       cd_dep_employed_count,
       count(*) cnt2,
       max(cd_dep_employed_count),
       stddev_samp(cd_dep_employed_count),
       stddev_samp(cd_dep_employed_count),
       cd_dep_college_count,
       count(*) cnt3,
       max(cd_dep_college_count),
       stddev_samp(cd_dep_college_count),
       stddev_samp(cd_dep_college_count)
from customer c,
     customer_address ca,
     customer_demographics
where c.c_current_addr_sk = ca.ca_address_sk
  and cd_demo_sk = c.c_current_cdemo_sk
  and exists (select *
              from store_sales,
                   date_dim
              where c.c_customer_sk = ss_customer_sk
                and ss_sold_date_sk = d_date_sk
                and d_year = 2000
                and d_qoy < 4)
  and (exists (select *
               from web_sales,
                    date_dim
               where c.c_customer_sk = ws_bill_customer_sk
                 and ws_sold_date_sk = d_date_sk
                 and d_year = 2000
                 and d_qoy < 4) or
       exists (select *
               from catalog_sales,
                    date_dim
               where c.c_customer_sk = cs_ship_customer_sk
                 and cs_sold_date_sk = d_date_sk
                 and d_year = 2000
                 and d_qoy < 4))
group by ca_state,
         cd_gender,
         cd_marital_status,
         cd_dep_count,
         cd_dep_employed_count,
         cd_dep_college_count
order by ca_state,
         cd_gender,
         cd_marital_status,
         cd_dep_count,
         cd_dep_employed_count,
         cd_dep_college_count LIMIT 100;

-- 查询36 (原query36.tpl)
select sum(ss_net_profit) / sum(ss_ext_sales_price) as gross_margin
     , i_category
     , i_class
     , grouping(i_category) + grouping(i_class)     as lochierarchy
     , rank()                                          over (
 	partition by grouping(i_category)+grouping(i_class),
 	case when grouping(i_class) = 0 then i_category end
 	order by sum(ss_net_profit)/sum(ss_ext_sales_price) asc) as rank_within_parent
from store_sales
   , date_dim d1
   , item
   , store
where d1.d_year = 2001
  and d1.d_date_sk = ss_sold_date_sk
  and i_item_sk = ss_item_sk
  and s_store_sk = ss_store_sk
  and s_state in ('TN', 'TN', 'TN', 'TN',
                  'TN', 'TN', 'TN', 'TN')
group by rollup (i_category, i_class)
order by lochierarchy desc
       , case when lochierarchy = 0 then i_category end
       , rank_within_parent LIMIT 100;

-- 查询37 (原query37.tpl)
select i_item_id
     , i_item_desc
     , i_current_price
from item,
     inventory,
     date_dim,
     catalog_sales
where i_current_price between 26 and 26 + 30
  and inv_item_sk = i_item_sk
  and d_date_sk = inv_date_sk
  and d_date between cast('2001-06-09' as date) and (cast('2001-06-09' as date) + 60 days)
  and i_manufact_id in (744, 884, 722, 693)
  and inv_quantity_on_hand between 100 and 500
  and cs_item_sk = i_item_sk
group by i_item_id, i_item_desc, i_current_price
order by i_item_id LIMIT 100;

-- 查询39 (原query39.tpl)
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
                from inventory
                   , item
                   , warehouse
                   , date_dim
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

-- 查询43 (原query43.tpl)
select s_store_name,
       s_store_id,
       sum(case when (d_day_name = 'Sunday') then ss_sales_price else null end)    sun_sales,
       sum(case when (d_day_name = 'Monday') then ss_sales_price else null end)    mon_sales,
       sum(case when (d_day_name = 'Tuesday') then ss_sales_price else null end)   tue_sales,
       sum(case when (d_day_name = 'Wednesday') then ss_sales_price else null end) wed_sales,
       sum(case when (d_day_name = 'Thursday') then ss_sales_price else null end)  thu_sales,
       sum(case when (d_day_name = 'Friday') then ss_sales_price else null end)    fri_sales,
       sum(case when (d_day_name = 'Saturday') then ss_sales_price else null end)  sat_sales
from date_dim,
     store_sales,
     store
where d_date_sk = ss_sold_date_sk
  and s_store_sk = ss_store_sk
  and s_gmt_offset = -5
  and d_year = 2000
group by s_store_name, s_store_id
order by s_store_name, s_store_id, sun_sales, mon_sales, tue_sales, wed_sales, thu_sales, fri_sales,
         sat_sales LIMIT 100;

-- 查询44 (原query44.tpl)
select asceding.rnk, i1.i_product_name best_performing, i2.i_product_name worst_performing
from (select *
      from (select item_sk, rank() over (order by rank_col asc) rnk
            from (select ss_item_sk item_sk, avg(ss_net_profit) rank_col
                  from store_sales ss1
                  where ss_store_sk = 6
                  group by ss_item_sk
                  having avg(ss_net_profit) > 0.9 * (select avg(ss_net_profit) rank_col
                                                     from store_sales
                                                     where ss_store_sk = 6
                                                       and ss_hdemo_sk is null
                                                     group by ss_store_sk)) V1) V11
      where rnk < 11) asceding,
     (select *
      from (select item_sk, rank() over (order by rank_col desc) rnk
            from (select ss_item_sk item_sk, avg(ss_net_profit) rank_col
                  from store_sales ss1
                  where ss_store_sk = 6
                  group by ss_item_sk
                  having avg(ss_net_profit) > 0.9 * (select avg(ss_net_profit) rank_col
                                                     from store_sales
                                                     where ss_store_sk = 6
                                                       and ss_hdemo_sk is null
                                                     group by ss_store_sk)) V2) V21
      where rnk < 11) descending,
     item i1,
     item i2
where asceding.rnk = descending.rnk
  and i1.i_item_sk = asceding.item_sk
  and i2.i_item_sk = descending.item_sk
order by asceding.rnk LIMIT 100;

-- 查询45 (原query45.tpl)
select ca_zip, ca_city, sum(ws_sales_price)
from web_sales,
     customer,
     customer_address,
     date_dim,
     item
where ws_bill_customer_sk = c_customer_sk
  and c_current_addr_sk = ca_address_sk
  and ws_item_sk = i_item_sk
  and (substr(ca_zip, 1, 5) in ('85669', '86197', '88274', '83405', '86475', '85392', '85460', '80348', '81792')
    or
       i_item_id in (select i_item_id
                     from item
                     where i_item_sk in (2, 3, 5, 7, 11, 13, 17, 19, 23, 29))
    )
  and ws_sold_date_sk = d_date_sk
  and d_qoy = 2
  and d_year = 2000
group by ca_zip, ca_city
order by ca_zip, ca_city LIMIT 100;

-- 查询46 (原query46.tpl)
select c_last_name
     , c_first_name
     , ca_city
     , bought_city
     , ss_ticket_number
     , amt
     , profit
from (select ss_ticket_number
           , ss_customer_sk
           , ca_city            bought_city
           , sum(ss_coupon_amt) amt
           , sum(ss_net_profit) profit
      from store_sales,
           date_dim,
           store,
           household_demographics,
           customer_address
      where store_sales.ss_sold_date_sk = date_dim.d_date_sk
        and store_sales.ss_store_sk = store.s_store_sk
        and store_sales.ss_hdemo_sk = household_demographics.hd_demo_sk
        and store_sales.ss_addr_sk = customer_address.ca_address_sk
        and (household_demographics.hd_dep_count = 3 or
             household_demographics.hd_vehicle_count = 1)
        and date_dim.d_dow in (6, 0)
        and date_dim.d_year in (1999, 1999 + 1, 1999 + 2)
        and store.s_city in ('Midway', 'Fairview', 'Fairview', 'Midway', 'Fairview')
      group by ss_ticket_number, ss_customer_sk, ss_addr_sk, ca_city) dn,
     customer,
     customer_address current_addr
where ss_customer_sk = c_customer_sk
  and customer.c_current_addr_sk = current_addr.ca_address_sk
  and current_addr.ca_city <> bought_city
order by c_last_name
       , c_first_name
       , ca_city
       , bought_city
       , ss_ticket_number LIMIT 100;

-- 查询47 (原query47.tpl)
with v1 as (select i_category,
                   i_brand,
                   s_store_name,
                   s_company_name,
                   d_year,
                   d_moy,
                   sum(ss_sales_price)      sum_sales,
                   avg(sum(ss_sales_price)) over (partition by i_category, i_brand,
                     s_store_name, s_company_name, d_year)
          avg_monthly_sales, rank() over (partition by i_category, i_brand,
                     s_store_name, s_company_name
           order by d_year, d_moy) rn
            from item,
                 store_sales,
                 date_dim,
                 store
            where ss_item_sk = i_item_sk
              and ss_sold_date_sk = d_date_sk
              and ss_store_sk = s_store_sk
              and (
                        d_year = 2001 or
                        (d_year = 2001 - 1 and d_moy = 12) or
                        (d_year = 2001 + 1 and d_moy = 1)
                )
            group by i_category, i_brand,
                     s_store_name, s_company_name,
                     d_year, d_moy),
     v2 as (select v1.i_category
                 , v1.i_brand
                 , v1.s_store_name
                 , v1.s_company_name
                 , v1.d_year
                 , v1.avg_monthly_sales
                 , v1.sum_sales
                 , v1_lag.sum_sales  psum
                 , v1_lead.sum_sales nsum
            from v1,
                 v1 v1_lag,
                 v1 v1_lead
            where v1.i_category = v1_lag.i_category
              and v1.i_category = v1_lead.i_category
              and v1.i_brand = v1_lag.i_brand
              and v1.i_brand = v1_lead.i_brand
              and v1.s_store_name = v1_lag.s_store_name
              and v1.s_store_name = v1_lead.s_store_name
              and v1.s_company_name = v1_lag.s_company_name
              and v1.s_company_name = v1_lead.s_company_name
              and v1.rn = v1_lag.rn + 1
              and v1.rn = v1_lead.rn - 1)
select *
from v2
where d_year = 2001
  and avg_monthly_sales > 0
  and case when avg_monthly_sales > 0 then abs(sum_sales - avg_monthly_sales) / avg_monthly_sales else null end > 0.1
order by sum_sales - avg_monthly_sales, nsum LIMIT 100;

-- 查询49 (原query49.tpl)
select channel, item, return_ratio, return_rank, currency_rank
from (select 'web' as channel
           , web.item
           , web.return_ratio
           , web.return_rank
           , web.currency_rank
      from (select item
                 , return_ratio
                 , currency_ratio
                 , rank() over (order by return_ratio) as return_rank
 	,rank() over (order by currency_ratio) as currency_rank
            from (select ws.ws_item_sk                                              as item
                       , (cast(sum(coalesce(wr.wr_return_quantity, 0)) as decimal(15, 4)) /
                          cast(sum(coalesce(ws.ws_quantity, 0)) as decimal(15, 4))) as return_ratio
                       , (cast(sum(coalesce(wr.wr_return_amt, 0)) as decimal(15, 4)) /
                          cast(sum(coalesce(ws.ws_net_paid, 0)) as decimal(15, 4))) as currency_ratio
                  from web_sales ws
                           left outer join web_returns wr
                                           on (ws.ws_order_number = wr.wr_order_number and
                                               ws.ws_item_sk = wr.wr_item_sk)
                     , date_dim
                  where wr.wr_return_amt > 10000
                    and ws.ws_net_profit > 1
                    and ws.ws_net_paid > 0
                    and ws.ws_quantity > 0
                    and ws_sold_date_sk = d_date_sk
                    and d_year = 2000
                    and d_moy = 12
                  group by ws.ws_item_sk) in_web) web
      where (
                        web.return_rank <= 10
                    or
                        web.currency_rank <= 10
                )
      union
      select 'catalog' as channel
           , catalog.item
           , catalog.return_ratio
           , catalog.return_rank
           , catalog.currency_rank
      from (select item
                 , return_ratio
                 , currency_ratio
                 , rank() over (order by return_ratio) as return_rank
 	,rank() over (order by currency_ratio) as currency_rank
            from (select cs.cs_item_sk                                              as item
                       , (cast(sum(coalesce(cr.cr_return_quantity, 0)) as decimal(15, 4)) /
                          cast(sum(coalesce(cs.cs_quantity, 0)) as decimal(15, 4))) as return_ratio
                       , (cast(sum(coalesce(cr.cr_return_amount, 0)) as decimal(15, 4)) /
                          cast(sum(coalesce(cs.cs_net_paid, 0)) as decimal(15, 4))) as currency_ratio
                  from catalog_sales cs
                           left outer join catalog_returns cr
                                           on (cs.cs_order_number = cr.cr_order_number and
                                               cs.cs_item_sk = cr.cr_item_sk)
                     , date_dim
                  where cr.cr_return_amount > 10000
                    and cs.cs_net_profit > 1
                    and cs.cs_net_paid > 0
                    and cs.cs_quantity > 0
                    and cs_sold_date_sk = d_date_sk
                    and d_year = 2000
                    and d_moy = 12
                  group by cs.cs_item_sk) in_cat) catalog
      where
          (
          catalog.return_rank <= 10
         or
          catalog.currency_rank <=10
          )
      union
      select
          'store' as channel
              , store.item
              , store.return_ratio
              , store.return_rank
              , store.currency_rank
      from (
          select
          item
              , return_ratio
              , currency_ratio
              , rank() over (order by return_ratio) as return_rank
              , rank() over (order by currency_ratio) as currency_rank
          from
          ( select sts.ss_item_sk as item
              , (cast (sum (coalesce (sr.sr_return_quantity, 0)) as decimal (15, 4))/ cast (sum (coalesce (sts.ss_quantity, 0)) as decimal (15, 4) )) as return_ratio
              , (cast (sum (coalesce (sr.sr_return_amt, 0)) as decimal (15, 4))/ cast (sum (coalesce (sts.ss_net_paid, 0)) as decimal (15, 4) )) as currency_ratio
          from
          store_sales sts left outer join store_returns sr
          on (sts.ss_ticket_number = sr.sr_ticket_number and sts.ss_item_sk = sr.sr_item_sk)
              , date_dim
          where
          sr.sr_return_amt > 10000
          and sts.ss_net_profit > 1
          and sts.ss_net_paid > 0
          and sts.ss_quantity > 0
          and ss_sold_date_sk = d_date_sk
          and d_year = 2000
          and d_moy = 12
          group by sts.ss_item_sk
          ) in_store
          ) store
      where (
          store.return_rank <= 10
         or
          store.currency_rank <= 10
          ))
order by 1, 4, 5, 2 LIMIT 100;

-- 查询51 (原query51.tpl)
WITH web_v1 as (select ws_item_sk item_sk,
                       d_date,
                       sum(sum(ws_sales_price))
                                  over (partition by ws_item_sk order by d_date rows between unbounded preceding and current row) cume_sales
                from web_sales
                   , date_dim
                where ws_sold_date_sk = d_date_sk
                  and d_month_seq between 1215 and 1215 + 11
                  and ws_item_sk is not NULL
                group by ws_item_sk, d_date),
     store_v1 as (select ss_item_sk item_sk,
                         d_date,
                         sum(sum(ss_sales_price))
                                    over (partition by ss_item_sk order by d_date rows between unbounded preceding and current row) cume_sales
                  from store_sales
                     , date_dim
                  where ss_sold_date_sk = d_date_sk
                    and d_month_seq between 1215 and 1215 + 11
                    and ss_item_sk is not NULL
                  group by ss_item_sk, d_date)
select *
from (select item_sk
           , d_date
           , web_sales
           , store_sales
           , max(web_sales)
        over
          (partition by item_sk order by d_date rows between unbounded preceding and current row) web_cumulative
     ,max(store_sales)
            over (partition by item_sk order by d_date rows between unbounded preceding and current row) store_cumulative
      from (select case when web.item_sk is not null then web.item_sk else store.item_sk end item_sk
                 , case when web.d_date is not null then web.d_date else store.d_date end    d_date
                 , web.cume_sales                                                            web_sales
                 , store.cume_sales                                                          store_sales
            from web_v1 web
                     full outer join store_v1 store on (web.item_sk = store.item_sk
                and web.d_date = store.d_date)) x) y
where web_cumulative > store_cumulative
order by item_sk
       , d_date LIMIT 100;

-- 查询58 (原query58.tpl)
with ss_items as
         (select i_item_id               item_id
               , sum(ss_ext_sales_price) ss_item_rev
          from store_sales
             , item
             , date_dim
          where ss_item_sk = i_item_sk
            and d_date in (select d_date
                           from date_dim
                           where d_week_seq = (select d_week_seq
                                               from date_dim
                                               where d_date = '2000-02-12'))
            and ss_sold_date_sk = d_date_sk
          group by i_item_id),
     cs_items as
         (select i_item_id               item_id
               , sum(cs_ext_sales_price) cs_item_rev
          from catalog_sales
             , item
             , date_dim
          where cs_item_sk = i_item_sk
            and d_date in (select d_date
                           from date_dim
                           where d_week_seq = (select d_week_seq
                                               from date_dim
                                               where d_date = '2000-02-12'))
            and cs_sold_date_sk = d_date_sk
          group by i_item_id),
     ws_items as
         (select i_item_id               item_id
               , sum(ws_ext_sales_price) ws_item_rev
          from web_sales
             , item
             , date_dim
          where ws_item_sk = i_item_sk
            and d_date in (select d_date
                           from date_dim
                           where d_week_seq = (select d_week_seq
                                               from date_dim
                                               where d_date = '2000-02-12'))
            and ws_sold_date_sk = d_date_sk
          group by i_item_id)
select ss_items.item_id
     , ss_item_rev
     , ss_item_rev / ((ss_item_rev + cs_item_rev + ws_item_rev) / 3) * 100 ss_dev
     , cs_item_rev
     , cs_item_rev / ((ss_item_rev + cs_item_rev + ws_item_rev) / 3) * 100 cs_dev
     , ws_item_rev
     , ws_item_rev / ((ss_item_rev + cs_item_rev + ws_item_rev) / 3) * 100 ws_dev
     , (ss_item_rev + cs_item_rev + ws_item_rev) / 3                       average
from ss_items,
     cs_items,
     ws_items
where ss_items.item_id = cs_items.item_id
  and ss_items.item_id = ws_items.item_id
  and ss_item_rev between 0.9 * cs_item_rev and 1.1 * cs_item_rev
  and ss_item_rev between 0.9 * ws_item_rev and 1.1 * ws_item_rev
  and cs_item_rev between 0.9 * ss_item_rev and 1.1 * ss_item_rev
  and cs_item_rev between 0.9 * ws_item_rev and 1.1 * ws_item_rev
  and ws_item_rev between 0.9 * ss_item_rev and 1.1 * ss_item_rev
  and ws_item_rev between 0.9 * cs_item_rev and 1.1 * cs_item_rev
order by item_id
       , ss_item_rev LIMIT 100;

-- 查询78 (原query78.tpl)
with ws as
         (select d_year AS              ws_sold_year,
                 ws_item_sk,
                 ws_bill_customer_sk    ws_customer_sk,
                 sum(ws_quantity)       ws_qty,
                 sum(ws_wholesale_cost) ws_wc,
                 sum(ws_sales_price)    ws_sp
          from web_sales ws1
                   left join web_returns wr on wr_order_number = ws1.ws_order_number and ws1.ws_item_sk = wr.wr_item_sk
                   join date_dim on ws1.ws_sold_date_sk = d_date_sk
          where wr_order_number is null
          group by d_year, ws1.ws_item_sk, ws1.ws_bill_customer_sk),
     cs as
         (select d_year AS              cs_sold_year,
                 cs_item_sk,
                 cs_bill_customer_sk    cs_customer_sk,
                 sum(cs_quantity)       cs_qty,
                 sum(cs_wholesale_cost) cs_wc,
                 sum(cs_sales_price)    cs_sp
          from catalog_sales cs1
                   left join catalog_returns cr on cr_order_number = cs1.cs_order_number and cs1.cs_item_sk = cr.cr_item_sk
                   join date_dim on cs1.cs_sold_date_sk = d_date_sk
          where cr_order_number is null
          group by d_year, cs1.cs_item_sk, cs1.cs_bill_customer_sk),
     ss as
         (select d_year AS              ss_sold_year,
                 ss_item_sk,
                 ss_customer_sk,
                 sum(ss_quantity)       ss_qty,
                 sum(ss_wholesale_cost) ss_wc,
                 sum(ss_sales_price)    ss_sp
          from store_sales ss1
                   left join store_returns sr on sr_ticket_number = ss1.ss_ticket_number and ss1.ss_item_sk = sr.sr_item_sk
                   join date_dim on ss1.ss_sold_date_sk = d_date_sk
          where sr_ticket_number is null
          group by d_year, ss1.ss_item_sk, ss1.ss_customer_sk)
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

-- 查询80 (原query80.tpl)
with ssr as
         (select s_store_id                                    as store_id,
                 sum(ss_ext_sales_price)                       as sales,
                 sum(coalesce(sr_return_amt, 0))               as returns,
                 sum(ss_net_profit - coalesce(sr_net_loss, 0)) as profit
          from store_sales
                   left outer join store_returns on
              (ss_item_sk = sr_item_sk and ss_ticket_number = sr_ticket_number),
               date_dim,
               store,
               item,
               promotion
          where ss_sold_date_sk = d_date_sk
            and d_date between cast('2002-08-04' as date)
              and (cast('2002-08-04' as date) + 30 days)
            and ss_store_sk = s_store_sk
            and ss_item_sk = i_item_sk
            and i_current_price > 50
            and ss_promo_sk = p_promo_sk
            and p_channel_tv = 'N'
          group by s_store_id),
     csr as
         (select cp_catalog_page_id                            as catalog_page_id,
                 sum(cs_ext_sales_price)                       as sales,
                 sum(coalesce(cr_return_amount, 0))            as returns,
                 sum(cs_net_profit - coalesce(cr_net_loss, 0)) as profit
          from catalog_sales cs1
                   left outer join catalog_returns cr on cr_order_number = cs1.cs_order_number and cs1.cs_item_sk = cr.cr_item_sk
                   join date_dim on cs1.cs_sold_date_sk = d_date_sk
          where d_date between cast('2002-08-04' as date)
            and (cast('2002-08-04' as date) + 30 days)
            and cs_catalog_page_sk = cp_catalog_page_sk
            and cs_item_sk = i_item_sk
            and i_current_price > 50
            and cs_promo_sk = p_promo_sk
            and p_channel_tv = 'N'
          group by cp_catalog_page_id),
     wsr as
         (select web_site_id,
                 sum(ws_ext_sales_price)                       as sales,
                 sum(coalesce(wr_return_amt, 0))               as returns,
                 sum(ws_net_profit - coalesce(wr_net_loss, 0)) as profit
          from web_sales ws1
                   left outer join web_returns wr on wr_order_number = ws1.ws_order_number and ws1.ws_item_sk = wr.wr_item_sk
                   join date_dim on ws1.ws_sold_date_sk = d_date_sk
          where d_date between cast('2002-08-04' as date)
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

-- 查询86 (原query86.tpl)
select sum(ws_net_paid)                         as total_sum
     , i_category
     , i_class
     , grouping(i_category) + grouping(i_class) as lochierarchy
     , rank()                                      over (
 	partition by grouping(i_category)+grouping(i_class),
 	case when grouping(i_class) = 0 then i_category end
 	order by sum(ws_net_paid) desc) as rank_within_parent
from web_sales
   , date_dim d1
   , item
where d1.d_month_seq between 1205 and 1205 + 11
  and d1.d_date_sk = ws_sold_date_sk
  and i_item_sk = ws_item_sk
group by rollup (i_category, i_class)
order by lochierarchy desc,
         case when lochierarchy = 0 then i_category end,
         rank_within_parent LIMIT 100;

-- 查询95 (原query95.tpl)
with ws_wh as
         (select ws1.ws_order_number, ws1.ws_warehouse_sk wh1, ws2.ws_warehouse_sk wh2
          from web_sales ws1,
               web_sales ws2
          where ws1.ws_order_number = ws2.ws_order_number
            and ws1.ws_warehouse_sk <> ws2.ws_warehouse_sk)
select count(distinct ws_order_number) as "order count"
     , sum(ws_ext_ship_cost)           as "total shipping cost"
     , sum(ws_net_profit)              as "total net profit"
from web_sales ws1
   , date_dim
   , customer_address
   , web_site
where d_date between '2002-5-01' and
    (cast('2002-5-01' as date) + 60 days)
  and ws1.ws_ship_date_sk = d_date_sk
  and ws1.ws_ship_addr_sk = ca_address_sk
  and ca_state = 'MA'
  and ws1.ws_web_site_sk = web_site_sk
  and web_company_name = 'pri'
  and ws1.ws_order_number in (select ws_order_number
                              from ws_wh)
  and ws1.ws_order_number in (select wr_order_number
                              from web_returns,
                                   ws_wh
                              where wr_order_number = ws_wh.ws_order_number)
order by count(distinct ws_order_number) LIMIT 100;

-- 查询96 (原query96.tpl)
select count(*)
from store_sales
   , household_demographics
   , time_dim
   , store
where ss_sold_time_sk = time_dim.t_time_sk
  and ss_hdemo_sk = household_demographics.hd_demo_sk
  and ss_store_sk = s_store_sk
  and time_dim.t_hour = 8
  and time_dim.t_minute >= 30
  and household_demographics.hd_dep_count = 5
  and store.s_store_name = 'ese'
order by count(*) LIMIT 100; 