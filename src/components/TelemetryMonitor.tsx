import React, { useState, useEffect } from 'react';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Progress } from '@/components/ui/progress';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Activity, Clock, AlertTriangle, CheckCircle, TrendingUp, Database } from 'lucide-react';

interface TelemetryMetric {
  name: string;
  value: number;
  unit: string;
  target?: number;
  status: 'good' | 'warning' | 'critical';
  trend: 'up' | 'down' | 'stable';
  category: 'performance' | 'business' | 'quality';
}

interface TelemetryEvent {
  timestamp: string;
  event: string;
  value: number;
  metadata?: Record<string, any>;
}

export function TelemetryMonitor() {
  const [metrics, setMetrics] = useState<TelemetryMetric[]>([
    // Performance metrics
    {
      name: 'Import Validation Time',
      value: 45000,
      unit: 'ms',
      target: 60000,
      status: 'good',
      trend: 'down',
      category: 'performance'
    },
    {
      name: 'Calculation Run Time',
      value: 120000,
      unit: 'ms', 
      target: 300000,
      status: 'good',
      trend: 'stable',
      category: 'performance'
    },
    {
      name: 'Export Write Time',
      value: 8000,
      unit: 'ms',
      target: 30000,
      status: 'good',
      trend: 'down',
      category: 'performance'
    },
    
    // Business metrics
    {
      name: 'Calculation Lines Processed',
      value: 85000,
      unit: 'lines',
      status: 'good',
      trend: 'up',
      category: 'business'
    },
    {
      name: 'Cap Hit Count',
      value: 12,
      unit: 'caps',
      status: 'good',
      trend: 'up',
      category: 'business'
    },
    {
      name: 'VAT Mode Distribution',
      value: 65,
      unit: '% added',
      status: 'good',
      trend: 'stable',
      category: 'business'
    },
    
    // Quality metrics
    {
      name: 'Job Failure Rate',
      value: 2.1,
      unit: '%',
      target: 5,
      status: 'good',
      trend: 'down',
      category: 'quality'
    },
    {
      name: 'Replay Mismatch Count',
      value: 0,
      unit: 'mismatches',
      target: 0,
      status: 'good',
      trend: 'stable',
      category: 'quality'
    },
    {
      name: 'Export Reconcile Diff',
      value: 0.02,
      unit: 'USD',
      target: 1.00,
      status: 'good',
      trend: 'stable',
      category: 'quality'
    }
  ]);

  const [recentEvents, setRecentEvents] = useState<TelemetryEvent[]>([
    {
      timestamp: new Date(Date.now() - 5 * 60000).toISOString(),
      event: 'calc.run.completed',
      value: 125000,
      metadata: { lines: 45000, run_id: 'calc_123' }
    },
    {
      timestamp: new Date(Date.now() - 10 * 60000).toISOString(),
      event: 'import.validate.completed',
      value: 42000,
      metadata: { rows: 10000, errors: 0 }
    },
    {
      timestamp: new Date(Date.now() - 15 * 60000).toISOString(),
      event: 'export.write.completed',
      value: 7500,
      metadata: { type: 'summary', size_mb: 2.3 }
    },
    {
      timestamp: new Date(Date.now() - 20 * 60000).toISOString(),
      event: 'cap.hit.detected',
      value: 1,
      metadata: { entity: 'Distributor_5', cap_amount: 1000000 }
    },
    {
      timestamp: new Date(Date.now() - 25 * 60000).toISOString(),
      event: 'vat.mode.applied',
      value: 1,
      metadata: { mode: 'added', rate: 0.17, jurisdiction: 'IL' }
    }
  ]);

  // Simulate real-time updates
  useEffect(() => {
    const interval = setInterval(() => {
      // Randomly update some metrics
      setMetrics(prev => prev.map(metric => {
        if (Math.random() < 0.3) { // 30% chance to update
          const variance = (Math.random() - 0.5) * 0.1; // ±5% variance
          const newValue = Math.max(0, metric.value * (1 + variance));
          
          let status: TelemetryMetric['status'] = 'good';
          if (metric.target) {
            if (metric.name.includes('Rate') || metric.name.includes('Count')) {
              status = newValue > metric.target ? 'critical' : 'good';
            } else {
              status = newValue > metric.target ? 'warning' : 'good';
            }
          }
          
          return {
            ...metric,
            value: newValue,
            status,
            trend: newValue > metric.value ? 'up' : newValue < metric.value ? 'down' : 'stable'
          };
        }
        return metric;
      }));
      
      // Add new events occasionally
      if (Math.random() < 0.2) {
        const events = [
          'calc.run.started',
          'import.validate.started', 
          'export.write.started',
          'cap.threshold.approached',
          'reconcile.diff.detected'
        ];
        
        const newEvent: TelemetryEvent = {
          timestamp: new Date().toISOString(),
          event: events[Math.floor(Math.random() * events.length)],
          value: Math.random() * 100000,
          metadata: { simulated: true }
        };
        
        setRecentEvents(prev => [newEvent, ...prev.slice(0, 19)]); // Keep last 20
      }
    }, 5000);

    return () => clearInterval(interval);
  }, []);

  const getStatusIcon = (status: TelemetryMetric['status']) => {
    switch (status) {
      case 'good': return <CheckCircle className="h-4 w-4 text-green-500" />;
      case 'warning': return <AlertTriangle className="h-4 w-4 text-yellow-500" />;
      case 'critical': return <AlertTriangle className="h-4 w-4 text-red-500" />;
    }
  };

  const getTrendIcon = (trend: TelemetryMetric['trend']) => {
    switch (trend) {
      case 'up': return <TrendingUp className="h-3 w-3 text-green-500" />;
      case 'down': return <TrendingUp className="h-3 w-3 text-red-500 rotate-180" />;
      case 'stable': return <div className="h-3 w-3 bg-gray-400 rounded-full" />;
    }
  };

  const formatValue = (value: number, unit: string) => {
    if (unit === 'ms') {
      return value > 1000 ? `${(value / 1000).toFixed(1)}s` : `${Math.round(value)}ms`;
    }
    if (unit === 'lines' && value > 1000) {
      return `${(value / 1000).toFixed(1)}k`;
    }
    if (unit === '%') {
      return `${value.toFixed(1)}%`;
    }
    if (unit === 'USD') {
      return `$${value.toFixed(2)}`;
    }
    return `${Math.round(value)} ${unit}`;
  };

  const performanceMetrics = metrics.filter(m => m.category === 'performance');
  const businessMetrics = metrics.filter(m => m.category === 'business');
  const qualityMetrics = metrics.filter(m => m.category === 'quality');

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold flex items-center gap-2">
            <Activity className="h-6 w-6" />
            Telemetry Monitor
          </h2>
          <p className="text-muted-foreground">Real-time performance and business metrics</p>
        </div>
        <Badge variant="outline" className="flex items-center gap-1">
          <div className="h-2 w-2 bg-green-500 rounded-full animate-pulse" />
          Live
        </Badge>
      </div>

      <Tabs defaultValue="overview" className="space-y-4">
        <TabsList>
          <TabsTrigger value="overview">Overview</TabsTrigger>
          <TabsTrigger value="performance">Performance</TabsTrigger>
          <TabsTrigger value="business">Business</TabsTrigger>
          <TabsTrigger value="quality">Quality</TabsTrigger>
          <TabsTrigger value="events">Events</TabsTrigger>
        </TabsList>

        <TabsContent value="overview" className="space-y-4">
          <div className="grid grid-cols-3 gap-4">
            <Card>
              <CardHeader className="pb-2">
                <CardTitle className="text-sm text-muted-foreground">Performance</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-2">
                  {performanceMetrics.slice(0, 3).map((metric) => (
                    <div key={metric.name} className="flex items-center justify-between">
                      <span className="text-xs">{metric.name.split(' ')[0]}</span>
                      <div className="flex items-center gap-1">
                        {getStatusIcon(metric.status)}
                        <span className="text-xs font-medium">{formatValue(metric.value, metric.unit)}</span>
                      </div>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="pb-2">
                <CardTitle className="text-sm text-muted-foreground">Business</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-2">
                  {businessMetrics.slice(0, 3).map((metric) => (
                    <div key={metric.name} className="flex items-center justify-between">
                      <span className="text-xs">{metric.name.split(' ')[0]}</span>
                      <div className="flex items-center gap-1">
                        {getTrendIcon(metric.trend)}
                        <span className="text-xs font-medium">{formatValue(metric.value, metric.unit)}</span>
                      </div>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="pb-2">
                <CardTitle className="text-sm text-muted-foreground">Quality</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-2">
                  {qualityMetrics.slice(0, 3).map((metric) => (
                    <div key={metric.name} className="flex items-center justify-between">
                      <span className="text-xs">{metric.name.split(' ')[0]}</span>
                      <div className="flex items-center gap-1">
                        {getStatusIcon(metric.status)}
                        <span className="text-xs font-medium">{formatValue(metric.value, metric.unit)}</span>
                      </div>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        <TabsContent value="performance" className="space-y-4">
          <div className="grid gap-4">
            {performanceMetrics.map((metric) => (
              <Card key={metric.name}>
                <CardHeader className="pb-3">
                  <div className="flex items-center justify-between">
                    <CardTitle className="text-lg">{metric.name}</CardTitle>
                    <div className="flex items-center gap-2">
                      {getStatusIcon(metric.status)}
                      {getTrendIcon(metric.trend)}
                    </div>
                  </div>
                </CardHeader>
                <CardContent>
                  <div className="space-y-2">
                    <div className="flex justify-between">
                      <span className="text-sm text-muted-foreground">Current</span>
                      <span className="font-medium">{formatValue(metric.value, metric.unit)}</span>
                    </div>
                    {metric.target && (
                      <>
                        <div className="flex justify-between">
                          <span className="text-sm text-muted-foreground">Target</span>
                          <span className="text-sm">{formatValue(metric.target, metric.unit)}</span>
                        </div>
                        <Progress 
                          value={Math.min(100, (metric.value / metric.target) * 100)} 
                          className="mt-2"
                        />
                      </>
                    )}
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        </TabsContent>

        <TabsContent value="business" className="space-y-4">
          <div className="grid gap-4">
            {businessMetrics.map((metric) => (
              <Card key={metric.name}>
                <CardHeader className="pb-3">
                  <div className="flex items-center justify-between">
                    <CardTitle className="text-lg">{metric.name}</CardTitle>
                    <div className="flex items-center gap-2">
                      {getTrendIcon(metric.trend)}
                      <Badge variant="outline">{formatValue(metric.value, metric.unit)}</Badge>
                    </div>
                  </div>
                </CardHeader>
              </Card>
            ))}
          </div>
        </TabsContent>

        <TabsContent value="quality" className="space-y-4">
          <div className="grid gap-4">
            {qualityMetrics.map((metric) => (
              <Card key={metric.name}>
                <CardHeader className="pb-3">
                  <div className="flex items-center justify-between">
                    <CardTitle className="text-lg">{metric.name}</CardTitle>
                    <div className="flex items-center gap-2">
                      {getStatusIcon(metric.status)}
                      <Badge variant={metric.status === 'good' ? 'default' : 'destructive'}>
                        {formatValue(metric.value, metric.unit)}
                      </Badge>
                    </div>
                  </div>
                </CardHeader>
                <CardContent>
                  {metric.target && (
                    <div className="space-y-2">
                      <div className="flex justify-between text-sm">
                        <span className="text-muted-foreground">Target: {formatValue(metric.target, metric.unit)}</span>
                        <span className={metric.value <= metric.target ? 'text-green-600' : 'text-red-600'}>
                          {metric.value <= metric.target ? 'Within target' : 'Exceeds target'}
                        </span>
                      </div>
                    </div>
                  )}
                </CardContent>
              </Card>
            ))}
          </div>
        </TabsContent>

        <TabsContent value="events" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Clock className="h-4 w-4" />
                Recent Events
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-2">
                {recentEvents.map((event, index) => (
                  <div key={index} className="flex items-center justify-between py-2 border-b last:border-b-0">
                    <div>
                      <span className="font-medium text-sm">{event.event}</span>
                      <div className="text-xs text-muted-foreground">
                        {new Date(event.timestamp).toLocaleTimeString()}
                      </div>
                    </div>
                    <div className="text-right">
                      <div className="text-sm font-medium">
                        {event.event.includes('time') || event.event.includes('completed') ? 
                          formatValue(event.value, 'ms') : 
                          Math.round(event.value)
                        }
                      </div>
                      {event.metadata && (
                        <div className="text-xs text-muted-foreground">
                          {Object.entries(event.metadata).slice(0, 2).map(([key, value]) => 
                            `${key}: ${value}`
                          ).join(', ')}
                        </div>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
}