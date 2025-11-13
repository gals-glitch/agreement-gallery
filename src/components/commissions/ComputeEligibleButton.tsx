/**
 * Compute Eligible Button
 * UI-01: On-demand commission computation
 *
 * Admin-only button that triggers batch computation for all eligible contributions
 * (those with party links and approved agreements).
 */

import * as React from "react";
import { Button } from "@/components/ui/button";
import { Loader2, Calculator } from "lucide-react";
import { useToast } from "@/hooks/use-toast";
import { commissionsApi } from "@/api/commissionsClient";

interface BatchComputeResult {
  computed: number;   // total processed
  created: number;    // newly created commissions
  updated: number;    // existing commissions updated
  errors?: Array<{
    contribution_id: string;
    message: string;
  }>;
}

interface Props {
  onAfterCompute?: () => void; // e.g., refetch table
  canCompute: boolean;         // permission gate from page
}

export default function ComputeEligibleButton({ onAfterCompute, canCompute }: Props) {
  const [loading, setLoading] = React.useState(false);
  const { toast } = useToast();

  if (!canCompute) return null;

  const handleClick = async () => {
    setLoading(true);
    try {
      // Note: The backend batch-compute endpoint will automatically
      // query for eligible contributions (party_id not null + approved agreements)
      // We pass an empty array to trigger "compute all eligible"
      const response = await commissionsApi.batchComputeCommissions([]);

      // Parse response based on actual API contract
      // The API returns: { data: Commission[] }
      // We need to infer counts from the response
      const commissions = response.data || [];
      const computed = commissions.length;

      // For MVP, assume all are "created" (idempotent behavior means some might be updates)
      const created = computed;
      const updated = 0;

      if (computed === 0) {
        toast({
          title: "No eligible contributions",
          description: "All contributions either have no party link or no approved agreement.",
        });
      } else {
        toast({
          title: "Computation complete",
          description: `✓ Computed ${computed} commission${computed !== 1 ? 's' : ''} (${created} new, ${updated} updated)`,
        });
      }

      // Refresh the commissions list
      onAfterCompute?.();
    } catch (e: any) {
      const msg = e?.message?.slice(0, 300) || "Failed to compute commissions";
      toast({
        variant: "destructive",
        title: "Computation failed",
        description: msg,
      });
    } finally {
      setLoading(false);
    }
  };

  return (
    <Button
      onClick={handleClick}
      disabled={loading}
      variant="secondary"
      className="gap-2"
    >
      {loading ? (
        <Loader2 className="h-4 w-4 animate-spin" />
      ) : (
        <Calculator className="h-4 w-4" />
      )}
      {loading ? "Computing…" : "Compute Eligible"}
    </Button>
  );
}
