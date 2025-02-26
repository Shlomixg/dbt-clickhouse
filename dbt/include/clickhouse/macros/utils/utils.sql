{% macro clickhouse__any_value(expression) -%}
    any({{ expression }})
{%- endmacro %}


{% macro clickhouse__bool_or(expression) -%}
    any({{ expression }}) > 0
{%- endmacro %}


{% macro clickhouse__cast_bool_to_text(field) %}
    multiIf({{ field }} > 0, 'true', {{ field }} = 0, 'false', NULL)
{% endmacro %}


{% macro clickhouse__hash(field) -%}
    lower(hex(MD5(toString({{ field }} ))))
{%- endmacro %}


{%- macro clickhouse__last_day(date, datepart) -%}
    {{ dbt.dateadd('day', '-1', dbt.dateadd(datepart, '1', dbt.date_trunc(datepart, date)))}}
{%- endmacro -%}


{% macro clickhouse__split_part(string_text, delimiter_text, part_number) %}
    splitByChar('{{delimiter_text}}', {{ string_text }})[{{ part_number }}]
{% endmacro %}


{% macro clickhouse__replace(field, old_chars, new_chars) %}
   replaceAll({{ field }},'{{ old_chars }}','{{ new_chars }}')
{% endmacro %}


{% macro clickhouse__listagg(measure, delimiter_text, order_by_clause, limit_num) %}
  {{ exceptions.raise_compiler_error(
    'ClickHouse does not support the listagg function.  See the groupArray function instead')
    }}
{% endmacro %}


{% macro clickhouse__array_construct(inputs, data_type) -%}
    {% if inputs|length > 0 %}
    [ {{ inputs|join(' , ') }} ]
    {% else %}
    emptyArray{{data_type}}()
    {% endif %}
{%- endmacro %}


{% macro clickhouse__array_append(array, new_element) -%}
    arrayPushBack({{ array }}, {{ new_element }})
{% endmacro %}


{% macro clickhouse__array_concat(array_1, array_2) -%}
   arrayConcat({{ array_1 }}, {{ array_2 }})
{% endmacro %}

{% macro clickhouse__inner_join_with_buckets(table_1, table_2, join_bucket_alias, table_2_keys, join_on_clause='', num_of_buckets=16) -%}
    {%- for bucket in range(num_of_buckets) %}
    select *
    from {{ table_1 }}
    join (
        select
            *,
            cityHash64({{ table_2_keys }}) % {{ num_of_buckets }} as bucket_num
        from {{ table_2 }}
        where bucket_num = {{ bucket }}
    ) as {{ join_bucket_alias }} on 
    {{ join_on_clause }}
    {% if not loop.last %}
    union all
    {% endif %}
    {%- endfor %}
{% endmacro %}
