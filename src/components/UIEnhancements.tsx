import React, { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from '@/components/ui/dropdown-menu';
import { Progress } from '@/components/ui/progress';
import { MoreHorizontal, Download, FileText, AlertCircle, CheckCircle, Clock, Play } from 'lucide-react';
import { useToast } from '@/hooks/use-toast';

interface RunContextBannerProps {
  draftRun?: {
    id: string;
    name: string;
    status: string;
    progress: number;
  };
  onOpenRun?: (runId: string) => void;
}

export function RunContextBanner({ draftRun, onOpenRun }: RunContextBannerProps) {
  const { toast } = useToast();

  if (!draftRun) return null;

  const getStatusIcon = () => {
    switch (draftRun.status) {
      case 'calculating':
        return <Clock className="h-4 w-4 text-blue-500" />;
      case 'completed':
        return <CheckCircle className="h-4 w-4 text-green-500" />;
      case 'failed':
        return <AlertCircle className="h-4 w-4 text-red-500" />;
      default:
        return <FileText className="h-4 w-4 text-gray-500" />;
    }
  };

  const getStatusColor = () => {
    switch (draftRun.status) {
      case 'calculating':
        return 'bg-blue-50 border-blue-200';
      case 'completed':
        return 'bg-green-50 border-green-200';
      case 'failed':
        return 'bg-red-50 border-red-200';
      default:
        return 'bg-gray-50 border-gray-200';
    }
  };

  return (
    <Alert className={`mb-4 ${getStatusColor()}`}>
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          {getStatusIcon()}
          <div className="flex-1">
            <AlertDescription className="flex items-center gap-2">
              <span className="font-medium">Open Run:</span>
              <span>{draftRun.name}</span>
              <Badge variant="outline" className="text-xs">
                {draftRun.status}
              </Badge>
            </AlertDescription>
            {draftRun.status === 'calculating' && (
              <div className="mt-2 flex items-center gap-2">
                <Progress value={draftRun.progress} className="flex-1 max-w-xs" />
                <span className="text-xs text-muted-foreground">{draftRun.progress}%</span>
              </div>
            )}
          </div>
        </div>
        <div className="flex items-center gap-2">
          <Button 
            variant="outline" 
            size="sm"
            onClick={() => onOpenRun?.(draftRun.id)}
          >
            <Play className="h-3 w-3 mr-1" />
            Open Run
          </Button>
        </div>
      </div>
    </Alert>
  );
}

interface JobsIconProps {
  pendingCount?: number;
  onClick?: () => void;
}

export function JobsIcon({ pendingCount = 0, onClick }: JobsIconProps) {
  return (
    <Button
      variant="ghost"
      size="sm"
      className="relative"
      onClick={onClick}
      title="View import/calculation/export jobs"
    >
      <FileText className="h-4 w-4" />
      {pendingCount > 0 && (
        <Badge 
          variant="destructive" 
          className="absolute -top-1 -right-1 h-5 w-5 rounded-full p-0 text-xs flex items-center justify-center"
        >
          {pendingCount > 9 ? '9+' : pendingCount}
        </Badge>
      )}
    </Button>
  );
}

interface ExportShortcutMenuProps {
  calculationRunId: string;
  entityName: string;
  onExport: (type: 'summary' | 'detail' | 'vat' | 'audit') => void;
  disabled?: boolean;
}

export function ExportShortcutMenu({ calculationRunId, entityName, onExport, disabled }: ExportShortcutMenuProps) {
  const { toast } = useToast();

  const handleExport = (type: 'summary' | 'detail' | 'vat' | 'audit') => {
    if (disabled) {
      toast({
        title: "Export Unavailable",
        description: "Complete calculations first to enable exports",
        variant: "destructive"
      });
      return;
    }
    onExport(type);
    toast({
      title: "Export Started",
      description: `Generating ${type} report for ${entityName}...`
    });
  };

  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button 
          variant="ghost" 
          size="sm" 
          className="h-8 w-8 p-0"
          disabled={disabled}
          title="Export options"
        >
          <MoreHorizontal className="h-4 w-4" />
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end" className="w-48 bg-background border shadow-lg">
        <DropdownMenuItem onClick={() => handleExport('summary')} className="flex items-center gap-2">
          <Download className="h-3 w-3" />
          Export Summary
        </DropdownMenuItem>
        <DropdownMenuItem onClick={() => handleExport('detail')} className="flex items-center gap-2">
          <Download className="h-3 w-3" />
          Export Detail
        </DropdownMenuItem>
        <DropdownMenuItem onClick={() => handleExport('vat')} className="flex items-center gap-2">
          <Download className="h-3 w-3" />
          Export VAT/Tax
        </DropdownMenuItem>
        <DropdownMenuItem onClick={() => handleExport('audit')} className="flex items-center gap-2">
          <Download className="h-3 w-3" />
          Export Audit Trail
        </DropdownMenuItem>
      </DropdownMenuContent>
    </DropdownMenu>
  );
}

interface RoundingDisclosureProps {
  grossTotal: number;
  netTotal: number;
  vatTotal: number;
  onViewDetails?: () => void;
}

export function RoundingDisclosure({ grossTotal, netTotal, vatTotal, onViewDetails }: RoundingDisclosureProps) {
  // Calculate if there's a meaningful rounding difference
  const calculatedNet = grossTotal + vatTotal;
  const roundingDiff = Math.abs(calculatedNet - netTotal);
  
  if (roundingDiff < 0.005) return null; // Less than half a cent
  
  return (
    <Alert className="mt-2">
      <AlertCircle className="h-4 w-4" />
      <AlertDescription className="flex items-center justify-between">
        <span className="text-xs">
          Rounding adjustment: ${roundingDiff.toFixed(2)}
        </span>
        {onViewDetails && (
          <Button 
            variant="link" 
            size="sm" 
            className="h-auto p-0 text-xs"
            onClick={onViewDetails}
          >
            View Details
          </Button>
        )}
      </AlertDescription>
    </Alert>
  );
}