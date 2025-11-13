import React from 'react';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Button } from '@/components/ui/button';
import { ArrowLeft } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { EnhancedValidationDashboard } from '@/components/EnhancedValidationDashboard';
import { TestFixtureGenerator } from '@/components/TestFixtureGenerator';
import { TelemetryMonitor } from '@/components/TelemetryMonitor';


export default function ValidationPage() {
  const navigate = useNavigate();

  return (
    <div className="container mx-auto py-6">
      <div className="mb-6">
        <Button 
          variant="ghost" 
          size="sm"
          onClick={() => navigate('/')}
          className="gap-2"
        >
          <ArrowLeft className="h-4 w-4" />
          Back
        </Button>
      </div>
      
      <Tabs defaultValue="dashboard" className="space-y-6">
        <TabsList className="grid w-full grid-cols-3">
          <TabsTrigger value="dashboard">Validation Dashboard</TabsTrigger>
          <TabsTrigger value="fixtures">Test Fixtures</TabsTrigger>
          <TabsTrigger value="telemetry">Telemetry</TabsTrigger>
        </TabsList>

        <TabsContent value="dashboard">
          <EnhancedValidationDashboard />
        </TabsContent>

        <TabsContent value="fixtures">
          <TestFixtureGenerator />
        </TabsContent>

        <TabsContent value="telemetry">
          <TelemetryMonitor />
        </TabsContent>
      </Tabs>
    </div>
  );
}