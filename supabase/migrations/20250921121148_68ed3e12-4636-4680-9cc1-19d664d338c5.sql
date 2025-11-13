-- Fix function search path security warning
CREATE OR REPLACE FUNCTION get_vat_rate(country TEXT, calculation_date DATE)
RETURNS DECIMAL(5,4)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT rate 
  FROM vat_rates 
  WHERE country_code = country 
    AND effective_from <= calculation_date 
    AND (effective_to IS NULL OR effective_to >= calculation_date)
  ORDER BY effective_from DESC 
  LIMIT 1;
$$;