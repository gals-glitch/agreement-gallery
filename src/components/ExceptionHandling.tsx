import React, { useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { ScrollArea } from "@/components/ui/scroll-area";
import { Progress } from "@/components/ui/progress";
import { 
  AlertTriangle, 
  CheckCircle, 
  XCircle,
  AlertCircle,
  Clock,
  Shield,
  Database,
  DollarSign,
  FileX,
  Settings,
  Mail,
  RefreshCw,
  TrendingUp
} from "lucide-react";
import { useToast } from "@/hooks/use-toast";

interface Exception {
  id: string;
  type: "VALIDATION" | "BUSINESS_RULE" | "DATA_INTEGRITY" | "APPROVAL";
  severity: "HIGH" | "MEDIUM" | "LOW";
  title: string;
  description: string;
  affectedEntity: string;
  entityId: string;
  dateDetected: string;
  status: "OPEN" | "RESOLVED" | "DISMISSED";
  resolutionNotes?: string;
  autoResolvable: boolean;
}

interface AlertRule {
  id: string;
  name: string;
  description: string;
  enabled: boolean;
  threshold: string;
  recipients: string[];
  frequency: "IMMEDIATE" | "DAILY" | "WEEKLY";
}

// Mock data for MVP
const MOCK_EXCEPTIONS: Exception[] = [
  {
    id: "EXC-001",
    type: "VALIDATION",
    severity: "HIGH",
    title: "Missing Payor Entity",
    description: "Agreement AG-205 does not have a payor entity specified, blocking fee calculation.",
    affectedEntity: "Agreement",
    entityId: "AG-205",
    dateDetected: "2024-01-15",
    status: "OPEN",
    autoResolvable: false
  },
  {
    id: "EXC-002", 
    type: "BUSINESS_RULE",
    severity: "MEDIUM",
    title: "Overlapping Rate Periods",
    description: "Investor INV-003 has overlapping rate periods for Deal Alpha (1.5% and 1.0%).",
    affectedEntity: "Calculation",
    entityId: "CALC-045",
    dateDetected: "2024-01-16",
    status: "OPEN",
    autoResolvable: true
  },
  {
    id: "EXC-003",
    type: "DATA_INTEGRITY",
    severity: "LOW",
    title: "Zero Fee Amount",
    description: "Calculation resulted in $0 fee for contribution event EVT-123.",
    affectedEntity: "Calculation",
    entityId: "CALC-046",
    dateDetected: "2024-01-17", 
    status: "RESOLVED",
    resolutionNotes: "Confirmed zero rate due to cap threshold reached.",
    autoResolvable: false
  },
  {
    id: "EXC-004",
    type: "APPROVAL",
    severity: "MEDIUM",
    title: "Missing VAT Configuration",
    description: "Agreement AG-301 missing VAT configuration for EU investor.",
    affectedEntity: "Agreement",
    entityId: "AG-301",
    dateDetected: "2024-01-18",
    status: "OPEN",
    autoResolvable: false
  }
];

const MOCK_ALERT_RULES: AlertRule[] = [
  {
    id: "RULE-001",
    name: "High Severity Exceptions",
    description: "Alert when high severity exceptions are detected",
    enabled: true,
    threshold: "severity = HIGH",
    recipients: ["rivka@buligo.com", "miri@buligo.com"],
    frequency: "IMMEDIATE"
  },
  {
    id: "RULE-002",
    name: "Quarterly Processing Reminders",
    description: "Remind Finance team about quarterly processing deadlines",
    enabled: true,
    threshold: "quarterly_deadline - 3 days",
    recipients: ["rivka@buligo.com"],
    frequency: "DAILY"
  },
  {
    id: "RULE-003",
    name: "Missing Approvals",
    description: "Alert when calculations await approval for >5 days",
    enabled: true,
    threshold: "approval_pending > 5 days",
    recipients: ["rivka@buligo.com", "legal@buligo.com"],
    frequency: "DAILY"
  }
];

export function ExceptionHandling() {
  const [exceptions, setExceptions] = useState<Exception[]>(MOCK_EXCEPTIONS);
  const [alertRules, setAlertRules] = useState<AlertRule[]>(MOCK_ALERT_RULES);
  const [selectedSeverity, setSelectedSeverity] = useState<Exception["severity"] | "ALL">("ALL");
  const [selectedStatus, setSelectedStatus] = useState<Exception["status"] | "ALL">("ALL");
  const { toast } = useToast();

  const resolveException = (exceptionId: string, notes: string) => {
    setExceptions(exceptions.map(exc => 
      exc.id === exceptionId 
        ? { ...exc, status: "RESOLVED" as const, resolutionNotes: notes }
        : exc
    ));
    
    toast({
      title: "Exception Resolved",
      description: `Exception ${exceptionId} has been marked as resolved.`,
    });
  };

  const dismissException = (exceptionId: string) => {
    setExceptions(exceptions.map(exc => 
      exc.id === exceptionId 
        ? { ...exc, status: "DISMISSED" as const }
        : exc
    ));
    
    toast({
      title: "Exception Dismissed",
      description: `Exception ${exceptionId} has been dismissed.`,
    });
  };

  const autoResolveExceptions = () => {
    const autoResolvable = exceptions.filter(exc => exc.autoResolvable && exc.status === "OPEN");
    
    setExceptions(exceptions.map(exc => 
      exc.autoResolvable && exc.status === "OPEN"
        ? { ...exc, status: "RESOLVED" as const, resolutionNotes: "Auto-resolved by system" }
        : exc
    ));
    
    toast({
      title: "Auto-Resolution Complete",
      description: `${autoResolvable.length} exceptions were automatically resolved.`,
    });
  };

  const toggleAlertRule = (ruleId: string) => {
    setAlertRules(alertRules.map(rule => 
      rule.id === ruleId 
        ? { ...rule, enabled: !rule.enabled }
        : rule
    ));
  };

  const sendTestAlert = (ruleId: string) => {
    toast({
      title: "Test Alert Sent",
      description: `Test notification sent to configured recipients for rule ${ruleId}.`,
    });
  };

  const filteredExceptions = exceptions.filter(exc => 
    (selectedSeverity === "ALL" || exc.severity === selectedSeverity) &&
    (selectedStatus === "ALL" || exc.status === selectedStatus)
  );

  const getSeverityIcon = (severity: Exception["severity"]) => {
    switch (severity) {
      case "HIGH":
        return <XCircle className="w-4 h-4 text-red-600" />;
      case "MEDIUM":
        return <AlertTriangle className="w-4 h-4 text-orange-600" />;
      case "LOW":
        return <AlertCircle className="w-4 h-4 text-yellow-600" />;
    }
  };

  const getSeverityColor = (severity: Exception["severity"]) => {
    switch (severity) {
      case "HIGH":
        return "bg-red-100 text-red-800 border-red-200";
      case "MEDIUM":
        return "bg-orange-100 text-orange-800 border-orange-200";
      case "LOW":
        return "bg-yellow-100 text-yellow-800 border-yellow-200";
    }
  };

  const getStatusIcon = (status: Exception["status"]) => {
    switch (status) {
      case "OPEN":
        return <Clock className="w-4 h-4 text-orange-600" />;
      case "RESOLVED":
        return <CheckCircle className="w-4 h-4 text-green-600" />;
      case "DISMISSED":
        return <XCircle className="w-4 h-4 text-gray-600" />;
    }
  };

  const getStatusColor = (status: Exception["status"]) => {
    switch (status) {
      case "OPEN":
        return "bg-orange-100 text-orange-800 border-orange-200";
      case "RESOLVED":
        return "bg-green-100 text-green-800 border-green-200";
      case "DISMISSED":
        return "bg-gray-100 text-gray-800 border-gray-200";
    }
  };

  const getTypeIcon = (type: Exception["type"]) => {
    switch (type) {
      case "VALIDATION":
        return <Shield className="w-4 h-4 text-blue-600" />;
      case "BUSINESS_RULE":
        return <Settings className="w-4 h-4 text-purple-600" />;
      case "DATA_INTEGRITY":
        return <Database className="w-4 h-4 text-green-600" />;
      case "APPROVAL":
        return <FileX className="w-4 h-4 text-orange-600" />;
    }
  };

  const openExceptions = exceptions.filter(exc => exc.status === "OPEN");
  const highSeverityOpen = openExceptions.filter(exc => exc.severity === "HIGH");
  const autoResolvableCount = openExceptions.filter(exc => exc.autoResolvable).length;

  return (
    <div className="space-y-6">
      {/* Exception Summary */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <AlertTriangle className="w-5 h-5" />
            Exception Dashboard
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-4">
            <div className="text-center">
              <div className="text-2xl font-bold text-orange-600">
                {openExceptions.length}
              </div>
              <div className="text-sm text-muted-foreground">Open Exceptions</div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold text-red-600">
                {highSeverityOpen.length}
              </div>
              <div className="text-sm text-muted-foreground">High Severity</div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold text-blue-600">
                {autoResolvableCount}
              </div>
              <div className="text-sm text-muted-foreground">Auto-Resolvable</div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold text-green-600">
                {exceptions.filter(exc => exc.status === "RESOLVED").length}
              </div>
              <div className="text-sm text-muted-foreground">Resolved</div>
            </div>
          </div>

          {autoResolvableCount > 0 && (
            <div className="flex gap-2">
              <Button onClick={autoResolveExceptions} className="gap-2">
                <RefreshCw className="w-4 h-4" />
                Auto-Resolve ({autoResolvableCount})
              </Button>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Main Content Tabs */}
      <Tabs defaultValue="exceptions">
        <TabsList>
          <TabsTrigger value="exceptions">Exceptions</TabsTrigger>
          <TabsTrigger value="alerts">Alert Rules</TabsTrigger>
          <TabsTrigger value="reports">Exception Reports</TabsTrigger>
        </TabsList>

        <TabsContent value="exceptions" className="space-y-4">
          {/* Filters */}
          <Card>
            <CardContent className="p-4">
              <div className="flex gap-4">
                <div className="flex items-center gap-2">
                  <label className="text-sm font-medium">Severity:</label>
                  <div className="flex gap-1">
                    {(["ALL", "HIGH", "MEDIUM", "LOW"] as const).map(severity => (
                      <Button
                        key={severity}
                        variant={selectedSeverity === severity ? "default" : "outline"}
                        size="sm"
                        onClick={() => setSelectedSeverity(severity)}
                      >
                        {severity}
                      </Button>
                    ))}
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  <label className="text-sm font-medium">Status:</label>
                  <div className="flex gap-1">
                    {(["ALL", "OPEN", "RESOLVED", "DISMISSED"] as const).map(status => (
                      <Button
                        key={status}
                        variant={selectedStatus === status ? "default" : "outline"}
                        size="sm"
                        onClick={() => setSelectedStatus(status)}
                      >
                        {status}
                      </Button>
                    ))}
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Exceptions List */}
          <Card>
            <CardContent className="p-0">
              <ScrollArea className="h-96">
                <div className="p-4 space-y-3">
                  {filteredExceptions.map((exception) => (
                    <Card key={exception.id} className="border">
                      <CardContent className="p-4">
                        <div className="flex items-start justify-between">
                          <div className="space-y-2 flex-1">
                            <div className="flex items-center gap-2">
                              {getTypeIcon(exception.type)}
                              <span className="font-medium">{exception.title}</span>
                              <Badge className={getSeverityColor(exception.severity)}>
                                {exception.severity}
                              </Badge>
                              <Badge className={getStatusColor(exception.status)}>
                                {exception.status}
                              </Badge>
                              {exception.autoResolvable && (
                                <Badge variant="outline">Auto-Resolvable</Badge>
                              )}
                            </div>
                            <div className="text-sm text-muted-foreground">
                              {exception.description}
                            </div>
                            <div className="flex items-center gap-4 text-xs text-muted-foreground">
                              <span>{exception.type.replace('_', ' ')}</span>
                              <span>{exception.affectedEntity}: {exception.entityId}</span>
                              <span>Detected: {exception.dateDetected}</span>
                            </div>
                            {exception.resolutionNotes && (
                              <div className="text-xs text-green-700 bg-green-50 p-2 rounded">
                                Resolution: {exception.resolutionNotes}
                              </div>
                            )}
                          </div>
                          
                          {exception.status === "OPEN" && (
                            <div className="flex gap-2 ml-4">
                              <Button 
                                size="sm"
                                onClick={() => resolveException(exception.id, "Manually resolved by user")}
                              >
                                Resolve
                              </Button>
                              <Button 
                                variant="outline" 
                                size="sm"
                                onClick={() => dismissException(exception.id)}
                              >
                                Dismiss
                              </Button>
                            </div>
                          )}
                        </div>
                      </CardContent>
                    </Card>
                  ))}
                </div>
              </ScrollArea>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="alerts" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Alert Rules Configuration</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                {alertRules.map((rule) => (
                  <Card key={rule.id} className="border">
                    <CardContent className="p-4">
                      <div className="flex items-center justify-between">
                        <div className="space-y-1 flex-1">
                          <div className="flex items-center gap-2">
                            <Mail className="w-4 h-4" />
                            <span className="font-medium">{rule.name}</span>
                            <Badge variant={rule.enabled ? "default" : "secondary"}>
                              {rule.enabled ? "Enabled" : "Disabled"}
                            </Badge>
                            <Badge variant="outline">{rule.frequency}</Badge>
                          </div>
                          <div className="text-sm text-muted-foreground">
                            {rule.description}
                          </div>
                          <div className="text-xs text-muted-foreground">
                            Threshold: {rule.threshold} • Recipients: {rule.recipients.join(", ")}
                          </div>
                        </div>
                        
                        <div className="flex gap-2">
                          <Button 
                            variant="outline" 
                            size="sm"
                            onClick={() => sendTestAlert(rule.id)}
                          >
                            Test
                          </Button>
                          <Button 
                            variant={rule.enabled ? "secondary" : "default"}
                            size="sm"
                            onClick={() => toggleAlertRule(rule.id)}
                          >
                            {rule.enabled ? "Disable" : "Enable"}
                          </Button>
                        </div>
                      </div>
                    </CardContent>
                  </Card>
                ))}
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="reports" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Exception Reports</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <Card className="border">
                  <CardContent className="p-4 text-center">
                    <FileX className="w-8 h-8 mx-auto mb-2 text-blue-600" />
                    <div className="font-medium mb-1">Weekly Exception Summary</div>
                    <div className="text-sm text-muted-foreground mb-3">
                      Summary of all exceptions from the past week
                    </div>
                    <Button variant="outline" size="sm">Generate Report</Button>
                  </CardContent>
                </Card>
                
                <Card className="border">
                  <CardContent className="p-4 text-center">
                    <AlertTriangle className="w-8 h-8 mx-auto mb-2 text-orange-600" />
                    <div className="font-medium mb-1">Critical Issues Report</div>
                    <div className="text-sm text-muted-foreground mb-3">
                      All high-severity exceptions requiring attention
                    </div>
                    <Button variant="outline" size="sm">Generate Report</Button>
                  </CardContent>
                </Card>
                
                <Card className="border">
                  <CardContent className="p-4 text-center">
                    <TrendingUp className="w-8 h-8 mx-auto mb-2 text-green-600" />
                    <div className="font-medium mb-1">Resolution Trends</div>
                    <div className="text-sm text-muted-foreground mb-3">
                      Exception resolution time and trend analysis
                    </div>
                    <Button variant="outline" size="sm">Generate Report</Button>
                  </CardContent>
                </Card>
                
                <Card className="border">
                  <CardContent className="p-4 text-center">
                    <Settings className="w-8 h-8 mx-auto mb-2 text-purple-600" />
                    <div className="font-medium mb-1">Compliance Audit</div>
                    <div className="text-sm text-muted-foreground mb-3">
                      Exception handling audit trail for compliance
                    </div>
                    <Button variant="outline" size="sm">Generate Report</Button>
                  </CardContent>
                </Card>
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
}