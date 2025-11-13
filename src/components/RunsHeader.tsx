import React from 'react';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { Progress } from '@/components/ui/progress';
import { Play, Calendar, Clock, AlertTriangle } from 'lucide-react';
import { FeeRun } from '@/types/runs';

interface RunsHeaderProps {
  selectedRun?: FeeRun | null;
  onStartCalculation?: () => void;
  onCreateRun?: () => void;
  progress?: number;
}

const getStatusColor = (status: FeeRun['status']) => {
  switch (status) {
    case 'draft': return 'bg-gray-500/10 text-gray-700 border-gray-200';
    case 'reviewed': return 'bg-blue-500/10 text-blue-700 border-blue-200';
    case 'approved': return 'bg-green-500/10 text-green-700 border-green-200';
    case 'exported': return 'bg-purple-500/10 text-purple-700 border-purple-200';
    case 'failed': return 'bg-red-500/10 text-red-700 border-red-200';
    default: return 'bg-gray-500/10 text-gray-700 border-gray-200';
  }
};

export function RunsHeader({ selectedRun, onStartCalculation, onCreateRun, progress }: RunsHeaderProps) {
  if (!selectedRun) {
    return (
      <Card className="mb-6">
        <CardContent className="py-4">
          <div className="flex items-center justify-between">
            <div>
              <h3 className="text-lg font-semibold text-muted-foreground">No run selected</h3>
              <p className="text-sm text-muted-foreground">Create a new run or select from history</p>
            </div>
            <Button onClick={onCreateRun} className="gap-2">
              <Calendar className="w-4 h-4" />
              Create New Run
            </Button>
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card className="mb-6">
      <CardContent className="py-4">
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-4">
            <div>
              <div className="flex items-center gap-2 mb-1">
                <h3 className="text-lg font-semibold">{selectedRun.cut_off_label}</h3>
                <Badge className={getStatusColor(selectedRun.status)}>
                  {selectedRun.status.charAt(0).toUpperCase() + selectedRun.status.slice(1)}
                </Badge>
              </div>
              <div className="flex items-center gap-4 text-sm text-muted-foreground">
                <span className="flex items-center gap-1">
                  <Calendar className="w-4 h-4" />
                  {selectedRun.period_start} to {selectedRun.period_end}
                </span>
                <span>Run ID: {selectedRun.id}</span>
                {selectedRun.exceptions_count ? (
                  <span className="flex items-center gap-1 text-amber-600">
                    <AlertTriangle className="w-4 h-4" />
                    {selectedRun.exceptions_count} exceptions
                  </span>
                ) : null}
              </div>
            </div>
          </div>
          
          <div className="flex items-center gap-2">
            {selectedRun.status === 'draft' && (
              <Button onClick={onStartCalculation} className="gap-2">
                <Play className="w-4 h-4" />
                Start Calculation
              </Button>
            )}
            <Button variant="outline" onClick={onCreateRun} className="gap-2">
              <Calendar className="w-4 h-4" />
              New Run
            </Button>
          </div>
        </div>

        {/* Progress bar for active calculations */}
        {progress !== undefined && progress > 0 && progress < 100 && (
          <div className="space-y-2">
            <div className="flex items-center justify-between text-sm">
              <span className="flex items-center gap-1 text-muted-foreground">
                <Clock className="w-4 h-4" />
                Calculation in progress...
              </span>
              <span className="font-medium">{progress}%</span>
            </div>
            <Progress value={progress} className="h-2" />
          </div>
        )}

        {/* Summary totals for completed runs */}
        {selectedRun.totals && (
          <div className="flex items-center gap-6 mt-4 pt-4 border-t text-sm">
            <div>
              <span className="text-muted-foreground">Gross: </span>
              <span className="font-medium">${selectedRun.totals.base.toLocaleString()}</span>
            </div>
            <div>
              <span className="text-muted-foreground">VAT: </span>
              <span className="font-medium">${selectedRun.totals.vat.toLocaleString()}</span>
            </div>
            <div>
              <span className="text-muted-foreground">Net: </span>
              <span className="font-medium">${selectedRun.totals.net.toLocaleString()}</span>
            </div>
            <div>
              <span className="text-muted-foreground">Total: </span>
              <span className="font-semibold text-primary">${selectedRun.totals.total.toLocaleString()}</span>
            </div>
          </div>
        )}
      </CardContent>
    </Card>
  );
}