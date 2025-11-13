/**
 * Admin Sync Dashboard
 * Manages Vantage IR sync operations
 * Date: 2025-11-06
 */

import { useEffect, useState } from "react";
import { supabase } from "@/integrations/supabase/client";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Alert, AlertDescription } from "@/components/ui/alert";
import { Loader2, RefreshCw, Database, AlertCircle, CheckCircle2 } from "lucide-react";

type SyncStatus = {
  resource: string;
  last_sync_status: string | null;
  records_synced: number | null;
  records_created: number | null;
  records_updated: number | null;
  started_at: string | null;
  completed_at: string | null;
  duration_ms: number | null;
  errors: any | null;
};

export default function AdminSync() {
  const [rows, setRows] = useState<SyncStatus[]>([]);
  const [busy, setBusy] = useState(false);
  const [result, setResult] = useState<any>(null);
  const [error, setError] = useState<string | null>(null);

  const loadStatus = async () => {
    const { data, error } = await supabase
      .from("vantage_sync_state")
      .select(
        "resource,last_sync_status,records_synced,records_created,records_updated,started_at,completed_at,duration_ms,errors"
      )
      .order("completed_at", { ascending: false });

    if (error) {
      setError(error.message);
    } else {
      setRows(data ?? []);
    }
  };

  useEffect(() => {
    loadStatus();
  }, []);

  const triggerSync = async (mode: "incremental" | "full") => {
    setBusy(true);
    setError(null);
    setResult(null);

    try {
      const { data, error } = await supabase.functions.invoke("vantage-sync", {
        body: {
          mode,
          resources: ["accounts", "funds"],
          dryRun: false,
        },
      });

      if (error) {
        setError(error.message);
      } else {
        setResult(data);
      }

      await loadStatus();
    } catch (err: any) {
      setError(err.message || "Unknown error occurred");
    } finally {
      setBusy(false);
    }
  };

  const getStatusBadge = (status: string | null) => {
    if (!status) return <Badge variant="outline">Unknown</Badge>;

    switch (status) {
      case "success":
        return (
          <Badge className="bg-green-100 text-green-800 border-green-300">
            <CheckCircle2 className="h-3 w-3 mr-1" />
            Success
          </Badge>
        );
      case "failed":
        return (
          <Badge variant="destructive">
            <AlertCircle className="h-3 w-3 mr-1" />
            Failed
          </Badge>
        );
      case "running":
        return (
          <Badge className="bg-blue-100 text-blue-800 border-blue-300">
            <Loader2 className="h-3 w-3 mr-1 animate-spin" />
            Running
          </Badge>
        );
      default:
        return <Badge variant="outline">{status}</Badge>;
    }
  };

  const formatDuration = (ms: number | null) => {
    if (!ms) return "-";
    if (ms < 1000) return `${ms}ms`;
    return `${Math.round(ms / 1000)}s`;
  };

  const formatDate = (dateString: string | null) => {
    if (!dateString) return "-";
    return new Date(dateString).toLocaleString();
  };

  return (
    <div className="p-6 space-y-6">
      {/* Header */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <div className="space-y-1">
              <CardTitle className="text-2xl flex items-center gap-2">
                <Database className="h-6 w-6" />
                Vantage IR Sync
              </CardTitle>
              <CardDescription>
                Manage data synchronization from Vantage IR platform
              </CardDescription>
            </div>
            <div className="flex gap-2">
              <Button
                disabled={busy}
                onClick={() => triggerSync("incremental")}
                className="gap-2"
              >
                {busy ? (
                  <Loader2 className="h-4 w-4 animate-spin" />
                ) : (
                  <RefreshCw className="h-4 w-4" />
                )}
                Sync Now (Incremental)
              </Button>
              <Button
                disabled={busy}
                onClick={() => triggerSync("full")}
                variant="outline"
                className="gap-2"
              >
                {busy ? (
                  <Loader2 className="h-4 w-4 animate-spin" />
                ) : (
                  <Database className="h-4 w-4" />
                )}
                Full Backfill
              </Button>
            </div>
          </div>
        </CardHeader>

        {/* Error Display */}
        {error && (
          <CardContent>
            <Alert variant="destructive">
              <AlertCircle className="h-4 w-4" />
              <AlertDescription>{error}</AlertDescription>
            </Alert>
          </CardContent>
        )}

        {/* Result Display */}
        {result && (
          <CardContent>
            <Alert>
              <CheckCircle2 className="h-4 w-4" />
              <AlertDescription>
                <div className="font-semibold mb-2">Sync completed successfully!</div>
                <pre className="text-xs bg-gray-50 p-3 rounded overflow-auto mt-2">
                  {JSON.stringify(result, null, 2)}
                </pre>
              </AlertDescription>
            </Alert>
          </CardContent>
        )}
      </Card>

      {/* Sync History Table */}
      <Card>
        <CardHeader>
          <CardTitle>Sync History</CardTitle>
          <CardDescription>Recent sync operations and their status</CardDescription>
        </CardHeader>
        <CardContent>
          {rows.length === 0 ? (
            <div className="text-center py-8 text-gray-500">
              No sync history available
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="text-left border-b">
                    <th className="py-3 px-4 font-semibold">Resource</th>
                    <th className="py-3 px-4 font-semibold">Status</th>
                    <th className="py-3 px-4 font-semibold">Created</th>
                    <th className="py-3 px-4 font-semibold">Updated</th>
                    <th className="py-3 px-4 font-semibold">Total Synced</th>
                    <th className="py-3 px-4 font-semibold">Duration</th>
                    <th className="py-3 px-4 font-semibold">Completed</th>
                  </tr>
                </thead>
                <tbody>
                  {rows.map((r, idx) => (
                    <tr key={`${r.resource}-${idx}`} className="border-b hover:bg-gray-50">
                      <td className="py-3 px-4 font-medium">{r.resource}</td>
                      <td className="py-3 px-4">{getStatusBadge(r.last_sync_status)}</td>
                      <td className="py-3 px-4">{r.records_created ?? 0}</td>
                      <td className="py-3 px-4">{r.records_updated ?? 0}</td>
                      <td className="py-3 px-4">{r.records_synced ?? 0}</td>
                      <td className="py-3 px-4">{formatDuration(r.duration_ms)}</td>
                      <td className="py-3 px-4 text-gray-600">
                        {formatDate(r.completed_at)}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
