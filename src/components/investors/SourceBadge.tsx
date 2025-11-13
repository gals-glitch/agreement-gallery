/**
 * SourceBadge Component
 * Displays investor source type with color-coded badge
 * Ticket: FE-101
 * Date: 2025-10-19
 */

import { Badge } from '@/components/ui/badge';
import { Building2, User, Minus, Database } from 'lucide-react';
import { InvestorSourceKind } from '@/types/investors';

interface SourceBadgeProps {
  sourceKind: InvestorSourceKind;
  className?: string;
}

const SOURCE_CONFIG: Record<InvestorSourceKind, {
  label: string;
  variant: 'default' | 'secondary' | 'outline' | 'destructive';
  icon: React.ComponentType<{ className?: string }>;
  className: string;
}> = {
  DISTRIBUTOR: {
    label: 'Distributor',
    variant: 'default',
    icon: Building2,
    className: 'bg-blue-100 text-blue-800 hover:bg-blue-100 border-blue-300',
  },
  REFERRER: {
    label: 'Referrer',
    variant: 'secondary',
    icon: User,
    className: 'bg-green-100 text-green-800 hover:bg-green-100 border-green-300',
  },
  NONE: {
    label: 'None',
    variant: 'outline',
    icon: Minus,
    className: 'bg-gray-50 text-gray-600 hover:bg-gray-50 border-gray-300',
  },
  vantage: {
    label: 'Vantage IR',
    variant: 'secondary',
    icon: Database,
    className: 'bg-purple-100 text-purple-800 hover:bg-purple-100 border-purple-300',
  },
};

export function SourceBadge({ sourceKind, className }: SourceBadgeProps) {
  const config = SOURCE_CONFIG[sourceKind];
  const Icon = config.icon;

  return (
    <Badge
      variant={config.variant}
      className={`${config.className} ${className || ''} inline-flex items-center gap-1.5 px-2.5 py-0.5 text-xs font-medium`}
    >
      <Icon className="h-3 w-3" />
      {config.label}
    </Badge>
  );
}
