-- Fix the foreign key relationship between distributor_rules and advanced_commission_rules
ALTER TABLE public.distributor_rules 
ADD CONSTRAINT fk_distributor_rules_rule_id 
FOREIGN KEY (rule_id) REFERENCES public.advanced_commission_rules(id);

-- Add foreign key for sub_agents to entities table  
ALTER TABLE public.sub_agents 
ADD CONSTRAINT fk_sub_agents_distributor_id 
FOREIGN KEY (distributor_id) REFERENCES public.entities(id);