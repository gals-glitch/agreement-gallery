/**
 * Dashboard - Real Commission System Overview
 * Updated: 2025-11-10
 *
 * Displays actual commission system data:
 * - Real commissions from database
 * - Real agreements and parties
 * - Actual calculation results
 */

import React from "react";
import { useQuery } from "@tanstack/react-query";
import { useNavigate } from "react-router-dom";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import {
  TrendingUp,
  DollarSign,
  Users,
  FileText,
  ArrowRight,
  CheckCircle2,
  Clock,
  AlertCircle
} from "lucide-react";
import { commissionsApi, type Commission } from "@/api/commissionsClient";
import { Badge } from "@/components/ui/badge";

function usd(n: number) {
  return n.toLocaleString(undefined, { style: "currency", currency: "USD" });
}

const getStatusBadgeClass = (status: string) => {
  switch (status) {
    case 'draft':
      return 'bg-gray-500/10 text-gray-700 border-gray-200';
    case 'pending':
      return 'bg-yellow-500/10 text-yellow-700 border-yellow-200';
    case 'approved':
      return 'bg-green-500/10 text-green-700 border-green-200';
    case 'paid':
      return 'bg-blue-500/10 text-blue-700 border-blue-200';
    case 'rejected':
      return 'bg-red-500/10 text-red-700 border-red-200';
    default:
      return 'bg-gray-500/10 text-gray-700 border-gray-200';
  }
};

