import React, { useMemo, useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { ScrollArea } from "@/components/ui/scroll-area";
import { Separator } from "@/components/ui/separator";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { SidebarProvider, SidebarTrigger } from "@/components/ui/sidebar";
import { AppSidebar } from "@/components/AppSidebar";
import { EnhancedAgreementUpload } from "@/components/EnhancedAgreementUpload";
import { Dashboard } from "@/components/Dashboard";
import { SimplifiedCalculationDashboard } from "@/components/SimplifiedCalculationDashboard";
import { CommissionRuleSetup } from "@/components/CommissionRuleSetup";
import { FundVITracksAdmin } from "@/components/FundVITracksAdmin";
import PartyManagement from "@/components/PartyManagement";
import DiscountManagement from "@/components/DiscountManagement";
import EventManagement from "@/components/EventManagement";
import InvestorManagement from "@/components/InvestorManagement";
import EnhancedInvestorUpload from "@/components/EnhancedInvestorUpload";
import { ExcelImportExport } from '@/components/ExcelImportExport';
import { useAuth } from "@/hooks/useAuth";
import { Link } from "react-router-dom";
import {
  Search,
  Filter,
  Sparkles,
  Play,
  Building2,
  Percent,
  Download,
  Link2,
  Users,
  FileText,
  Crown,
  Star,
  Presentation,
  Calculator,
  Calendar,
  Workflow,
  LogOut,
  User,
  FileSpreadsheet,
  Menu,
  ArrowLeft,
} from "lucide-react";

/**
 * Referral & Distributor Compensation System
 * -------------------------------------------------
 * Purpose: Comprehensive system for managing referral agreements,
 * investor onboarding, fee calculations, and compliance tracking.
 * Implements full user stories with acceptance criteria.
 */

// Types
 type Persona = "Distributor" | "Referrer" | "Partner" | "Friend";
 type Basis = "EQUITY" | "MGMT_FEE" | "PROMOTE";
 type Trigger = "ACQUISITION" | "QUARTERLY" | "SALE";

 type Agreement = {
  id: string;
  title: string; // e.g., "Upfront 1.5% (First-3 Deals)"
  owner: string; // Aventine Advisors, etc.
  persona: Persona;
  basis: Basis;
  trigger: Trigger;
  percent?: number;
  status: "Active" | "Draft" | "Archived";
  vat: boolean;
  nextPayoutUSD?: number;
 };

// Mock data: a mix of distributors, referrers, partners, friends
const AGREEMENTS: Agreement[] = [
  { id: "AG-101", title: "Upfront 1.5% (First-3 Deals)", owner: "Aventine Advisors", persona: "Distributor", basis: "EQUITY", trigger: "ACQUISITION", percent: 0.015, status: "Active", vat: true, nextPayoutUSD: 18500 },
  { id: "AG-201", title: "Promote 25% → 27% (Walden Tier)", owner: "Walden Partners", persona: "Partner", basis: "PROMOTE", trigger: "SALE", percent: 0.27, status: "Draft", vat: false, nextPayoutUSD: 0 },
  { id: "AG-301", title: "Quarterly 10% of Mgmt Fee", owner: "Skyline Capital", persona: "Referrer", basis: "MGMT_FEE", trigger: "QUARTERLY", percent: 0.1, status: "Active", vat: false, nextPayoutUSD: 7200 },
  { id: "AG-401", title: "Fixed Fee $1,000 per Acquisition", owner: "Friend-of-Fund – Cohen", persona: "Friend", basis: "EQUITY", trigger: "ACQUISITION", status: "Active", vat: true, nextPayoutUSD: 1000 },
  { id: "AG-402", title: "Upfront 1% (First-2 Deals)", owner: "Shaked Capital", persona: "Referrer", basis: "EQUITY", trigger: "ACQUISITION", percent: 0.01, status: "Active", vat: false, nextPayoutUSD: 5400 },
  { id: "AG-403", title: "Cumulative Cap until $1M", owner: "Dafna Family Office", persona: "Distributor", basis: "EQUITY", trigger: "ACQUISITION", percent: 0.015, status: "Active", vat: true, nextPayoutUSD: 0 },
  { id: "AG-404", title: "Investor Self-Discount 50%", owner: "Omega Holdings LLC", persona: "Friend", basis: "EQUITY", trigger: "ACQUISITION", percent: 0.5, status: "Draft", vat: false, nextPayoutUSD: 0 },
];

function usd(n?: number) {
  if (n == null) return "—";
  return n.toLocaleString(undefined, { style: "currency", currency: "USD" });
}

export default function Index() {
  const { user, signOut } = useAuth();
  
  // Main navigation state
  const [activeView, setActiveView] = useState<"dashboard" | "parties" | "discounts" | "calculations" | "rules" | "tracks" | "investors" | "excel" | "exports" | "validation">("dashboard");
  
  // Filters/search
  const [query, setQuery] = useState("");
  const [persona, setPersona] = useState<Persona | "all">("all");
  const [basis, setBasis] = useState<Basis | "all">("all");
  const [status, setStatus] = useState<Agreement["status"] | "all">("all");

  // Selection for profile drawer
  const [selected, setSelected] = useState<Agreement | null>(null);
  const [activeTab, setActiveTab] = useState("overview");

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    return AGREEMENTS.filter((a) =>
      (persona === "all" || a.persona === persona) &&
      (basis === "all" || a.basis === basis) &&
      (status === "all" || a.status === status) &&
      (!q || a.title.toLowerCase().includes(q) || a.owner.toLowerCase().includes(q))
    );
  }, [query, persona, basis, status]);

  // Dummy export (CSV) to complete the UI flow
  const exportCsv = () => {
    const headers = ["id","owner","persona","title","basis","trigger","status","vat","nextPayoutUSD"]; 
    const escape = (s: any) => {
      const str = String(s ?? "");
      return /[",\n]/.test(str) ? `"${str.replace(/"/g,'""')}"` : str;
    };
    const lines = [headers.join(","), ...filtered.map(a => headers.map(h => escape((a as any)[h])).join(","))];
    const csv = lines.join("\r\n");
    const blob = new Blob([csv], { type: "text/csv;charset=utf-8;" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url; a.download = "agreements_demo.csv"; a.click(); URL.revokeObjectURL(url);
  };

  return (
    <SidebarProvider>
      <div className="min-h-screen w-full flex bg-background">
        <AppSidebar />
        
        <div className="flex-1 flex flex-col">
          {/* Top bar */}
          <div className="sticky top-0 z-20 bg-background/80 backdrop-blur border-b border-border">
            <div className="px-4 py-3 flex items-center gap-3">
              <SidebarTrigger />
              <h1 className="text-lg font-semibold">Dashboard</h1>
              <div className="flex items-center gap-3 ml-auto">
                <EnhancedAgreementUpload />
                <Button variant="outline" className="gap-2" onClick={exportCsv}>
                  <Download className="w-4 h-4"/> 
                  Export CSV
                </Button>
              </div>
            </div>
          </div>

          {/* Main Content */}
          <main className="flex-1 p-6">
            <Dashboard />
          </main>
        </div>
      </div>
    </SidebarProvider>
  );
}