import { Toaster } from "@/components/ui/toaster";
import { Toaster as Sonner } from "@/components/ui/sonner";
import { TooltipProvider } from "@/components/ui/tooltip";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { createBrowserRouter, RouterProvider } from "react-router-dom";
import { AuthProvider } from "@/hooks/useAuth";
import { ProtectedRoute } from "@/components/ProtectedRoute";
import { FeatureGuard } from "@/components/FeatureGuard";
import Index from "./pages/Index";
import Auth from "./pages/Auth";
import ResetPassword from "./pages/ResetPassword";
import EntityManagement from "./pages/EntityManagement";
import NotFound from "./pages/NotFound";
import NoAccess from "./pages/NoAccess";
import Profile from "./pages/Profile";
import PartyManagementPage from "./pages/PartyManagementPage";
import FundVITracksPage from "./pages/FundVITracks";
import CalculationRunsPage from "./pages/CalculationRuns";
import DealsPage from "./pages/Deals";
import ContributionsPage from "./pages/Contributions";
import FundEditor from "./pages/FundEditor";
import VATSettingsPage from "./pages/VATSettings";
import DocumentsPage from "./pages/Documents";
import DiscountManagement from "@/components/DiscountManagement";
import EventManagement from "@/components/EventManagement";
import WorkflowPage from "./pages/WorkflowPage";
import Exports from "./pages/Exports";
import ValidationPage from "./pages/Validation";
import AdminUsersPage from "./pages/admin/Users";
import AdminSettingsPage from "./pages/admin/Settings";
import AdminFeatureFlagsPage from "./pages/admin/FeatureFlags";
import ChargesPage from "./pages/Charges";
import ChargeDetailPage from "./pages/ChargeDetail";
import CommissionsPage from "./pages/Commissions";
import CommissionDetailPage from "./pages/CommissionDetail";
import InvestorsPage from "./pages/Investors";
import InvestorDetailPage from "./pages/InvestorDetail";
import AgreementsPage from "./pages/Agreements";
import AdminSyncPage from "./pages/AdminSync";

const queryClient = new QueryClient();

// Create router with v7 future flags
const router = createBrowserRouter(
  [
    // Public routes
    { path: "/auth", element: <Auth /> },
    { path: "/reset-password", element: <ResetPassword /> },
    { path: "/auth/reset", element: <ResetPassword /> },
    { path: "/no-access", element: <NoAccess /> },

    // Protected routes
    { path: "/", element: <ProtectedRoute><Index /></ProtectedRoute> },
    { path: "/runs", element: <ProtectedRoute requiredRoles={['admin', 'finance', 'ops']}><CalculationRunsPage /></ProtectedRoute> },
    { path: "/fund-vi/tracks", element: <ProtectedRoute requiredRoles={['admin', 'finance']}><FundVITracksPage /></ProtectedRoute> },
    { path: "/deals", element: <ProtectedRoute requiredRoles={['admin', 'finance', 'ops']}><DealsPage /></ProtectedRoute> },
    { path: "/funds", element: <ProtectedRoute requiredRoles={['admin', 'finance', 'ops']}><FundEditor /></ProtectedRoute> },
    { path: "/contributions", element: <ProtectedRoute><ContributionsPage /></ProtectedRoute> },
    { path: "/investors", element: <ProtectedRoute><InvestorsPage /></ProtectedRoute> },
    { path: "/investors/:id", element: <ProtectedRoute><InvestorDetailPage /></ProtectedRoute> },
    { path: "/entities", element: <ProtectedRoute requiredRoles={['admin', 'finance', 'ops']}><EntityManagement /></ProtectedRoute> },
    { path: "/parties", element: <ProtectedRoute requiredRoles={['admin', 'finance', 'ops']}><PartyManagementPage /></ProtectedRoute> },
    { path: "/discounts", element: <ProtectedRoute requiredRoles={['admin', 'finance']}><DiscountManagement /></ProtectedRoute> },
    { path: "/events", element: <ProtectedRoute requiredRoles={['admin', 'finance', 'ops']}><EventManagement /></ProtectedRoute> },
    { path: "/exports", element: <ProtectedRoute><Exports /></ProtectedRoute> },
    { path: "/validation", element: <ProtectedRoute><ValidationPage /></ProtectedRoute> },
    { path: "/profile", element: <ProtectedRoute><Profile /></ProtectedRoute> },

    // Admin routes
    { path: "/admin/users", element: <ProtectedRoute requiredRoles={['admin']}><AdminUsersPage /></ProtectedRoute> },
    { path: "/admin/settings", element: <ProtectedRoute><AdminSettingsPage /></ProtectedRoute> },
    { path: "/admin/feature-flags", element: <ProtectedRoute requiredRoles={['admin']}><AdminFeatureFlagsPage /></ProtectedRoute> },
    {
      path: "/admin/sync",
      element: (
        <ProtectedRoute requiredRoles={['admin']}>
          <FeatureGuard flag="vantage_sync" fallback={<NotFound />}>
            <AdminSyncPage />
          </FeatureGuard>
        </ProtectedRoute>
      )
    },

    // Feature-flagged routes
    {
      path: "/vat-settings",
      element: (
        <ProtectedRoute requiredRoles={['admin']}>
          <FeatureGuard flag="vat_admin" fallback={<NotFound />}>
            <VATSettingsPage />
          </FeatureGuard>
        </ProtectedRoute>
      )
    },
    {
      path: "/documents",
      element: (
        <ProtectedRoute>
          <FeatureGuard flag="docs_repository" fallback={<NotFound />}>
            <DocumentsPage />
          </FeatureGuard>
        </ProtectedRoute>
      )
    },
    {
      path: "/charges",
      element: (
        <ProtectedRoute requiredRoles={['admin', 'finance', 'ops']}>
          <ChargesPage />
        </ProtectedRoute>
      )
    },
    {
      path: "/charges/:id",
      element: (
        <ProtectedRoute requiredRoles={['admin', 'finance', 'ops']}>
          <ChargeDetailPage />
        </ProtectedRoute>
      )
    },
    {
      path: "/commissions",
      element: (
        <ProtectedRoute requiredRoles={['admin', 'finance', 'ops']}>
          <CommissionsPage />
        </ProtectedRoute>
      )
    },
    {
      path: "/commissions/:id",
      element: (
        <ProtectedRoute requiredRoles={['admin', 'finance', 'ops']}>
          <CommissionDetailPage />
        </ProtectedRoute>
      )
    },
    {
      path: "/agreements",
      element: (
        <ProtectedRoute requiredRoles={['admin', 'finance', 'manager']}>
          <AgreementsPage />
        </ProtectedRoute>
      )
    },

    // 404
    { path: "*", element: <NotFound /> },
  ],
  {
    future: {
      v7_startTransition: true,
      v7_relativeSplatPath: true,
    },
  }
);

const App = () => (
  <QueryClientProvider client={queryClient}>
    <AuthProvider>
      <TooltipProvider>
        <Toaster />
        <Sonner />
        <RouterProvider router={router} />
      </TooltipProvider>
    </AuthProvider>
  </QueryClientProvider>
);

export default App;
