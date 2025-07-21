{% macro cast_string_clean(column_name, type, upper=false) %}
    {%- set col = "trim(" ~ column_name ~ ")" %}
    {%- if upper %}
        {%- set col = "upper(" ~ col ~ ")" %}
    {%- endif %}
    cast( nullif({{ col }},'') as {{ type }})
{% endmacro %}

--=======================================================

{% macro cast_number_clean(column_name, type='numeric(20,4)') %}
    cast(replace(trim(cast({{ column_name }} as varchar)), ',', '') as {{ type }})
{% endmacro %}