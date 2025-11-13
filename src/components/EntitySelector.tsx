import React, { useState, useEffect } from 'react';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Label } from '@/components/ui/label';
import { Button } from '@/components/ui/button';
import { Plus } from 'lucide-react';
import { supabase } from '@/integrations/supabase/client';

interface Party {
  id: string;
  name: string;
  party_type: string;
  is_active: boolean;
}

interface EntitySelectorProps {
  entityType: 'distributor' | 'referrer' | 'partner';
  value?: string;
  onValueChange: (value: string) => void;
  label?: string;
  placeholder?: string;
  required?: boolean;
}

export function EntitySelector({
  entityType,
  value,
  onValueChange,
  label,
  placeholder,
  required = false
}: EntitySelectorProps) {
  const [entities, setEntities] = useState<Party[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchEntities();
  }, [entityType]);

  const fetchEntities = async () => {
    try {
      const { data, error } = await supabase
        .from('parties')
        .select('id, name, party_type, is_active')
        .eq('active', true)
        .order('name');

      if (error) throw error;
      setEntities(data || []);
    } catch (error) {
      console.error('Error fetching entities:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleAddNew = () => {
    window.open('/parties', '_blank');
  };

  const displayLabel = label || `${entityType.charAt(0).toUpperCase()}${entityType.slice(1)}`;
  const displayPlaceholder = placeholder || `Select ${entityType}`;

  return (
    <div className="space-y-2">
      <div className="flex items-center justify-between">
        <Label>
          {displayLabel}
          {required && <span className="text-destructive ml-1">*</span>}
        </Label>
        <Button
          type="button"
          variant="outline"
          size="sm"
          onClick={handleAddNew}
          className="h-6 px-2 text-xs"
        >
          <Plus className="w-3 h-3 mr-1" />
          Add New
        </Button>
      </div>
      
      <Select value={value} onValueChange={onValueChange} required={required}>
        <SelectTrigger>
          <SelectValue placeholder={loading ? "Loading..." : displayPlaceholder} />
        </SelectTrigger>
        <SelectContent>
          {entities.length === 0 && !loading && (
            <SelectItem value="" disabled>
              No active {entityType}s found
            </SelectItem>
          )}
          {entities.map((entity) => (
            <SelectItem key={entity.id} value={entity.id}>
              {entity.name}
            </SelectItem>
          ))}
        </SelectContent>
      </Select>
    </div>
  );
}