export function Dashboard() {
  const navigate = useNavigate();

  // Fetch all commissions to calculate stats
  const { data: draftData, isLoading: draftLoading } = useQuery({
    queryKey: ['commissions', 'draft'],
    queryFn: () => commissionsApi.listCommissions({ status: 'draft' }),
  });

  const { data: pendingData, isLoading: pendingLoading } = useQuery({
    queryKey: ['commissions', 'pending'],
    queryFn: () => commissionsApi.listCommissions({ status: 'pending' }),
  });

  const { data: approvedData, isLoading: approvedLoading } = useQuery({
    queryKey: ['commissions', 'approved'],
    queryFn: () => commissionsApi.listCommissions({ status: 'approved' }),
  });

  const { data: paidData, isLoading: paidLoading } = useQuery({
    queryKey: ['commissions', 'paid'],
    queryFn: () => commissionsApi.listCommissions({ status: 'paid' }),
  });

  const isLoading = draftLoading || pendingLoading || approvedLoading || paidLoading;

  // Calculate statistics
  const draftCommissions = draftData?.data || [];
  const pendingCommissions = pendingData?.data || [];
  const approvedCommissions = approvedData?.data || [];
  const paidCommissions = paidData?.data || [];

  const totalCommissions =
    draftCommissions.length +
    pendingCommissions.length +
    approvedCommissions.length +
    paidCommissions.length;

  const totalValue =
    [...draftCommissions, ...pendingCommissions, ...approvedCommissions, ...paidCommissions]
      .reduce((sum, c) => sum + c.total_amount, 0);

  const pendingApprovalCount = pendingCommissions.length;
  const pendingApprovalValue = pendingCommissions.reduce((sum, c) => sum + c.total_amount, 0);

  const approvedAwaitingPayment = approvedCommissions.length;
  const approvedAwaitingPaymentValue = approvedCommissions.reduce((sum, c) => sum + c.total_amount, 0);

  // Get unique parties
  const uniqueParties = new Set([
    ...draftCommissions.map(c => c.party_id),
    ...pendingCommissions.map(c => c.party_id),
    ...approvedCommissions.map(c => c.party_id),
    ...paidCommissions.map(c => c.party_id),
  ]).size;

  // Calculate average rate (from draft commissions as they have full snapshot)
  const avgRate = draftCommissions.length > 0
    ? draftCommissions.reduce((sum, c) => {
        // Extract rate from base_amount / contribution_amount
        const rate = c.contribution_amount > 0
          ? (c.base_amount / c.contribution_amount) * 100
          : 0;
        return sum + rate;
      }, 0) / draftCommissions.length
    : 0;

  // Recent commissions for preview (top 5 by value)
  const recentCommissions = [...draftCommissions]
    .sort((a, b) => b.total_amount - a.total_amount)
    .slice(0, 5);

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">Commission Dashboard</h1>
          <p className="text-muted-foreground">
            Real-time overview of your distributor commission system
          </p>
        </div>

        <Button onClick={() => navigate('/commissions')}>
          View All Commissions
          <ArrowRight className="w-4 h-4 ml-2" />
        </Button>
      </div>

      {/* Summary Statistics */}
      {isLoading ? (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          {[...Array(4)].map((_, i) => (
            <Card key={i}>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <Skeleton className="h-4 w-[100px]" />
                <Skeleton className="h-4 w-4" />
              </CardHeader>
              <CardContent>
                <Skeleton className="h-8 w-[120px] mb-2" />
                <Skeleton className="h-3 w-[80px]" />
              </CardContent>
            </Card>
          ))}
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          {/* Total Commissions */}
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Total Commissions</CardTitle>
              <FileText className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{totalCommissions}</div>
              <p className="text-xs text-muted-foreground">
                {draftCommissions.length} draft, {paidCommissions.length} paid
              </p>
            </CardContent>
          </Card>

          {/* Total Value */}
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Total Value</CardTitle>
              <DollarSign className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{usd(totalValue)}</div>
              <p className="text-xs text-muted-foreground">
                All commissions (incl. VAT)
              </p>
            </CardContent>
          </Card>

          {/* Pending Approval */}
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Pending Approval</CardTitle>
              <Clock className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{pendingApprovalCount}</div>
              <p className="text-xs text-muted-foreground">
                {usd(pendingApprovalValue)} awaiting review
              </p>
            </CardContent>
          </Card>

          {/* Active Parties */}
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Active Parties</CardTitle>
              <Users className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{uniqueParties}</div>
              <p className="text-xs text-muted-foreground">
                Avg rate: {avgRate.toFixed(2)}%
              </p>
            </CardContent>
          </Card>
        </div>
      )}

      {/* Action Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        {/* Needs Approval */}
        <Card
          className="cursor-pointer hover:shadow-lg transition-shadow"
          onClick={() => navigate('/commissions?status=pending')}
        >
          <CardHeader>
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <Clock className="h-5 w-5 text-yellow-600" />
                <CardTitle className="text-lg">Needs Approval</CardTitle>
              </div>
              <Badge variant="secondary" className="bg-yellow-500/10 text-yellow-700 border-yellow-200">
                {pendingApprovalCount}
              </Badge>
            </div>
            <CardDescription>
              Commissions submitted and awaiting admin approval
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold mb-2">{usd(pendingApprovalValue)}</div>
            <Button variant="outline" size="sm" className="w-full">
              Review Pending
              <ArrowRight className="w-4 h-4 ml-2" />
            </Button>
          </CardContent>
        </Card>

        {/* Ready to Pay */}
        <Card
          className="cursor-pointer hover:shadow-lg transition-shadow"
          onClick={() => navigate('/commissions?status=approved')}
        >
          <CardHeader>
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <CheckCircle2 className="h-5 w-5 text-green-600" />
                <CardTitle className="text-lg">Ready to Pay</CardTitle>
              </div>
              <Badge variant="secondary" className="bg-green-500/10 text-green-700 border-green-200">
                {approvedAwaitingPayment}
              </Badge>
            </div>
            <CardDescription>
              Approved commissions awaiting payment
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold mb-2">{usd(approvedAwaitingPaymentValue)}</div>
            <Button variant="outline" size="sm" className="w-full">
              Mark as Paid
              <ArrowRight className="w-4 h-4 ml-2" />
            </Button>
          </CardContent>
        </Card>

        {/* Draft Commissions */}
        <Card
          className="cursor-pointer hover:shadow-lg transition-shadow"
          onClick={() => navigate('/commissions?status=draft')}
        >
          <CardHeader>
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <AlertCircle className="h-5 w-5 text-gray-600" />
                <CardTitle className="text-lg">Draft Commissions</CardTitle>
              </div>
              <Badge variant="secondary">
                {draftCommissions.length}
              </Badge>
            </div>
            <CardDescription>
              Commissions computed but not yet submitted
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold mb-2">
              {usd(draftCommissions.reduce((sum, c) => sum + c.total_amount, 0))}
            </div>
            <Button variant="outline" size="sm" className="w-full">
              Submit for Approval
              <ArrowRight className="w-4 h-4 ml-2" />
            </Button>
          </CardContent>
        </Card>
      </div>

      {/* Top Commissions Preview */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <div>
              <CardTitle>Top Commissions</CardTitle>
              <CardDescription>
                Highest value draft commissions by amount
              </CardDescription>
            </div>
            <Button variant="ghost" size="sm" onClick={() => navigate('/commissions')}>
              View All
              <ArrowRight className="w-4 h-4 ml-2" />
            </Button>
          </div>
        </CardHeader>
        <CardContent>
          {isLoading ? (
            <div className="space-y-3">
              {[...Array(3)].map((_, i) => (
                <div key={i} className="flex items-center justify-between p-3 border rounded">
                  <Skeleton className="h-4 w-[200px]" />
                  <Skeleton className="h-4 w-[100px]" />
                </div>
              ))}
            </div>
          ) : recentCommissions.length === 0 ? (
            <div className="text-center py-8 text-muted-foreground">
              <TrendingUp className="w-12 h-12 mx-auto mb-3 opacity-50" />
              <p className="font-medium mb-1">No commissions yet</p>
              <p className="text-sm">
                Click "Compute Eligible" on the Commissions page to start
              </p>
            </div>
          ) : (
            <div className="space-y-3">
              {recentCommissions.map((commission) => (
                <div
                  key={commission.id}
                  className="flex items-center justify-between p-3 border rounded hover:bg-muted/50 cursor-pointer transition-colors"
                  onClick={() => navigate(`/commissions/${commission.id}`)}
                >
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2">
                      <p className="font-medium truncate">
                        {commission.investor_name}
                      </p>
                      <span className="text-muted-foreground">→</span>
                      <p className="text-sm text-muted-foreground truncate">
                        {commission.party_name}
                      </p>
                    </div>
                    <p className="text-xs text-muted-foreground mt-1">
                      {commission.fund_name || commission.deal_name}
                    </p>
                  </div>
                  <div className="flex items-center gap-3 ml-4">
                    <Badge
                      className={getStatusBadgeClass(commission.status)}
                      variant="outline"
                    >
                      {commission.status.toUpperCase()}
                    </Badge>
                    <div className="text-right">
                      <p className="font-semibold">{usd(commission.total_amount)}</p>
                      <p className="text-xs text-muted-foreground">
                        Base: {usd(commission.base_amount)}
                      </p>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Quick Actions */}
      <Card>
        <CardHeader>
          <CardTitle>Quick Actions</CardTitle>
          <CardDescription>
            Common tasks and navigation
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <Button
              variant="outline"
              className="h-auto py-4 flex flex-col items-center gap-2"
              onClick={() => navigate('/commissions')}
            >
              <TrendingUp className="w-6 h-6" />
              <span className="font-medium">View Commissions</span>
              <span className="text-xs text-muted-foreground">
                Manage all commissions
              </span>
            </Button>

            <Button
              variant="outline"
              className="h-auto py-4 flex flex-col items-center gap-2"
              onClick={() => navigate('/investors')}
            >
              <Users className="w-6 h-6" />
              <span className="font-medium">Manage Investors</span>
              <span className="text-xs text-muted-foreground">
                1,014 investors in system
              </span>
            </Button>

            <Button
              variant="outline"
              className="h-auto py-4 flex flex-col items-center gap-2"
              onClick={() => navigate('/contributions')}
            >
              <DollarSign className="w-6 h-6" />
              <span className="font-medium">View Contributions</span>
              <span className="text-xs text-muted-foreground">
                Source data for commissions
              </span>
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
